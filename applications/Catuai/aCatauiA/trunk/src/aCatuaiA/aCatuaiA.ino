// aCatuaiQ.pde
//
// 2-channel Rise-o-Meter and manual roast controller
// output on serial port:  timestamp, ambient, T1, RoR1, T2, RoR2, heater, fan
// output on LCD : timestamp, power(%), channel 2 temperature
//                 RoR 1,               channel 1 temperature

// OT1 goes to any SSR or triac for controlling the heater, integral cycle control
// OT2 goes to random fire SSR or triac for controlling the fan via phase angle control
// I/O2 or I/O3 connected to external zero cross detector (logic low on zero cross, ONCE per cycle ONLY)

// Support for pBourbon.pde and 16 x 2 LCD

// Derived from aBourbon.pde by Jim Gallt and Bill Welch
// Originally adapted from the a_logger.pde by Bill Welch.
// Hacked by Eric Mills to target generic air roasters with VC air supply
//
// This version tested on Mega2560 with 4bit LCD/keyboard shield (D4-D10) requiring following hardware mods:
// Mega2560:
//    Jumper SCL/SCA to A4/A5 pins on back of board (TC4 not R3, needs SCL & SCA)
// TC4:
//    Cut driver output to OT1 & OT2 on top of board and wire output pins to D11 & D12 directly (I bypassed drivers)
//    Cut Anlg1, move from A0 to A2 as std LCD/keypad uses A0 for keys


// *** BSD License ***
// ------------------------------------------------------------------------------------------
// Copyright (c) 2011, MLG Properties, LLC
// All rights reserved.
//
// Contributor:  Jim Gallt, Eric Mills
//
// Redistribution and use in source and binary forms, with or without modification, are 
// permitted provided that the following conditions are met:
//
//   Redistributions of source code must retain the above copyright notice, this list of 
//   conditions and the following disclaimer.
//
//   Redistributions in binary form must reproduce the above copyright notice, this list 
//   of conditions and the following disclaimer in the documentation and/or other materials 
//   provided with the distribution.
//
//   Neither the name of the MLG Properties, LLC nor the names of its contributors may be 
//   used to endorse or promote products derived from this software without specific prior 
//   written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS 
// OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF 
// MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL 
// THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) 
// HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, 
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS 
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
// ------------------------------------------------------------------------------------------

// --------------------------------------------------------------------------------------------
// Revision history
// 14-Oct-2011  : Created
// 15-Oct-2011  : Revised trying to fix lock ups when reading ANLG
// 02-Nov-2011  : Added watchdog on AC power
// 21-Nov-2011  : Tested successfully on popper P1 fan motor
// 05-Oct-2012  : Removed watchdog on AC, new manual control code,
// 		  tested with generic VC motor air roaster on Mega2560 NOT Uno

// -----------------------------------------------------------------------------------------------
#define BANNER_CAT "CatuaiA beta " // version

// The user.h file contains user-definable compiler options
// It must be located in the same folder as aCatuai.ino
#include "user.h"
// code for integral cycle control and phase angle control
#include "phase_ctrl.h"

// this library included with the arduino distribution
#include <Wire.h>

// these "contributed" libraries must be installed in your sketchbook's arduino/libraries folder
#include <thermocouple.h>
#include <cADC.h>
#include <cLCD.h>
#include <mcEEPROM.h>

#ifdef LCDAPTER  // implement buttons only if the LCDAPTER option is selected in user.h
#include <cButton.h>
#endif

// ------------------------ other compile directives
#define MIN_DELAY 300   // ms between ADC samples (tested OK at 270)
#define NCHAN 2   // number of TC input channels
#define DP 1  // decimal places for output on serial port
#define D_MULT 0.001 // multiplier to convert temperatures from int to float
#define RESET "RESET" // text string command for resetting the timer
#define MAX_COMMAND 80 // max length of a command string
#define LOOPTIME 1000 // cycle time, in ms

// --------------------------------------------------------------
// global variables

// eeprom calibration data structure
calBlock caldata;

// class objects
mcEEPROM eeprom;
cADC adc( A_ADC ); // MCP3424
ambSensor amb( A_AMB ); // MCP9800
filterRC fT[NCHAN]; // filter for displayed/logged ET, BT
filterRC fRise[NCHAN]; // heavily filtered for calculating RoR
filterRC fRoR[NCHAN]; // post-filtering on RoR values

int32_t temps[NCHAN]; //  stored temperatures are divided by D_MULT
int32_t ftemps[NCHAN]; // heavily filtered temps
int32_t ftimes[NCHAN]; // filtered sample timestamps
int32_t flast[NCHAN]; // for calculating derivative
int32_t lasttimes[NCHAN]; // for calculating derivative

#ifdef ANALOG_IN
#define ANLG1	2		// analog input pins
#define ANLG2	1
#define	A_HYST	3		// ADC counts hysteresis on analogue inputs
#define ANLG_DELAY delay(3);	// Delay in ms before each reading, affects fan on ramp speed
//#define ANLG_DELAY ;
static uint8_t heater = 255;	// Last setting ICC, force initial display update
static uint8_t fan = 255;	// Last setting PAC
#endif
static int currKey = 1023;	// Currently detected debounced keypad analogue value (0->1023)

// LCD output strings
char smin[3],ssec[3],st1[6],st2[6],sRoR1[7];

// ---------------------------------- LCD interface definition
#ifdef LCDAPTER
  #define BACKLIGHT lcd.backlight();
  cLCD lcd; // I2C LCD interface
  cButtonPE16 buttons; // class object to manage button presses
#else // parallel interface, standard LiquidCrystal
  #define BACKLIGHT digitalWrite(10, HIGH);
  #define RS 8
  #define ENABLE 9
  #define D4 4
  #define D5 5
  #define D6 6
  #define D7 7
  LiquidCrystal lcd( RS, ENABLE, D4, D5, D6, D7 ); // standard 4-bit parallel interface
#endif

// used in main loop
static float timestamp = 0;
static boolean first;
uint32_t nextLoop;
static float reftime; // reference for measuring elapsed time
static boolean standAlone = true; // default is standalone mode

static char command[MAX_COMMAND+1]; // input buffer for commands from the serial port

// declaration needed to maintain compatibility with Eclipse/WinAVR/gcc
static void updateLCD( float t1, float t2, float RoR );

// T1, T2 = temperatures x 1000
// t1, t2 = time marks, milliseconds
// ---------------------------------------------------
static float calcRise( int32_t T1, int32_t T2, int32_t t1, int32_t t2 ) {
  int32_t dt = t2 - t1;
  if( dt == 0 ) return 0.0;  // fixme -- throw an exception here?
  float dT = (T2 - T1) * D_MULT;
  float dS = dt * 0.001; // convert from milli-seconds to seconds
  return ( dT / dS ) * 60.0; // rise per minute
}

// ------------------------------------------------------------------
static void logger()
{
  int i;
  float RoR,t1,t2,t_amb;
  float rx;

  // print timestamp from when samples were taken
  Serial.print( timestamp, 0 );

  // print ambient
  Serial.print(",");
#ifdef CELSIUS
  t_amb = amb.getAmbC();
#else
  t_amb = amb.getAmbF();
#endif
  Serial.print( t_amb, DP );

  // print temperature, rate for each channel
  i = 0;
  if( NCHAN >= 1 ) {
    Serial.print(",");
    Serial.print( t1 = D_MULT*temps[i], DP );
    Serial.print(",");
    RoR = calcRise( flast[i], ftemps[i], lasttimes[i], ftimes[i] );
    RoR = fRoR[i].doFilter( RoR /  D_MULT ) * D_MULT; // perform post-filtering on RoR values
    Serial.print( RoR , DP );
    i++;
  };
  
  if( NCHAN >= 2 ) {
    Serial.print(",");
    Serial.print( t2 = D_MULT * temps[i], DP );
    Serial.print(",");
    rx = calcRise( flast[i], ftemps[i], lasttimes[i], ftimes[i] );
    rx = fRoR[i].doFilter( rx / D_MULT ) * D_MULT; // perform post-filtering on RoR values
    Serial.print( rx , DP );
    i++;
  };
  
  if( NCHAN >= 3 ) {
    Serial.print(",");
    Serial.print( D_MULT * temps[i], DP );
/*    Serial.print(",");
    rx = calcRise( flast[i], ftemps[i], lasttimes[i], ftimes[i] );
    rx = fRoR[i].doFilter( rx / D_MULT ) * D_MULT; // perform post-filtering on RoR values
    Serial.print( rx , DP ); */
    i++;
  };
  
  if( NCHAN >= 4 ) {
    Serial.print(",");
    Serial.print( D_MULT * temps[i], DP );
/*    Serial.print(",");
    rx = calcRise( flast[i], ftemps[i], lasttimes[i], ftimes[i] );
    rx = fRoR[i].doFilter( rx / D_MULT ) * D_MULT; // perform post-filtering on RoR values
    Serial.print( rx , DP ); */
  };

// log the power level to the serial port
#ifdef ANALOG_IN
  Serial.print(",");
  Serial.print( heater );
  Serial.print( "," );
  Serial.print( fan );
#endif

  Serial.println();
  updateLCD( t1, t2, RoR );  
};

// --------------------------------------------
static void updateLCD( float t1, float t2, float RoR ) {
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
  lcd.print( "RT");
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

// Read analog value and map to 0 to 100 - ICC heater
// ICC_MAX is limited to < 128
static void readAnlg1() {
    char pstr[5];
    uint8_t reading;
    ANLG_DELAY;
    uint16_t aval = analogRead(ANLG1);
    if (aval < ((uint16_t)heater * 512) / (ICC_MAX / 2))	// "heater" is also last knob posn
	aval += A_HYST;
    else
	aval -= A_HYST;
    reading = ((aval + 512 / ICC_MAX) * (ICC_MAX / 2)) / 512;
    if (fan == 0) reading = 0;			// Fan off forces heater off
    if (reading != heater) {
	heater = reading;
	output_level_icc(heater);
	sprintf(pstr, "%3d%%", heater);
	lcd.setCursor(6, 0);
	lcd.print(pstr);
    }
}

// Read analogue value & map to: 0, FAN_MIN -> FAN_MAX over full range of pot
// Overridden to FAN_EJECT by eject key pressed
static void readAnlg2() {
    char pstr[4];
    uint8_t reading;
    static uint8_t knob2;			// Raw knob position: 0 -> FAN_MAX - FAN_MIN + 1
    ANLG_DELAY;
    uint16_t aval = analogRead(ANLG2);
#if FAN_MAX - FAN_MIN + 1 < 64			// Fits in 16 bits
    if (aval < ((uint16_t)knob2 * 1024) / (FAN_MAX - FAN_MIN + 1))
	aval += A_HYST;
    else
	aval -= A_HYST;
    reading = ((aval + 1024 / (2 * (FAN_MAX - FAN_MIN + 1))) * (FAN_MAX - FAN_MIN + 1)) / 1024;
#elif FAN_MAX - FAN_MIN + 1 < 128		// Rounds up ticks to even max
    if (aval < ((uint16_t)knob2 * 512) / ((FAN_MAX - FAN_MIN + 2) / 2))
	aval += A_HYST;
    else
	aval -= A_HYST;
    reading = ((aval + 512 / (FAN_MAX - FAN_MIN + 1)) * ((FAN_MAX - FAN_MIN + 2) / 2)) / 512;
#else
#error "Too many ticks in fan control"
#endif
    knob2 = reading;				// Keep raw position for hyst calc
    if (reading != 0)
	reading += FAN_MIN - 1;
    if (currKey < 30 && heater == 0)		// Eject key active, NOT roasting!
	reading = FAN_EJECT;
    if (reading != fan) {
	fan = reading != 0 && fan < reading - 1 ? fan + 1 : reading;	// Ramp up to avoid inrush current
	output_level_pac(fan);
	sprintf(pstr, "%3d", fan);
	lcd.setCursor(6, 1);
	lcd.print(pstr);
    }
}
#endif

#ifdef LCDAPTER
// ----------------------------------
static void checkButtons() { // take action if a button is pressed
  if( buttons.readButtons() ) {
    if( buttons.keyPressed( 3 ) && buttons.keyChanged( 3 ) ) {// left button = start the roast
      if( standAlone ) { // reset the timer
        resetTimer();
      }
      else {
        Serial.print( "# STRT,");
        Serial.println( timestamp, DP );
        buttons.ledOn ( 2 ); // turn on leftmost LED when start button is pushed
      }
    }
    else if( buttons.keyPressed( 2 ) && buttons.keyChanged( 2 ) ) { // 2nd button marks first crack
      if( standAlone ) {
      }
      else {
        Serial.print( "# FC,");
        Serial.println( timestamp, DP );
        buttons.ledOn ( 1 ); // turn on middle LED at first crack
      }
    }
    else if( buttons.keyPressed( 1 ) && buttons.keyChanged( 1 ) ) { // 3rd button marks second crack
      if( standAlone ) {
      }
      else {
        Serial.print( "# SC,");
        Serial.println( timestamp, DP );
        buttons.ledOn ( 0 ); // turn on rightmost LED at second crack
      }
    }
    else if( buttons.keyPressed( 0 ) && buttons.keyChanged( 0 ) ) { // 4th button marks eject
      if( standAlone ) {
      }
      else {
        Serial.print( "# EJCT,");
        Serial.println( timestamp, DP );
        buttons.ledAllOff(); // turn off all LED's when beans are ejected
      }
    }
  }
}
#endif // LCDAPTER

// -------------------------------------
static void append( char* str, char c ) { // reinventing the wheel
  int len = strlen( str );
  str[len] = c;
  str[len+1] = '\0';
}

// ----------------------------
static void resetTimer() {
  Serial.println("# Reset"); // write message to log
  nextLoop = 10 + millis(); // wait 10 ms and force a sample/log cycle
  reftime = 0.001 * nextLoop; // reset the reference point for timestamp
  return;
}

// -------------------------------------
static void processCommand() {  // a newline character has been received, so process the command
  if( ! strcmp( command, RESET ) ) { // RESET command received, so reset the timer
    resetTimer();
    standAlone = false;
  }
  return;
}

// -------------------------------------
static void checkSerial() {  // buffer the input from the serial port
  char c;
  while( Serial.available() > 0 ) {
    c = Serial.read();
    if( ( c == '\n' ) || ( strlen( command ) == MAX_COMMAND ) ) { // check for newline, or buffer overflow
      processCommand();
      strcpy( command, "" ); // empty the buffer
    } // end if
    else {
      append( command, c );
    } // end else
  } // end while
}

// ----------------------------------
static void checkStatus( uint32_t ms ) { // this is an active delay loop
  uint32_t tod = millis();
  while( millis() < tod + ms ) {
#ifdef ANALOG_IN
    readAnlg1();
    readAnlg2();
#endif
#ifdef LCDAPTER
    checkButtons();
#else
    int key = analogRead(0);
    if (key != currKey) {
	delay(20);				// Debounce
	if (key == analogRead(0)) {
	    currKey = key;
	    if (key < 30) {			// Right key - max fan eject beans - picked up in analogue fan read
	    }
	    else if (key < 150) {		// Up key - log SC
		Serial.println("# SC");
	    }
	    else if (key < 360) {		// Down key - cool down
		Serial.println("# Cool");
	    }
	    else if (key < 535) {		// Left key - log FC
		Serial.println("# FC");
	    }
	    else if (key < 760) {		// Select key - reset & log start
		resetTimer();
	    }
	}
    }
#endif
  }
}

// --------------------------------------------------------------------------
static void get_samples() // this function talks to the amb sensor and ADC via I2C
{
  int32_t v;
  TC_TYPE tc;
  float tempC;
  
  for( int j = 0; j < NCHAN; j++ ) {	// one-shot conversions on both chips
    adc.nextConversion( j );		// start ADC conversion on channel j
    amb.nextConversion();		// start ambient sensor conversion
    checkStatus( MIN_DELAY );		// give the chips time to perform the conversions
    ftimes[j] = millis();		// record timestamp for RoR calculations
    amb.readSensor();			// retrieve value from ambient temp register
    v = adc.readuV();			// retrieve microvolt sample from MCP3424
    tempC = tc.Temp_C( 0.001 * v, amb.getAmbC() );	// convert to Celsius
#ifdef CELSIUS
    v = round( tempC / D_MULT );	// store results as integers
#else
    v = round( C_TO_F( tempC ) / D_MULT ); // store results as integers
#endif
    temps[j] = fT[j].doFilter( v );	// apply digital filtering for display/logging
    ftemps[j] =fRise[j].doFilter( v );	// heavier filtering for RoR
  }
};
  
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
#ifdef CELSIUS  // display a C or F after the version to indicate temperature scale
  lcd.print( "C" );
#else
  lcd.print( "F" );
#endif
  
#ifdef LCDAPTER
  buttons.begin( 4 );
  buttons.readButtons();
  buttons.ledAllOff();
#endif

  Serial.begin(BAUD);
  amb.init( AMB_FILTER );  // initialize ambient temp filtering

  // read calibration and identification data from eeprom
  if( readCalBlock( eeprom, caldata ) ) {
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
#ifdef ANALOG_IN
  Serial.print(",heater,fan");
#endif
  Serial.println();
 
  fT[0].init( BT_FILTER ); // digital filtering on BT
  fT[1].init( ET_FILTER ); // digital filtering on ET
  fRise[0].init( RISE_FILTER ); // digital filtering for RoR calculation
  fRise[1].init( RISE_FILTER ); // digital filtering for RoR calculation
  fRoR[0].init( ROR_FILTER ); // post-filtering on RoR values
  fRoR[1].init( ROR_FILTER ); // post-filtering on RoR values

  init_phase_ctrl();
  
  delay( 1800 );
  nextLoop = 2000;
  reftime = 0.001 * nextLoop; // initialize reftime to the time of first sample
  first = true;
  lcd.clear();
  pinMode(DEBUG_PIN, OUTPUT);
}

// -----------------------------------------------------------------
void loop() {
  float idletime;
  uint32_t thisLoop;

  // delay loop to force update on even LOOPTIME boundaries
  while ( millis() < nextLoop ) { // delay until time for next loop
    if( !first ) { // do not want to check the buttons on the first time through
#ifdef LCDAPTER
      checkButtons();
#endif
#ifdef ANALOG_IN
      readAnlg1();
      readAnlg2();
#endif
      checkSerial(); // Has a command been received?
    } // if not first
  }
 
  thisLoop = millis(); // actual time marker for this loop
  timestamp = 0.001 * float( thisLoop ) - reftime; // system time, seconds, for this set of samples
  get_samples(); // retrieve values from MCP9800 and MCP3424
  if( first ) // use first samples for RoR base values only
    first = false;
  else {
    logger(); // output results to serial port
  }
    // check and see if AC is present and drive debug LED
    // digitalWrite(DEBUG_PIN, ACdetect() ? HIGH : LOW);

  for( int j = 0; j < NCHAN; j++ ) {
    flast[j] = ftemps[j]; // use previous values for calculating RoR
    lasttimes[j] = ftimes[j];
  }
  // arbitrary: complain if we don't have at least 50mS left
  idletime = LOOPTIME - ( millis() - thisLoop );
  if (idletime < 50 ) {
    Serial.print("# idle: ");
    Serial.println(idletime);
  }
  nextLoop += LOOPTIME; // time mark for start of next update 
}
