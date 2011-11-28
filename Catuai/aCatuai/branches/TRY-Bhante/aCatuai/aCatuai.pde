// aCatuai.pde Version 1.10
//
// 2-channel Rise-o-Meter and manual roast controller
// output on serial port:  timestamp, ambient, T1, RoR1, T2, RoR2, [power1], [power2]
// output on LCD : timestamp, power(%), channel 2 temperature
//                 RoR 1,               channel 1 temperature

// Support for pBourbon.pde and 16 x 2 LCD

// Derived from aBourbon.pde by Jim Gallt and Bill Welch
// Originally adapted from the a_logger.pde by Bill Welch.

// *** BSD License ***
// ------------------------------------------------------------------------------------------
// Copyright (c) 2011, MLG Properties, LLC
// All rights reserved.
//
// Contributor:  Jim Gallt
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
// May 22, 2011 : Revisions to respond to RESET command from host, aBourbon-style
//                Added PWM fan control code for IO3
// Version 1.00
// May 27, 2011 : Customisations by BM: log output to 3 decimal places
// Jul 11, 2011 : Customisations by BM: LCD output improved
// July 22, 2011: Revised for compatibility with class PWM_IO3 in the PWM16 library
// Version 1.10
// Sept. 3, 2011: Now uses readCalBlock() from mcEEPROM library for better error checking.
//                Now uses thermocouple.h.  Support for type K, type J, and type T
//                In standalone mode, STRT button now resets the timer.  LED's not used in standalone.
// Sept  4, 2011: Customised by BM following version 1.00

// -----------------------------------------------------------------------------------------------
#define BANNER_CAT "Catuai V1.10" // version

// The user.h file contains user-definable compiler options
// It must be located in the same folder as aCatuai.pde
#include "user.h"

// this library included with the arduino distribution
#include <Wire.h>

// these "contributed" libraries must be installed in your sketchbook's arduino/libraries folder
#include <thermocouple.h>
#include <cADC.h>
#include <PWM16.h>
#include <cLCD.h>
#include <mcEEPROM.h>

#ifdef LCDAPTER  // implement buttons only if the LCDAPTER option is selected in user.h
#include <cButton.h>
#endif

#ifdef ANALOG_IN
// #define TIME_BASE pwmN1Hz // cycle time for PWM output to SSR on Ot1 (if used)
#define TIME_BASE pwmN10Hz // cycle time for PWM output to SSR on Ot1 (if used) // was 10Hz
// #define PWM_MODE IO3_FASTPWM // Fast PWM mode
#define PWM_MODE IO3_PCORPWM // Phase Correct PWM mode
//#define PWM_PRESCALE IO3_PRESCALE_1024 // 61 Hz PWM on FASTPWM, 30.6 Hz on PCORPWM
#define PWM_PRESCALE IO3_PRESCALE_8 // 7.8 kHz PWM on FASTPWM, 3.9 kHz on PCORPWM
// #define PWM_PRESCALE IO3_PRESCALE_32 // 1.9 kHz PWM on FASTPWM, 980 Hz on PCORPWM - try with PCOR for Ulka
// 61Hz and 30.6 Hz are extremely bad for fan noise
// 3.9 kHz is OK for fan noise, too fast for Ulka
// 980 Hz is noisy for fan, lots of harmonics, not very good for Ulka

#endif

// ------------------------ other compile directives
#define MIN_DELAY 300   // ms between ADC samples (tested OK at 270) // normally 300
#define NCHAN 2   // number of TC input channels // normally 2
#define DP 3  // decimal places for output on serial port // BM
#define D_MULT 0.001 // multiplier to convert temperatures from int to float
#define RESET "RESET" // text string command for resetting the timer
#define MAX_COMMAND 80 // max length of a command string
#define LOOPTIME 1000 // cycle time, in ms // normally 1000

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
uint8_t anlg1 = 0; // analog input pins
uint8_t anlg2 = 1;
int32_t power1 = 0; // power for 1st output (heater)
int32_t power2 = 0; // power for 2nd output (fan)
PWM16 output1; // 16-bit timer for SSR output on Ot1 and Ot2
PWM_IO3 io3; // 8-bit timer for fan control on IO3
#endif

// LCD output strings
char smin[3],ssec[3],st1[6],st2[6],sRoR1[7];

// ---------------------------------- LCD interface definition
#ifdef LCDAPTER
  #define BACKLIGHT lcd.backlight();
  cLCD lcd; // I2C LCD interface
  cButtonPE16 buttons; // class object to manage button presses
#else // parallel interface, standard LiquidCrystal
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
boolean first;
uint32_t nextLoop;
float reftime; // reference for measuring elapsed time
//boolean standAlone = true; // default is standalone mode
boolean standAlone = false; // default is standalone mode // changed BM

char command[MAX_COMMAND+1]; // input buffer for commands from the serial port

// declaration needed to maintain compatibility with Eclipse/WinAVR/gcc
void updateLCD( float t1, float t2, float RoR );

// T1, T2 = temperatures x 1000
// t1, t2 = time marks, milliseconds
// ---------------------------------------------------
float calcRise( int32_t T1, int32_t T2, int32_t t1, int32_t t2 ) {
  int32_t dt = t2 - t1;
  if( dt == 0 ) return 0.0;  // fixme -- throw an exception here?
  float dT = (T2 - T1) * D_MULT;
  float dS = dt * 0.001; // convert from milli-seconds to seconds
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
#ifdef CELSIUS
  t_amb = amb.getAmbC();
#else
  t_amb = amb.getAmbF();
#endif
  Serial.print( t_amb, DP );

  // print temperature, rate for each channel
  i = 0;
  if( NCHAN >= 1 ) {
    Serial.print(", ");
    Serial.print( t1 = D_MULT*temps[i], DP );
    Serial.print(", ");
    RoR = calcRise( flast[i], ftemps[i], lasttimes[i], ftimes[i] );
    RoR = fRoR[i].doFilter( RoR /  D_MULT ) * D_MULT; // perform post-filtering on RoR values
    Serial.print( RoR , DP );
    i++;
    if( NCHAN == 1 ) {   // dummy values for T2 and RoR2 to avoid confusing pBourbon
      Serial.print(", ");
      Serial.print( 0.0, 1 );
      Serial.print(", ");
      Serial.print( 0.0 , 1 );
    };
  };
  
  if( NCHAN >= 2 ) {
    Serial.print(", ");
    Serial.print( t2 = D_MULT * temps[i], DP );
    Serial.print(", ");
    rx = calcRise( flast[i], ftemps[i], lasttimes[i], ftimes[i] );
    rx = fRoR[i].doFilter( rx / D_MULT ) * D_MULT; // perform post-filtering on RoR values
    Serial.print( rx , DP );
    i++;
  };
  
  if( NCHAN >= 3 ) {
    Serial.print(", ");
    Serial.print( D_MULT * temps[i], DP );
    Serial.print(", ");
    rx = calcRise( flast[i], ftemps[i], lasttimes[i], ftimes[i] );
    rx = fRoR[i].doFilter( rx / D_MULT ) * D_MULT; // perform post-filtering on RoR values
    Serial.print( rx , DP );
    i++;
  };
  
  if( NCHAN >= 4 ) {
    Serial.print(", ");
    Serial.print( D_MULT * temps[i], DP );
    Serial.print(", ");
    rx = calcRise( flast[i], ftemps[i], lasttimes[i], ftimes[i] );
    rx = fRoR[i].doFilter( rx / D_MULT ) * D_MULT; // perform post-filtering on RoR values
    Serial.print( rx , DP );
    i++;
  };

// log the power level to the serial port
#ifdef ANALOG_IN
  Serial.print(",");
  Serial.print( power1 );
  Serial.print( "," );
  Serial.print( power2 );
#endif
  Serial.println();

  updateLCD( t1, t2, RoR );  
};

// --------------------------------------------
void updateLCD( float t1, float t2, float RoR ) { // displays time, temp, RoR only here
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
//  int it02 = round( t2 ); //BM
//  if( it02 > 999 ) it02 = 999; //BM
//  else if( it02 < -999 ) it02 = -999; //BM
//  sprintf( st2, "%3d", it02 ); //BM
//  lcd.setCursor( 11, 0 ); //BM
//  lcd.print( "E " ); //BM
  lcd.setCursor( 13, 0 ); //BM
  lcd.print( "E:" ); //BM
//  lcd.print( st2 ); //BM
  if (t2<100.0) lcd.print(" "); //BM
  lcd.print(t2,1); //BM

// Alternative form for last 2 lines:
//  if (t2<100.0) lcd.print(" "); //BM
//  lcd.print((int)t2); //BM
//  lcd.print("."); //BM
//  int it2 = (t2 - (int)t2) * 10; //BM
//  lcd.print( abs(it2) ); //BM

  // channel 1 RoR
  int iRoR = round( RoR );
  if( iRoR > 99 ) 
    iRoR = 99;
  else
   if( iRoR < -99 ) iRoR = -99; 
  sprintf( sRoR1, "%0+3d", iRoR );
  lcd.setCursor(0,1);
//  lcd.print( "RT"); //BM
  lcd.print( "RoR"); //BM
  lcd.print( sRoR1 );

  // channel 1 temperature
/*  int it01 = round( t1 );
  if( it01 > 999 ) 
    it01 = 999;
  else
    if( it01 < -999 ) it01 = -999;
  sprintf( st1, "%3d", it01 );
  lcd.setCursor( 11, 1 );
  lcd.print("B "); */ //BM
  lcd.setCursor( 13, 1 ); //BM
  lcd.print("B:"); //BM
//  lcd.print(st1); //BM
  if (t1<100.0) lcd.print(" "); //BM
  lcd.print(t1,1); //BM
}

#ifdef ANALOG_IN
// -------------------------------- reads analog value and maps it to 0 to 100
// -------------------------------- rounded to the nearest 5
int32_t getAnalogValue( uint8_t port ) {
  int32_t mod, trial, aval;
  aval = analogRead( port );
  trial = aval * 100;
  trial /= 1023;
  mod = trial % 5;
  trial = ( trial / 5 ) * 5; // truncate to multiple of 5
  if( mod >= 3 )
    trial += 5;
  return trial;
}

// ---------------------------------
void readAnlg1() { // read analog port 1 and adjust Ot1 output
  char pstr[5];
  int32_t reading;
  reading = getAnalogValue( anlg1 );
  if( reading <= 100 && reading != power1 ) { // did it change?
    power1 = reading;
    sprintf( pstr, "%3d", (int)power1 );
//    lcd.setCursor( 6, 0 ); //BM
//    lcd.print( pstr ); lcd.print("%"); //BM
    lcd.setCursor( 7, 0 ); //BM
    lcd.print("H"); lcd.print( pstr ); lcd.print("%"); //BM
  }
}

// ---------------------------------
void readAnlg2() { // read analog port 2 and adjust IO3 output
  char pstr[5];
  int32_t reading;
  reading = getAnalogValue( anlg2 );
  if( reading <= 100 && reading != power2 ) { // did it change?
    power2 = reading;
    float pow = 2.55 * power2;  // output values are 0 to 255
    io3.Out( round( pow ) );
    sprintf( pstr, "%3d", (int)power2 );
//    lcd.setCursor( 6, 1 ); //BM
//    lcd.print( pstr ); lcd.print("%"); //BM
    lcd.setCursor( 7, 1 ); //BM
    lcd.print("F"); lcd.print( pstr ); lcd.print("%"); //BM
  }
}
#endif

#ifdef LCDAPTER
// ----------------------------------
void checkButtons() { // take action if a button is pressed
  if( buttons.readButtons() ) {
    if( buttons.keyPressed( 3 ) && buttons.keyChanged( 3 ) ) {// left button = start the roast
      if( standAlone ) { // reset the timer
        buttons.ledOn ( 2 ); // turn on leftmost LED when start button is pushed
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
        buttons.ledOn ( 1 ); // turn on middle LED at first crack
      }
      else {

        Serial.print( "# FC,");
        Serial.println( timestamp, DP );
        buttons.ledOn ( 1 ); // turn on middle LED at first crack
      }
    }
    else if( buttons.keyPressed( 1 ) && buttons.keyChanged( 1 ) ) { // 3rd button marks second crack
      if( standAlone ) {
        buttons.ledOn ( 0 ); // turn on rightmost LED at second crack
      }
      else {

        Serial.print( "# SC,");
        Serial.println( timestamp, DP );
        buttons.ledOn ( 0 ); // turn on rightmost LED at second crack
      }
    }
    else if( buttons.keyPressed( 0 ) && buttons.keyChanged( 0 ) ) { // 4th button marks eject
      if( standAlone ) {
        buttons.ledAllOff(); // turn off all LED's when beans are ejected
      }
      else {

        Serial.print( "# EJCT,");
        Serial.println( timestamp, DP );
        buttons.ledAllOff(); // turn off all LED's when beans are ejected
//      Do not reset the timer here; if timer is reset here, the graph will fly back to 0 on eject!!
      }
    }
  }
}
#endif // LCDAPTER

// -------------------------------------
void append( char* str, char c ) { // reinventing the wheel
  int len = strlen( str );
  str[len] = c;
  str[len+1] = '\0';
}

// ----------------------------
void resetTimer() {
  Serial.print( "# Reset, " ); Serial.println( timestamp ); // write message to log
  nextLoop = 10 + millis(); // wait 10 ms and force a sample/log cycle
  reftime = 0.001 * nextLoop; // reset the reference point for timestamp
  return;
}

// -------------------------------------
void processCommand() {  // a newline character has been received, so process the command
  if( ! strcmp( command, RESET ) ) { // RESET command received, so reset the timer
    resetTimer();
    standAlone = false;
  }
  return;
}

// -------------------------------------
void checkSerial() {  // buffer the input from the serial port
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
void checkStatus( uint32_t ms ) { // this is an active delay loop
  uint32_t tod = millis();
  while( millis() < tod + ms ) {
#ifdef ANALOG_IN
    readAnlg1();
    readAnlg2();
#endif
#ifdef LCDAPTER
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
#ifdef CELSIUS
    v = round( tempC / D_MULT ); // store results as integers
#else
    v = round( C_TO_F( tempC ) / D_MULT ); // store results as integers
#endif
    temps[j] = fT[j].doFilter( v ); // apply digital filtering for display/logging
    ftemps[j] =fRise[j].doFilter( v ); // heavier filtering for RoR
  }
};
  
// ------------------------------------------------------------------------
// MAIN
//
void setup()
{
  delay(100);
  Wire.begin(); 
//  lcd.begin(16, 2);
  lcd.begin(20, 4); //BM
  BACKLIGHT;
  lcd.setCursor( 0, 3 );
  lcd.print( BANNER_CAT ); // display version banner
#ifdef CELSIUS  // display a C or F after the version to indicate temperature scale
  lcd.print( " " ); lcd.print( char(0xDF) ); lcd.print( "C" ); //BM
#else
  lcd.print( " " ); lcd.print( char(0xDF) ); lcd.print( "F" ); //BM
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
  Serial.print(",[power1],[power2]");
  Serial.println();
 
  fT[0].init( BT_FILTER ); // digital filtering on BT
  fT[1].init( ET_FILTER ); // digital filtering on ET
  fRise[0].init( RISE_FILTER ); // digital filtering for RoR calculation
  fRise[1].init( RISE_FILTER ); // digital filtering for RoR calculation
  fRoR[0].init( ROR_FILTER ); // post-filtering on RoR values
  fRoR[1].init( ROR_FILTER ); // post-filtering on RoR values

#ifdef ANALOG_IN
  output1.Setup( TIME_BASE );
  io3.Setup( PWM_MODE, PWM_PRESCALE );
  power1 = power2 = -50;  // initialize to force display of initial power setting
#endif
  
  delay( 1800 );
  nextLoop = 2000;
  reftime = 0.001 * nextLoop; // initialize reftime to the time of first sample
  first = true;
  lcd.clear();
  lcd.setCursor( 0, 3 ); //BM
  lcd.print( BANNER_CAT ); // display version banner //BM
//  lcd.print( " Celsius" ); //BM
  lcd.print( " " ); lcd.print( char(0xDF) ); lcd.print( "C" ); //BM
}
// ---------------------------------- End of Setup loop

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
 #ifdef ANALOG_IN
    output1.Out( power1, 0 ); // update the power output on the SSR drive Ot1
 #endif
  }

  for( int j = 0; j < NCHAN; j++ ) {
   flast[j] = ftemps[j]; // use previous values for calculating RoR
   lasttimes[j] = ftimes[j];
  }

  idletime = LOOPTIME - ( millis() - thisLoop );
  // arbitrary: complain if we don't have at least 50mS left
  if (idletime < 20 ) { // BM - original was 50, later used 100; this is saved in the excel data also!
    Serial.print("# idle: ");
    Serial.println(idletime);
  }

  nextLoop += LOOPTIME; // time mark for start of next update 
}

