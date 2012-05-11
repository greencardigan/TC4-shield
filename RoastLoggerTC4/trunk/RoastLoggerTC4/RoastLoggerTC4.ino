
/********************************************************************************************
 *  RoastLoggerTC4.ino  by GreenBean and Jim Gallt (see revision histroy below)
 *  
 *  TC4 Arduino sketch for use with Roast Logger by GreenBean http://www.toomuchcoffee.com/
 *  For information on the RoastLogger see:
 * 
 *        http://homepage.ntlworld.com/green_bean/coffee/roastlogger/roastlogger.htm
 *
 *  This version modified to compile/verify on Arduino IDE version 1.0.
 *  Compiles on Arduino Duemilanove 328 and Uno boards.
 *
 *  Based on aBourbon.pde:
 *  Bourbon-REL-300  downloaded from http://code.google.com/p/tc4-shield/downloads/list
 *  Quote
 *  aBourbon, as a standalone application, displays elapsed roast time, ET, BT, and BT-RoR on 
 *  LCD.  When connected to LCDapter board, buttons provide ability to identify 4 roast 
 *  markers (start, first crack, second crack, eject).
 *  Unquote
 *
 *  Modified to be compatible with the Roast Logger and renamed RoastLoggerTC4.pde
 *  Changed baud rate in user.h to 115200
 *  Default output is Celsius - add jumper on ANLG2 to output in Fahrenheit.
 *  Added communication for heater power control for OT1 
 *  Changed serial output to report T1, T2, rorT1, rorT2 and power level.
 *  ROR is not currently used by RoastLogger but may be added in future.
 *  
 *
 ********************************************************************************************/
/********************************************************************************************

 Please note that you must install the included libraries (in the libraries folder) before 
  the sketch will verify/compile.

  See the "Contributed Libraries" section of http://www.arduino.cc/en/Reference/Libraries
  for details of how to install them.

 ********************************************************************************************/

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

#define BANNER_BRBN "RoastLoggerTC4 ver 0.7"
// Revision history: - of RoastLoggerTC4
//  20120112:  Version 0.3 - Released for testing
//  20120127:  Version 0.4 - Modified to compile under Arduino IDE 1.0
//  20120312:  Version 0.5 - Modified by Jim Gallt to use standard PWM outputs on OT1 and IO3
//                           Added fan output command capability
//  20120403:  Version 0.6 - Minor modification to logger method to change order of output and clean up RoR output
//  20120425:  Version 0.7 - Select F units using jumper on ANLG2 port (IN -- GND)
//  20120511:  Version 0.8 - Turn fan, heater off by default in setup; use 4 sec timebase for heater PWM

// Revision history: - of aBourbon.pde
//   20100922: Added support for I2C LCD interface (optional). 
//             This program now requires use of cLCD library.
//   20100927: converted aBourbon to be a roast monitor only
//   20100928: added EEPROM support (optional)
//   20110403: moved user configurable compile flags to user.h
//   20110404: Added support for Celsius operation
//   20110405: Added support for button pushes
//   20110406: Added post-filtering for RoR values
//   20110408: Added code to read RESET code from serial port
//   20110522: Eliminated the dummy power field in the output stream.  pBourbon now is smart
//             enough to not require the dummy field.
//   20110903: Improved error checking when reading cal block from EEPROM
//             Added support for typeJ, typeT thermocouples

// This code was adapted from the a_logger.pde file provided
// by Bill Welch.

// The user.h file contains user-definable compiler options
#include "user.h"

// this library included with the arduino distribution
#include <Wire.h>

// these "contributed" libraries must be installed in your sketchbook's arduino/libraries folder
#include <thermocouple.h>
#include <cADC.h>
#include <PWM16.h>
#include <mcEEPROM.h>

// ------------------------ other compile directives
#define MIN_DELAY 300   // ms between ADC samples (tested OK at 270)
#define NCHAN 2   // number of TC input channels
#define DP 1  // decimal places for output on serial port
#define D_MULT 0.001 // multiplier to convert temperatures from int to float
#define MAX_COMMAND 80 // max length of a command string
#define LOOPTIME 1000 // cycle time, in ms

#define ANLG2 A1 // arduino pin A1
#define UNIT_SEL ANLG2 // select temperature scale

#define CMD_POWER "POWER"
#define CMD_FAN "FAN"
#define CMD_PCCONTROL "PCCONTROL"
#define CMD_ARDUINOCONTROL "ARDUINOCONTROL"

// --------------------------------------------------------------
// global variables

mcEEPROM eeprom;
calBlock caldata;

// class objects
cADC adc( A_ADC ); // MCP3424
ambSensor amb( A_AMB ); // MCP9800
filterRC fT[NCHAN]; // filter for displayed/logged ET, BT
filterRC fRise[NCHAN]; // heavily filtered for calculating RoR
filterRC fRoR[NCHAN]; // post-filtering on RoR values

tcBase* tc[NCHAN]; // array of pointers to thermocouples

TC_TYPE1 tc1; // input 1
TC_TYPE2 tc2; // input 2

// arrays to store temperatures, times for each channel
int32_t temps[NCHAN]; //  stored temperatures are divided by D_MULT
int32_t ftemps[NCHAN]; // heavily filtered temps
int32_t ftimes[NCHAN]; // filtered sample timestamps
int32_t flast[NCHAN]; // for calculating derivative
int32_t lasttimes[NCHAN]; // for calculating derivative

//RoastLogger global variables for heater, fan power %
int8_t heater = 100; // power for 1st output (heater); default 100%
int8_t fan = 0; // power for 2nd output (fan); default 0%
PWM16 output1; // 16-bit timer for SSR output on Ot1 and Ot2
PWM_IO3 io3; // 8-bit timer for fan control on IO3

// used in main loop
float timestamp = 0;
boolean first;
uint32_t lastLoop;
float reftime; // reference for measuring elapsed time

// temperature units selection
boolean celsius = true;

char command[MAX_COMMAND+1]; // input buffer for commands from the serial port

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

  String rorT1,rorT2;

  t1 = D_MULT * temps[0];
  t2 = D_MULT * temps[1];  

  // print temperature, rate for each channel
  i = 0;
  if( NCHAN >= 1 ) {
    Serial.print("rorT1=");
    RoR = calcRise( flast[i], ftemps[i], lasttimes[i], ftimes[i] );
    RoR = fRoR[i].doFilter( RoR /  D_MULT ) * D_MULT; // perform post-filtering on RoR values
    Serial.println( RoR , DP );
    Serial.print("T1=");
    Serial.println( t1, DP );
    i++;
  };

  if( NCHAN >= 2 ) {
    Serial.print("rorT2=");
    rx = calcRise( flast[i], ftemps[i], lasttimes[i], ftimes[i] );
    rx = fRoR[i].doFilter( rx / D_MULT ) * D_MULT; // perform post-filtering on RoR values
    Serial.println( rx , DP );
    Serial.print("T2=");
    Serial.println( t2, DP );
    i++;
  };

  //print heater power and fan output level 
  Serial.print("Power%=");
  Serial.println(heater);
  Serial.print("Fan=");
  Serial.println(fan);

};

// -------------------------------------
void append( char* str, char c ) { // reinventing the wheel
  int len = strlen( str );
  str[len] = toupper(c);
  str[len+1] = '\0';
}

// -------------------------------------
void processCommand() {  // a newline character has been received, so process the command
  char *val, *c;
  String key = strtok_r(command, "=", &c);
  if (key != NULL && key.equals(CMD_POWER)) {
    val = strtok_r(NULL, "=", &c);
    if (val != NULL) {
      heater = atoi(val);      
      if (heater >= 0 && heater <101) {  
        output1.Out( heater, 0 ); // update the power output on the SSR drive Ot1
      }
    }
  }
  else if (key != NULL && key.equals(CMD_FAN)) {
    val = strtok_r(NULL, "=", &c);
    if (val != NULL) {
      fan = atoi(val);      
      if (fan >= 0 && fan <101) {  
        float pow = 2.55 * fan;  // output values are 0 to 255
        io3.Out( round( pow ) );   
      }
    }
  }
  else if (key != NULL && key.equals(CMD_PCCONTROL)) { // placeholder
  }
  else if (key != NULL && key.equals(CMD_ARDUINOCONTROL)) { // placeholder
  }
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

// --------------------------------------------------------------------------
void get_samples() // this function talks to the amb sensor and ADC via I2C
{
  int32_t v;
  float tempC;

  for( int j = 0; j < NCHAN; j++ ) { // one-shot conversions on both chips
    adc.nextConversion( j ); // start ADC conversion on channel j
    amb.nextConversion(); // start ambient sensor conversion
    delay( MIN_DELAY ); // give the chips time to perform the conversions
    ftimes[j] = millis(); // record timestamp for RoR calculations
    amb.readSensor(); // retrieve value from ambient temp register
    v = adc.readuV(); // retrieve microvolt sample from MCP3424
    tempC = tc[j]->Temp_C( 0.001 * v, amb.getAmbC() ); // convert to Celsius
    if( celsius )
      v = round( tempC / D_MULT ); // store results as integers
    else
      v = round( C_TO_F( tempC ) / D_MULT ); // store results as integers
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
  lastLoop = millis();
  Wire.begin(); 
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
    adc.setCal( caldata.cal_gain, caldata.cal_offset );
    amb.setOffset( caldata.K_offset );
  }
  else { // if there was a problem with EEPROM read, then use default values
    Serial.println("# Failed to read EEPROM.  Using default calibration data. ");
    adc.setCal( CAL_GAIN, UV_OFFSET );
    amb.setOffset( AMB_OFFSET );
  }   

  fT[0].init( BT_FILTER ); // digital filtering on BT
  fT[1].init( ET_FILTER ); // digital filtering on ET
  fRise[0].init( RISE_FILTER ); // digital filtering for RoR calculation
  fRise[1].init( RISE_FILTER ); // digital filtering for RoR calculation
  fRoR[0].init( ROR_FILTER ); // post-filtering on RoR values
  fRoR[1].init( ROR_FILTER ); // post-filtering on RoR values

  tc[0] = &tc1; // allow different thermocouple types on outputs
  tc[1] = &tc2;
  
  output1.Setup( TIME_BASE );
  output1.Out( 0, 0 ); // heater is off by default
  
  io3.Setup( PWM_MODE, PWM_PRESCALE );
  io3.Out( 0 ); // fan is off by default
  
  // set up ANLG2 input pin for temperature units selection
  pinMode( UNIT_SEL, INPUT );
  digitalWrite( UNIT_SEL, HIGH ); // enable pullup

  first = true;
}

// -----------------------------------------------------------------
void loop() {
  float idletime;
  uint32_t thisLoop;

  checkSerial();
  thisLoop = millis();

  if( thisLoop - lastLoop >= LOOPTIME ) { // time to take another sample
    celsius = digitalRead( UNIT_SEL ) == HIGH;  // use jumper to drive low and select fahrenheit
    if( first )
      reftime = 0.001 * thisLoop;
    lastLoop += LOOPTIME;
    timestamp = 0.001 * float( thisLoop ) - reftime; // system time, seconds, for this set of samples
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
    // arbitrary: complain if we don't have at least 50mS left
    if (idletime < 50 ) {
      Serial.print("# idle: ");
      Serial.println(idletime);
    }
  }
}

