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

#define BANNER_CAT "Catuai 20101010" // version

// this library included with the arduino distribution
#include <Wire.h>

// these "contributed" libraries must be installed in your sketchbook's arduino/libraries folder
#include <TypeK.h>
#include <cADC.h>
#include <PWM16.h>
#include <cLCD.h>
#include <cButton.h>
#include <mcEEPROM.h>

// *************************************************************************************
// NOTE TO USERS: the following parameters should be
// be reviewed to suit your preferences and hardware setup.  
// First, load and edit this sketch in the Arduino IDE.
// Next compile the sketch and upload it to the Duemilanove.

// ------------------ optionally, use I2C port expander for LCD interface
#define I2C_LCD //comment out to use the standard parallel LCD 4-bit interface

// ------ connect a potentiomenter to ANLG1 for manual heater control using Ot1
#define ANALOG_IN // comment this line out if you do not use this feature
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
#define RISE_FILTER 70 // heavy filtering on non-displayed BT for RoR calculations

// future versions will read all calibration values from EEPROM
#define CAL_GAIN 1.00 // substitute known gain adjustment from calibration
#define UV_OFFSET 0 // subsitute known value for uV offset in ADC
#define AMB_OFFSET 0 // substitute known value for amb temp offset (Celsius)

// ambient sensor should be stable, so quick variations are probably noise -- filter heavily
#define AMB_FILTER 70 // 70% filtering on ambient sensor readings

// *************************************************************************************


// ------------------------ other compile directives
#define MIN_DELAY 300   // ms between ADC samples (tested OK at 270)
#define NCHAN 2   // number of TC input channels
#define TC_TYPE TypeK  // thermocouple type / library
#define DP 1  // decimal places for output on serial port
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
uint32_t time0 = 0;  // ms value when we want to start recording
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
#else
  Serial.print( (int32_t)0 );
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
 
  // channel 2 temperature 
  int it02 = round( t2 );
  if( it02 > 999 ) it02 = 999;
  else if( it02 < -999 ) it02 = -999;
  sprintf( st2, "%3d", it02 );
  lcd.setCursor( 11, 0 );
  lcd.print( "E " );
  lcd.print( st2 ); 

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
}

#ifdef ANALOG_IN
// ---------------------------------
void readPot() { // read analog port 1, round to nearest 5% output value
  char pstr[5];
  int32_t mod, trial;
  aval = analogRead( anlg );
  trial = aval * 100;
  trial /= 1023;
  mod = trial % 5;
  trial = ( trial / 5 ) * 5; // truncate to multiple of 5
  if( mod >= 3 )
    trial += 5;
  if( trial <= 100 && trial != power ) { // did it change?
    power = trial;
    sprintf( pstr, "%3d", (int)power );
    lcd.setCursor( 6, 0 );
    lcd.print( pstr ); lcd.print("%");
  }
}
#endif

#ifdef I2C_LCD
// ----------------------------------
void checkButtons() { // take action if a button is pressed
  if( buttons.readButtons() ) {
    if( buttons.keyPressed( 3 ) && buttons.keyChanged( 3 ) ) {// left button = start the roast
      resetTimer();
      Serial.println( "# STRT (timer reset)");
    }
    else if( buttons.keyPressed( 2 ) && buttons.keyChanged( 2 ) ) { // 2nd button marks first crack
      resetTimer();
      Serial.println( "# FC (timer reset)");
    }
    else if( buttons.keyPressed( 1 ) && buttons.keyChanged( 1 ) ) { // 3rd button marks second crack
      resetTimer();
      Serial.println( "# SC (timer reset)");
    }
    else if( buttons.keyPressed( 0 ) && buttons.keyChanged( 0 ) ) { // 4th button marks eject
      resetTimer();
      Serial.println( "# EJCT (timer reset)");
    }
  }
}
#endif

// ----------------------------------
void checkStatus( uint32_t ms ) { // this is an active delay loop
  uint32_t tod = millis();
  while( millis() < tod + ms ) {
#ifdef ANALOG_IN
    readPot();
#endif
#ifdef I2C_LCD
    checkButtons();
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
  lcd.begin(16, 2);
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
    Serial.print( caldata.PCB); Serial.print("  ");
    Serial.println( caldata.version );
    Serial.print("# ");
    Serial.print( caldata.cal_gain, 4 ); Serial.print("  ");
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
  delay( 3000 ); // display banner for a while
  lcd.clear();
  resetTimer();
}

// -----------------------------------------------------------------
void loop() {
  float idletime;

  // update on even 1 second boundaries
  while ( ( millis() - time0 ) < nextLoop ) { // delay until time for next loop
    if( !first ) {
#ifdef ANALOG_IN
    readPot();
#endif
#ifdef I2C_LCD
    checkButtons();
#endif
    }
  }
  
  nextLoop += 1000; // time mark for start of next update 
  timestamp = float( millis() - time0 ) * 0.001;
  get_samples(); // retrieve values from MCP9800 and MCP3424
  if( first ) // use first samples for RoR base values only
    first = false;
  else {
    logger(); // output results to serial port
 #ifdef ANALOG_IN
    output.Out( power, 0 ); // update the power output on the SSR drive Ot1
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

