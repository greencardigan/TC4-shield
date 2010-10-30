// aCatuai.pde
//
// 2-channel Rise-o-Meter and manual roast controller
// output on serial port:  timestamp, ambient, T1, RoR1, T2, RoR2, power
// output on LCD : timestamp, power(%), channel 2 temperature
//                 RoR 1,               channel 1 temperature

// Support for pBourbon.pde and 16 x 2 LCD
// MIT license: http://opensource.org/licenses/mit-license.php
// Jim Gallt and Bill Welch
// Derived from aBourbon.pde by Jim Gallt and Bill Welch
// Originally adapted from the a_logger.pde by Bill Welch.
//RC1 added support for 20 x 4 LCD and MCP23008 port expander

#define BANNER_CAT "Catuai 20101030 RC1" // version

// this library included with the arduino distribution
#include <Wire.h>

// these "contributed" libraries must be installed in your sketchbook's arduino/libraries folder
#include <TypeK.h>
#include <cADC.h>
#include <PWM16.h>
#include <cLCD.h>
#include "user.h"           //constants most likely to be changed by the user

#include <mcEEPROM.h>

#ifdef I2C_LCD
#include <cButton.h>
void checkButtons();    //function in input.pde
#endif

#ifdef ANALOG_IN
void readPot();       //function buttons.pde
#endif

#ifdef c23008
#include <c23008.h>
int OldButton;
c23008Expander expander; 
String message[]= {
  "Start", "Load Beans", "First Crack", "Second Crack","End Roast"};
//char sent to graph by key press
char key_event[] = {
  'x','L','F','S','E'};
int key_count = 0;   //Tracks location during roast 
float lastEventTime = 0;
void(* resetFunc) (void) = 0; //declare software reset function @ address 0
void p_button();    //function in buttons.pde
#endif

#ifdef FANCONTROL
int32_t fanSpeed;   //fan speed %
int32_t power = 0; // power output % to heater
PWM16 output;
#endif

#ifndef c23008
int get_ubtton();   //function in buttons.pde
#endif

#define TIME_BASE pwmN1Hz // cycle time for PWM output to SSR on Ot1 (if used)

#define BAUD 57600  // serial baud rate
#define BT_FILTER 10 // filtering level (percent) for displayed BT
#define ET_FILTER 10 // filtering level (percent) for displayed ET

// use RISE_FILTER to adjust the sensitivity of the RoR calculation
// higher values will give a smoother RoR trace, but will also create more
// lag in the RoR value.  A good starting point is 70%, but for air poppers
// or other roasters where BT might be jumpy, then a higher value of RISE_FILTER
// will be needed.  Theoretical max. is 99%, but watch out for the lag when
// you get above 85%.
#define RISE_FILTER 85 // heavy filtering on non-displayed BT for RoR calculations

// future versions will read all calibration values from EEPROM
#define CAL_GAIN 1.00 // substitute known gain adjustment from calibration
#define UV_OFFSET 0 // subsitute known value for uV offset in ADC
#define AMB_OFFSET 0 // substitute known value for amb temp offset (Celsius)

// ambient sensor should be stable, so quick variations are probably noise -- filter heavily
#define AMB_FILTER 75 // 70% filtering on ambient sensor readings

// *************************************************************************************


// ------------------------ other compile directives
#define MIN_DELAY 300   // ms between ADC samples (tested OK at 270)
#define NCHAN 2         // number of TC input channels
#define TC_TYPE TypeK  // thermocouple type / library
#define DP 1          // decimal places for output on serial port
#define D_MULT 0.001 // multiplier to convert temperatures from int to float

// --------------------------------------------------------------
// global variables

// eeprom calibration data structure
struct infoBlock {
  char PCB[40]; // identifying information for the board
  char version[16];
  float cal_gain;  // calibration factor of ADC at 50000 uV
  int16_t cal_offset; // uV, probably small in most cases
  float T_offset; // temperature offset (Celsius) at 0.0C (type T)
  float K_offset; // same for type K
};
mcEEPROM eeprom;
infoBlock caldata;

// class objects
cADC adc( A_ADC ); // MCP3424
ambSensor amb( A_AMB ); // MCP9800
filterRC fT[NCHAN]; // filter for displayed/logged ET, BT
filterRC fRise[NCHAN]; // heavily filtered for calculating RoR

int32_t temps[NCHAN]; //  stored temperatures are divided by D_MULT
int32_t ftemps[NCHAN]; // heavily filtered temps
int32_t ftimes[NCHAN]; // filtered sample timestamps
int32_t flast[NCHAN]; // for calculating derivative
int32_t lasttimes[NCHAN]; // for calculating derivative

#ifdef ANALOG_IN
int32_t aval = 0; // analog input value for manual control
uint8_t anlg = 0; // analog input pin
int32_t power = 0; // power output to heater
PWM16 output;
#endif
void roast_mode_select();  //routine in mode.pde
void fly_changes();        //routine in mode.pde
void display_roast();      //routine in display.pde
void display_startup();    //routine in display.pde
// LCD output strings
char smin[3],ssec[3],st1[6],st2[6],sRoR1[7];

// ---------------------------------- LCD interface definition
#ifdef I2C_LCD
#define BACKLIGHT lcd.backlight();
cLCD lcd; // I2C LCD interface
cButtonPE16 buttons; // button array on I2C port expander
#else

#define BACKLIGHT ;
#define RS 2
#define ENABLE 4
#define D4 7
#define D5 8
#define D6 12
#define D7 13
LiquidCrystal lcd( RS, ENABLE, D4, D5, D6, D7 ); // standard 4-bit parallel interface

#endif

// used in main loop
float timestamp = 0;
float timestamp2 = 0;
uint32_t time0 = 0;  // ms value when we want to start recording
uint32_t time1 = 0;  // ms value when we want to start tracking event time
uint32_t timeReset = 0;  // ms value when we want to start tracking enter key time
boolean first;
uint32_t nextLoop;

// declarations needed to maintain compatibility with Eclipse/WinAVR/gcc
void updateLCD( float t1, float t2, float RoR );
void resetTimer();

// --------------------------------------------------- returns RoR
// T1, T2 = temperatures x 1000
// t1, t2 = time marks, milliseconds
float calcRise( int32_t T1, int32_t T2, int32_t t1, int32_t t2 ) {
  int32_t dt = t2 - t1;
  if( dt == 0 ) return 0.0;  // fixme -- throw an exception here?
  float dT = (T2 - T1) * D_MULT;
  float dS = dt * 0.001;
  return ( dT / dS ) * 60.0; // rise per minute
}

// ------------------------------------------------------------------
void logger()
{
  int i;
  float RoR,t1,t2,t_amb;
  float rx;

  // print timestamp from when samples were taken
  Serial.print( timestamp, DP );

  // print ambient
  Serial.print(",");
  t_amb = amb.getAmbF();
  Serial.print( t_amb, DP );

  // print temperature, rate for each channel
  i = 0;
  if( NCHAN >= 1 ) {
    Serial.print(",");
    Serial.print( t1 = D_MULT*temps[i], DP );
    Serial.print(",");
    RoR = calcRise( flast[i], ftemps[i], lasttimes[i], ftimes[i] );
    Serial.print( RoR , DP );
    i++;
  };

  if( NCHAN >= 2 ) {
    Serial.print(",");
    Serial.print( t2 = D_MULT * temps[i], DP );
    Serial.print(",");
    rx = calcRise( flast[i], ftemps[i], lasttimes[i], ftimes[i] );
    Serial.print( rx , DP );
    i++;
  };

  if( NCHAN >= 3 ) {
    Serial.print(",");
    Serial.print( D_MULT * temps[i], DP );
    Serial.print(",");
    rx = calcRise( flast[i], ftemps[i], lasttimes[i], ftimes[i] );
    Serial.print( rx , DP );
    i++;
  };

  if( NCHAN >= 4 ) {
    Serial.print(",");
    Serial.print( D_MULT * temps[i], DP );
    Serial.print(",");
    rx = calcRise( flast[i], ftemps[i], lasttimes[i], ftimes[i] );
    Serial.print( rx , DP );
    i++;
  };

  // log the power level to the serial port
  Serial.print(",");
#ifdef ANALOG_IN
  Serial.print( power );
//#else
//  Serial.print( (int32_t)0 );
#endif

#ifdef FANCONTROL
  Serial.print( power );
  Serial.print(",");
  Serial.print(fanSpeed);
#endif 

  Serial.println();

  updateLCD( t1, t2, RoR );  
};

// --------------------------------------------
void updateLCD( float t1, float t2, float RoR ) {
  // form the timer output string in min:sec format
  int itod = round( timestamp );
  if( itod > 3599 ) itod = 3599;
  sprintf( smin, "%02u", itod / 60 );
  sprintf( ssec, "%02u", itod % 60 );
  lcd.setCursor(0,0);
  lcd.print( smin );
  lcd.print( ":" );
  lcd.print( ssec );

#ifdef LCD_20_4 
  //Display phase counter
  itod = round( timestamp2 );
  if( itod > 3599 ) itod = 3599;
  sprintf( smin, "%02u", itod / 60 );
  sprintf( ssec, "%02u", itod % 60 );
  lcd.setCursor(0,2);
  lcd.print( smin );
  lcd.print( ":" );
  lcd.print( ssec );
  //Display event time
  itod = round( timestamp - lastEventTime );
  if( itod > 3599 ) itod = 3599;
  sprintf( smin, "%02u", itod / 60 );
  sprintf( ssec, "%02u", itod % 60 );
  lcd.setCursor(0,3);
  lcd.print( smin );
  lcd.print( ":" );
  lcd.print( ssec );
#endif

  // channel 2 temperature 
  int it02 = round( t2 );
  if( it02 > 999 ) it02 = 999;
  else if( it02 < -999 ) it02 = -999;
  sprintf( st2, "%3d", it02 );
  lcd.setCursor( 11, 0 );
  lcd.print( "E " );
  lcd.print( st2 ); 
#ifdef LCD_20_4 
  //Now show Celsius
  it02 = round(F_TO_C( t2));
  if( it02 > 999 ) it02 = 999;
  else if( it02 < -999 ) it02 = -999;
  sprintf( st2, "%4d", it02 );
  lcd.print( st2 );
#endif
  // channel 1 RoR
  int iRoR = round( RoR );
  if( iRoR > 99 ) 
    iRoR = 99;
  else
    if( iRoR < -99 ) iRoR = -99; 
  sprintf( sRoR1, "%0+3d", iRoR );
  lcd.setCursor(0,1);
  lcd.print( "RoR:");
  lcd.print( sRoR1 );

  // channel 1 temperature
  int it01 = round( t1 );
  if( it01 > 999 ) 
    it01 = 999;
  else
    if( it01 < -999 ) it01 = -999;
  sprintf( st1, "%3d", it01 );
  lcd.setCursor( 11, 1 );
  lcd.print("B ");
  lcd.print(st1);
#ifdef LCD_20_4   
  //Now show Celsius
  it01 = round(F_TO_C( t1));
  if( it01 > 999 ) 
    it01 = 999;
  else
    if( it01 < -999 ) it01 = -999;
  sprintf( st1, "%4d", it01 );
  lcd.print(st1);
#endif  
}


// ----------------------------------
void checkStatus( uint32_t ms ) { // this is an active delay loop
  uint32_t tod = millis();
  while( millis() < tod + ms ) {

#ifdef ANALOG_IN
    //  readPot();
#endif  
#ifdef I2C_LCD
    checkButtons();
#endif
#ifdef c23008
    p_button();
#endif
  }
}

// --------------------------------------------------------------------------
void get_samples() // this function talks to the amb sensor and ADC via I2C
{
  int32_t v;
  TC_TYPE tc;
  float tempC;

  for( int j = 0; j < NCHAN; j++ ) { // one-shot conversions on both chips
    adc.nextConversion( j ); // start ADC conversion on channel j
    amb.nextConversion(); // start ambient sensor conversion
    checkStatus( MIN_DELAY ); // give the chips time to perform the conversions
    ftimes[j] = millis(); // record timestamp for RoR calculations
    amb.readSensor(); // retrieve value from ambient temp register
    v = adc.readuV(); // retrieve microvolt sample from MCP3424
    tempC = tc.Temp_C( 0.001 * v, amb.getAmbC() ); // convert to Celsius
    v = round( C_TO_F( tempC ) / D_MULT ); // store results as integers
    temps[j] = fT[j].doFilter( v ); // apply digital filtering for display/logging
    ftemps[j] =fRise[j].doFilter( v ); // heavier filtering for RoR
  }
};

// resets the timestamp origin
void resetTimer() {
  time0 = millis();
  time1 = millis();
  timestamp = 0.0;
  nextLoop = 1000;
}

// ------------------------------------------------------------------------
// MAIN
//
void setup()
{
  delay(100);
  Wire.begin();

#ifdef LCD_20_4 
  lcd.begin(20, 4);
#else  
  lcd.begin(16, 2);
#endif

  BACKLIGHT;
  lcd.setCursor( 0, 0 );
  lcd.print( BANNER_CAT ); // display version banner
#ifdef I2C_LCD
  buttons.begin( 4 );
  buttons.readButtons();
#endif

  Serial.begin(BAUD);

  // read calibration and identification data from eeprom
  if( eeprom.read( 0, (uint8_t*) &caldata, sizeof( caldata) ) == sizeof( caldata ) ) {
    Serial.println("# EEPROM data read: ");
    Serial.print("# ");
    Serial.print( caldata.PCB); 
    Serial.print("  ");
    Serial.println( caldata.version );
    Serial.print("# ");
    Serial.print( caldata.cal_gain, 4 ); 
    Serial.print("  ");
    Serial.println( caldata.K_offset, 2 );
    lcd.setCursor( 0, 1 ); // echo EEPROM data to LCD
    lcd.print( caldata.PCB );
    adc.setCal( caldata.cal_gain, caldata.cal_offset );
    amb.setOffset( caldata.K_offset );
  }
  else { // if there was a problem with EEPROM read, then use default values
    Serial.println("# Failed to read EEPROM.  Using default calibration data. ");
    lcd.setCursor( 0, 1 ); // echo EEPROM data to LCD
    lcd.print( "No EEPROM - OK" );
    adc.setCal( CAL_GAIN, UV_OFFSET );
    amb.setOffset( AMB_OFFSET );
  }   

  // write header to serial port
  Serial.print("# time,ambient,T0,rate0");
  if( NCHAN >= 2 ) Serial.print(",T1,rate1");
  if( NCHAN >= 3 ) Serial.print(",T2,rate2");
  if( NCHAN >= 4 ) Serial.print(",T3,rate3");
  Serial.print(",power");
  #ifdef FANCONTROL
   Serial.print(",fan");
   #endif
  Serial.println();

  amb.init( AMB_FILTER );  // initialize ambient temp filtering
  for( int j = 0; j < NCHAN; j++ ) { // initialize digital filters for each channel
    if( j == 1 )
      fT[j].init( ET_FILTER ); // special value for channel 2 (ET)
    else
      fT[j].init( BT_FILTER ); // digital filtering on BT
    fRise[j].init( RISE_FILTER ); // digital filtering for RoR calculation
  }

#ifdef ANALOG_IN
  output.Setup( TIME_BASE );
#endif

  first = true;
  delay( 2000 ); // display banner for a while
  lcd.clear();
  resetTimer();

#ifdef c23008
  expander.begin(0,0xff);  //init 23008 chip at address 0x20, set all ports to input with pullup and inverted
  //  expander.setInputs(0xff);
  //  expander.setPullups(0xFF);
  //  expander.setInverse(0xFF);
  power = 0;

  lcd.setCursor( 8, 0 );
  lcd.print( "0%" );
  lcd.setCursor( 7, 2 );
  lcd.print(STARTSPEED,DEC );
  lcd.print("% " );
  lcd.setCursor( 8, 3 );
  lcd.print(message[key_count] );
#endif
#ifdef FANCONTROL
  fanSpeed = STARTSPEED;
  pinMode(FANPIN, OUTPUT); 
  lcd.setCursor( 7, 2 );
  lcd.print(STARTSPEED,DEC );
  lcd.print("% " );
#endif  

}


// -----------------------------------------------------------------
void loop() {
  float idletime;

  // update on even 1 second boundaries
  while ( ( millis() - time0 ) < nextLoop ) { // delay until time for next loop
    if( !first ) {

#ifdef ANALOG_IN
      //  readPot();
#endif

#ifdef I2C_LCD
      checkButtons();
#endif

#ifdef c23008
      p_button();
#endif
    }
  }

  nextLoop += 1000; // time mark for start of next update 
  timestamp = float( millis() - time0 ) * 0.001;
  timestamp2 = float( millis() - time1 ) * 0.001;
  get_samples(); // retrieve values from MCP9800 and MCP3424
  if( first ) // use first samples for RoR base values only
    first = false;
  else {
    logger(); // output results to serial port
#ifdef ANALOG_IN
    output.Out( power, 0 ); // update the power output on the SSR drive Ot1
#endif    
#ifdef FANCONTROL
    output.Out( power, 0 ); // update the power output on the SSR drive Ot1
    analogWrite(FANPIN, (int)(fanSpeed *2.55) );  //adjust fan speed  
#endif
  }

  for( int j = 0; j < NCHAN; j++ ) {
    flast[j] = ftemps[j]; // use previous values for calculating RoR
    lasttimes[j] = ftimes[j];
  }

  idletime = float( millis() - time0 ) * 0.001;
  idletime = 1.0 - (idletime - timestamp);
  // arbitrary: complain if we don't have at least 10mS left
  if (idletime < 0.010) {
    Serial.print("# idle: ");
    Serial.println(idletime);
  }
}















