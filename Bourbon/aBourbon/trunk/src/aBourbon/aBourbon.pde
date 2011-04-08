// aBourbon.pde
//
// N-channel Rise-o-Meter
// output on serial port:  timestamp, ambient, T1, RoR1, T2, RoR2, 0.0 (placeholder)
// output on LCD : timestamp, channel 2 temperature
//                 RoR 1,     channel 1 temperature

// Support for pBourbon.pde and 16 x 2 LCD

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

#define BANNER_BRBN "Bourbon V2.00"
// Revision history:
//   20100922: Added support for I2C LCD interface (optional). 
//             This program now requires use of cLCD library.
//   20100927: converted aBourbon to be a roast monitor only
//   20100928: added EEPROM support (optional)
//   20110403: moved user configurable compile flags to user.h
//   20110404: Added support for Celsius operation
//   20110405: Added support for button pushes
//   20110406: Added post-filtering for RoR values
//   20110408: Added code to read codes from serial port

// This code was adapted from the a_logger.pde file provided
// by Bill Welch.

// The user.h file contains user-definable compiler options
// It must be located in the same folder as aBourbon.pde
#include "user.h"

// this library included with the arduino distribution
#include <Wire.h>

// these "contributed" libraries must be installed in your sketchbook's arduino/libraries folder
#include <TypeK.h>
#include <cADC.h>
#include <cLCD.h>

#ifdef LCDAPTER  // implement buttons only if the LCDAPTER option is selected in user.h
#include <cButton.h>
#endif

// ------------------------ other compile directives
#define MIN_DELAY 300   // ms between ADC samples (tested OK at 270)
#define NCHAN 2   // number of TC input channels
#define TC_TYPE TypeK  // thermocouple type / library
#define DP 1  // decimal places for output on serial port
#define D_MULT 0.001 // multiplier to convert temperatures from int to float
#define RESET "RESET" // text string command for resetting the timer
#define MAX_COMMAND 80 // max length of a command string
#define LOOPTIME 1000 // cycle time, in ms

// --------------------------------------------------------------
// global variables

#ifdef EEPROM_BRBN // optional code if EEPROM flag is active
#include <mcEEPROM.h>
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
#endif

// class objects
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

// LCD output strings
char smin[3],ssec[3],st1[6],st2[6],sRoR1[7];

// ---------------------------------- LCD interface definition
#ifdef LCDAPTER
  #define BACKLIGHT lcd.backlight();
  cLCD lcd; // I2C LCD interface
  cButtonPE16 buttons; // class object to manage button presses
#else // equivalent to standard LiquidCrystal interface
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

char command[MAX_COMMAND+1]; // input from the serial port


// declarations needed to maintain compatibility with Eclipse/WinAVR/gcc
void updateLCD( float t1, float t2, float RoR );

// ---------------------------------------------------
// T1, T2 = temperatures x 1000
// t1, t2 = time marks, milliseconds
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
  Serial.print( timestamp - reftime, DP );

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
    Serial.print(",");
    rx = calcRise( flast[i], ftemps[i], lasttimes[i], ftimes[i] );
    rx = fRoR[i].doFilter( rx / D_MULT ) * D_MULT; // perform post-filtering on RoR values
    Serial.print( rx , DP );
    i++;
  };
  
  if( NCHAN >= 4 ) {
    Serial.print(",");
    Serial.print( D_MULT * temps[i], DP );
    Serial.print(",");
    rx = calcRise( flast[i], ftemps[i], lasttimes[i], ftimes[i] );
    rx = fRoR[i].doFilter( rx / D_MULT ) * D_MULT; // perform post-filtering on RoR values
    Serial.print( rx , DP );
    i++;
  };

// log the placeholder to serial port
  Serial.println(",0");
  
  updateLCD( t1, t2, RoR );  
};

// --------------------------------------------
void updateLCD( float t1, float t2, float RoR ) {
  // form the timer output string in min:sec format
  int itod = round( timestamp - reftime );
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
  lcd.print( "RoR1:");
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

#ifdef LCDAPTER
// ----------------------------------
void checkButtons() { // take action if a button is pressed
  if( buttons.readButtons() ) {
    if( buttons.keyPressed( 3 ) && buttons.keyChanged( 3 ) ) {// left button = start the roast
      Serial.print( "# STRT,");
      Serial.println( timestamp - reftime, DP );
      buttons.ledOn ( 2 ); // turn on leftmost LED when start button is pushed
    }
    else if( buttons.keyPressed( 2 ) && buttons.keyChanged( 2 ) ) { // 2nd button marks first crack
      Serial.print( "# FC,");
      Serial.println( timestamp, DP );
      buttons.ledOn ( 1 ); // turn on middle LED at first crack
    }
    else if( buttons.keyPressed( 1 ) && buttons.keyChanged( 1 ) ) { // 3rd button marks second crack
      Serial.print( "# SC,");
      Serial.println( timestamp, DP );
      buttons.ledOn ( 0 ); // turn on rightmost LED at second crack
    }
    else if( buttons.keyPressed( 0 ) && buttons.keyChanged( 0 ) ) { // 4th button marks eject
      Serial.print( "# EJCT,");
      Serial.println( timestamp, DP );
      buttons.ledAllOff(); // turn off all LED's when beans are ejected
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

// -------------------------------------
void processCommand() {  // a null character has been received, so process the command
  if( ! strcmp( command, RESET ) ) { // RESET command received, so reset the timer
    nextLoop = 100 + millis(); // wait 100 ms and force a sample/log cycle
    reftime = 0.001 * nextLoop; // reset the reference point for elapsed time
    return;
  }
}

// -------------------------------------
void checkSerial() {  // buffer the input from the serial port
  char c;
  while( Serial.available() > 0 ) {
    c = Serial.read();
    if( ( c == '\n' ) || ( strlen( command ) == MAX_COMMAND ) ) {
      processCommand();
      strcpy( command, "" );
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
#ifdef LCDAPTER
    checkButtons();
#endif
    checkSerial(); // Has a command been received?
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
  lcd.begin(16, 2);
  BACKLIGHT;
  lcd.setCursor( 0, 0 );
  lcd.print( BANNER_BRBN ); // display version banner

#ifdef LCDAPTER
  buttons.begin( 4 );
  buttons.readButtons();
  buttons.ledAllOff();
#endif

#ifdef CELSIUS  // display a C or F after the version to indicate temperature scale
  lcd.print( "C" );
#else
  lcd.print( "F" );
#endif
  
  Serial.begin(BAUD);
  amb.init( AMB_FILTER );  // initialize ambient temp filtering

#ifdef EEPROM_BRBN
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
    adc.setCal( CAL_GAIN, UV_OFFSET );
    amb.setOffset( AMB_OFFSET );
  }   
#else
  adc.setCal( CAL_GAIN, UV_OFFSET );
  amb.setOffset( AMB_OFFSET );
#endif

  // write header to serial port
  Serial.print("# time,ambient,T0,rate0");
  if( NCHAN >= 2 ) Serial.print(",T1,rate1");
  if( NCHAN >= 3 ) Serial.print(",T2,rate2");
  if( NCHAN >= 4 ) Serial.print(",T3,rate3");
  Serial.print(",0");
  Serial.println();
  
  fT[0].init( BT_FILTER ); // digital filtering on BT
  fT[1].init( ET_FILTER ); // digital filtering on ET
  fRise[0].init( RISE_FILTER ); // digital filtering for RoR calculation
  fRise[1].init( RISE_FILTER ); // digital filtering for RoR calculation
  fRoR[0].init( ROR_FILTER ); // post-filtering on RoR values
  fRoR[1].init( ROR_FILTER ); // post-filtering on RoR values

  delay( 1800 );
  nextLoop = 2000;
  first = true;
  lcd.clear();
}

// -----------------------------------------------------------------
void loop()
{
  float idletime;
  uint32_t thisLoop;

  // delay loop to force update on even LOOPTIME boundaries
  while ( millis() < nextLoop ) { // delay until time for next loop
    if( !first ) { // do not want to check the buttons on the first time through
#ifdef LCDAPTER
      checkButtons();
#endif
      checkSerial(); // Has a command been received?
    } // if not first
  }
  
  thisLoop = millis(); // actual time marker for this loop
  timestamp = float( thisLoop ) * 0.001; // system time, seconds, for this set of samples
  get_samples(); // retrieve values from MCP9800 and MCP3424
  if( first ) // use first samples for RoR base values only
    first = false;
  else {
    logger(); // output results to serial port
  }

  for( int j = 0; j < NCHAN; j++ ) {
   flast[j] = ftemps[j]; // use previous values for calculating RoR
   lasttimes[j] = ftimes[j];
  }

  idletime = LOOPTIME - ( millis() - thisLoop );
  // arbitrary: complain if we don't have at least 10mS left
  if (idletime < 10 ) {
    Serial.print("# idle: ");
    Serial.println(idletime);
  }

  nextLoop += LOOPTIME; // time mark for start of next update 
}

