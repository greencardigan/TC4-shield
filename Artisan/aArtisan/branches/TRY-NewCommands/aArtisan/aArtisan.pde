// aArtisan.pde
// ------------

// Written to support the Artisan roasting scope //http://code.google.com/p/artisan/

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
//   Neither the name of the copyright holder(s) nor the names of its contributors may be 
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

#define BANNER_ARTISAN "aARTISAN V1.05prelease"

// Revision history:
// 20110408 Created.
// 20110409 Reversed the BT and ET values in the output stream.
//          Shortened the banner display time to avoid timing issues with Artisan
//          Echo all commands to the LCD
// 20110413 Added support for Artisan 0.4.1
// 20110414 Reduced filtering levels on BT, ET
//          Improved robustness of checkSerial() for stops/starts by Artisan
//          Revised command format to include newline character for Artisan 0.4.x
// 20110528 New command language added (major revision)
//          Use READ command to poll the device for up to 4 temperature channels
//          Change temperature scale using UNITS command
//          Map physical channels on ADC to logical channels using the CHAN command
//          Select SSR output duty cycle with OT1 and OT2 commands
//          Select PWM logic level output on I/O3 using IO3 command
//          Directly control digital pins using DPIN command (WARNING -- this might not be smart)
//          Directly control analog pins using APIN command (WARNING -- this might not be smart)

// this library included with the arduino distribution
#include <Wire.h>

// The user.h file contains user-definable compiler options
// It must be located in the same folder as aArtisan.pde
#include "user.h"

// these "contributed" libraries must be installed in your sketchbook's arduino/libraries folder
#include <TypeK.h>
#include <cADC.h> // MCP3424
#include <PWM16.h> // for SSR output
#ifdef LCD
#include <cLCD.h> // required only if LCD is used
#endif

// ------------------------ other compile directives
#define MIN_DELAY 300   // ms between ADC samples (tested OK at 270)
#define NC 4   // max physical number of TC input channels (activate using CHAN command)
#define TC_TYPE TypeK  // thermocouple type / library
#define DP 1  // decimal places for output on serial port
#define D_MULT 0.001 // multiplier to convert temperatures from int to float

#define MAX_COMMAND 80 // max length of a command string
#define MAX_TOKEN_LEN 8 // max length of an individual token
#define MAX_TOKENS 4 // max is 4 tokens in one command
#define DLMTR "; ,"  // delimiters in new command language

#define IO3 3 // use DIO3 for PWM output

#ifdef EEPROM_ARTISAN // optional code if EEPROM flag is active
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

float AT; // ambient temp
float T[NC];  // final output values referenced to physical channels 0-3
uint8_t actv[NC];  // identifies channel status, 0 = inactive, n = physical channel + 1
#ifdef CELSIUS // only affects startup conditions
boolean Cscale = true;
#else
boolean Cscale = false;
#endif

char command[MAX_COMMAND+1]; // input buffer for commands from the serial port
char tokens[MAX_TOKENS+1][MAX_TOKEN_LEN+1];  // tokens from command line

int levelOT1, levelOT2, levelIO3;  // parameters to control output levels

// class objects
cADC adc( A_ADC ); // MCP3424
ambSensor amb( A_AMB ); // MCP9800
filterRC fT[NC]; // filter for logged ET, BT
PWM16 ssr;  // object for SSR output on OT1, OT2

// ---------------------------------- LCD interface definition
#ifdef LCD
// LCD output strings
char st1[6],st2[6];
#ifdef LCDAPTER
  #define BACKLIGHT lcd.backlight();
  cLCD lcd; // I2C LCD interface
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
#endif
// --------------------------------------------- end LCD interface

// -------------------------- parse string and create tokens
int tokenize( char dest[][MAX_TOKEN_LEN+1], char src[] ) {
  char* pch;
  int n = 0;
  pch = strtok( src, DLMTR );
  while( pch != NULL && n <= MAX_TOKENS ) {
   strncpy( dest[n], pch, MAX_TOKEN_LEN );
//   Serial.println( dest[n] );
   pch = strtok( NULL, DLMTR );
   ++n;
  }
//  Serial.println( n );
  return n; 
}

// -------------------------------------
void append( char* str, char c ) { // reinventing the wheel
  int len = strlen( str );
  str[len] = c;
  str[len+1] = '\0';
}

// -------------------------------------
void checkSerial() {  // buffer the input from the serial port
  char c;
  while( Serial.available() > 0 ) {
    c = Serial.read();
    // check for newline, buffer overflow
    if( ( c == '\n' ) || ( strlen( command ) == MAX_COMMAND ) ) { 
      processCommand();
      strcpy( command, "" ); // empty the buffer
    } // end if
    else {
      append( command, toupper( c ) );
    } // end else
  } // end while
}

// ------------------------------ analog output based on 0 to 100%
void analogOut( uint8_t prt, int level ) {
  float pow = 2.55 * levelIO3;
  analogWrite( prt, round( pow ) );
}

// -------------------------------------
void processCommand() {  // a newline character has been received, so process the command  
#ifdef LCD
    lcd.setCursor( 0, 1 ); // echo all commands to the LCD
    lcd.print( command );
#endif
  for( int i =0; i < MAX_TOKENS; i++ )
    tokens[i][0] = '\0';  // clear out old tokens
  int n = tokenize( tokens, command );
  if( n != 0 ) {
    // first check the legacy commands
    if( ! strcmp( tokens[0], "RF2000" ) ) { // command received, read and output a sample
      Cscale = false;
      logger();
      return;
    }
    if( ! strcmp( tokens[0], "RC2000" ) ) { // command received, read and output a sample
      Cscale = true;
      logger();
      return;
    }
    if( ! strcmp( tokens[0], "READ" ) ) { // legacy code to support Artisan 0.3.4
      logger();
      return;
    }
    // --------------- next, check the new command structure
    // UNITS;F\n or UNITS;C\n
    if( ! strcmp( tokens[0], "UNITS" )  ) {
      Serial.print("# Changed units to ");
      if( ! strcmp( tokens[1], "F" ) ) {
        Cscale = false;
        Serial.println("F");
        return;
      }
      if( ! strcmp( tokens[1], "C" ) ) {
        Cscale = true;
        Serial.println("C");
        return;
      }
    }
    
    // --------------------------- specify active channels, and order of output
    // CHAN;ijkl\n
    if( ! strcmp( tokens[0], "CHAN" ) ) {
      char str[2];
      uint8_t n;
      uint8_t len = strlen( tokens[1] );
      if( len > 0 && len <= NC ) {
        for( int i = 0; i < len && i <= NC; i++ ) {
          str[0] = '\0';
          append( str, tokens[1][i] );
          n = atoi( str );        
          if( n <= NC ) 
            actv[i] = n;
          else 
            actv[i] = 0;
        }
        Serial.print("# Active channels set to ");
        Serial.println( tokens[1] );
      }
      return;
    }

    // --------------------------- specify output level on OT1
    // OT1;ddd\n
    if( ! strcmp( tokens[0], "OT1" ) ) {
      uint8_t len = strlen( tokens[1] );
      if( len > 0 ) {
        levelOT1 = atoi( tokens[1] );
        ssr.Out( levelOT1, levelOT2 );
        Serial.print("# OT1 level set to "); Serial.println( levelOT1 );
      }
      return;
    }

    // --------------------------- specify output level on OT2
    // OT2;ddd\n
    if( ! strcmp( tokens[0], "OT2" ) ) {
      uint8_t len = strlen( tokens[1] );
      if( len > 0 ) {
        levelOT2 = atoi( tokens[1] );
        ssr.Out( levelOT1, levelOT2 );
        Serial.print("# OT2 level set to "); Serial.println( levelOT2 );
      }
      return;
    }

    // --------------------------- specify output level on I/O3
    // IO3;ddd\n
    if( ! strcmp( tokens[0], "IO3" ) ) {
      uint8_t len = strlen( tokens[1] );
      if( len > 0 ) {
        levelIO3 = atoi( tokens[1] );
        analogOut( IO3, levelIO3 );
        Serial.print("# IO3 level set to "); Serial.println( levelIO3 );
      }
      return;
    }

    // --------------------------- specify analog output to arbitrary pin
    // WARNING - this is not error checked.
    // APIN;ppp;ddd\n
    if( ! strcmp( tokens[0], "APIN" ) ) {
      uint8_t apin;
      int level;
      uint8_t len1 = strlen( tokens[1] );
      uint8_t len2 = strlen( tokens[2] );
      if( len1 > 0 && len2 > 0 ) {
        apin = atoi( tokens[1] );
        level = atoi( tokens[2] );
        analogOut( apin, level );
        Serial.print("# APIN ");
        Serial.print( (int) apin );
        Serial.print(" level set to "); Serial.println( level );
      }
      return;
    }

    // --------------------------- specify digital output to arbitrary pin
    // WARNING - this is not error checked.
    // DPIN;ppp;ddd\n
    if( ! strcmp( tokens[0], "DPIN" ) ) {
      uint8_t dpin;
      uint8_t len1 = strlen( tokens[1] );
      uint8_t len2 = strlen( tokens[2] );
      if( len1 > 0 && len2 > 0 ) {
        dpin = atoi( tokens[1] );
        pinMode( dpin, OUTPUT );
        if( ! strcmp( tokens[2], "HIGH" ) ) {
          digitalWrite( dpin, HIGH );
          Serial.print("# DPIN ");
          Serial.print( (int) dpin );
          Serial.println(" set to HIGH");
         }
        else if( ! strcmp( tokens[2], "LOW" ) ) {
          digitalWrite( dpin, LOW );
          Serial.print("# DPIN ");
          Serial.print( (int) dpin );
          Serial.println(" set to LOW");
        }
      }
      return;
    }

  }
}

// ----------------------------------
void checkStatus( uint32_t ms ) { // this is an active delay loop
  uint32_t tod = millis();
  while( millis() < tod + ms ) {
    checkSerial();
    // add future code here to detect LCDapter button presses, etc.
  }
}

// ----------------------------------------------------
float convertUnits ( float t ) {
  if( Cscale ) return F_TO_C( t );
  else return t;
}

// ------------------------------------------------------------------
void logger()
{
// print ambient
  Serial.print( convertUnits( AT ), DP );
// print active channels
  for( uint8_t jj = 0; jj < NC; ++jj ) {
    uint8_t k = actv[jj];
    if( k > 0 ) {
      --k;
      Serial.print(",");
      Serial.print( convertUnits( T[k] ) );
    }
  }
  Serial.println();
}

// --------------------------------------------------------------------------
void get_samples() // this function talks to the amb sensor and ADC via I2C
{
  int32_t v;
  TC_TYPE tc;
  float tempF;
  int32_t itemp;
  
  for( uint8_t jj = 0; jj < NC; jj++ ) { // one-shot conversions on both chips
    uint8_t k = actv[jj]; // map logical channels to physical ADC channels
    if( k > 0 ) {
      --k;
      adc.nextConversion( k ); // start ADC conversion on physical channel k
      amb.nextConversion(); // start ambient sensor conversion
      checkStatus( MIN_DELAY ); // give the chips time to perform the conversions
      amb.readSensor(); // retrieve value from ambient temp register
      v = adc.readuV(); // retrieve microvolt sample from MCP3424
      tempF = tc.Temp_F( 0.001 * v, amb.getAmbF() ); // convert uV to Celsius
      v = round( tempF / D_MULT ); // store results as integers
      AT = amb.getAmbF();
      itemp = fT[k].doFilter( v ); // apply digital filtering for display/logging
      T[k] = 0.001 * itemp;
    }
  }
};

#ifdef LCD
// --------------------------------------------
void updateLCD() {
  
 // AT
  int it01 = round( convertUnits( AT ) );
  if( it01 > 999 ) 
    it01 = 999;
  else
    if( it01 < -999 ) it01 = -999;
  sprintf( st1, "%4d", it01 );
  lcd.setCursor( 0, 0 );
  lcd.print("AMB:");
  lcd.print(st1);

  // display the first 2 active channels encountered, normally BT and ET
  uint8_t jj,j;
  uint8_t k;
  for( jj = 0, j = 0; jj < NC && j < 2; ++jj ) {
    k = actv[jj];
    if( k != 0 ) {
      ++j;
      it01 = round( convertUnits( T[k-1] ) );
      if( it01 > 999 ) 
        it01 = 999;
      else
        if( it01 < -999 ) it01 = -999;
      sprintf( st1, "%4d", it01 );
      if( j == 1 ) {
        lcd.setCursor( 9, 0 );
        lcd.print("T1:");
      }
      else {
        lcd.setCursor( 9, 1 );
        lcd.print( "T2:" );
      }
      lcd.print(st1);  
    }
  }
  lcd.setCursor( 0, 1 );
  lcd.print( "         ");
}
#endif

// ------------------------------------------------------------------------
// MAIN
//
void setup()
{
  delay(100);
  Wire.begin(); 
  Serial.begin(BAUD);
  amb.init( AMB_FILTER );  // initialize ambient temp filtering

#ifdef LCD
  lcd.begin(16, 2);
  BACKLIGHT;
  lcd.setCursor( 0, 0 );
  lcd.print( BANNER_ARTISAN ); // display version banner
#ifdef CELSIUS
  lcd.print( " C");
#else
  lcd.print( " F");
#endif // Celsius
#endif // LCD

#ifdef EEPROM_ARTISAN
  // read calibration and identification data from eeprom
  if( eeprom.read( 0, (uint8_t*) &caldata, sizeof( caldata) ) == sizeof( caldata ) ) {
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

  fT[0].init( BT_FILTER ); // digital filtering on BT
  fT[1].init( ET_FILTER ); // digital filtering on ET
  fT[2].init( ET_FILTER);
  fT[3].init( ET_FILTER);
  
  // set up output variables
  ssr.Setup( TIME_BASE );
  levelOT1 = levelOT2 = levelIO3 = 0;
  
  // initialize the active channels to default values
  actv[0] = 2;  // BT normally
  actv[1] = 1;  // ET normally
  actv[2] = 0; // default inactive
  actv[3] = 0;

#ifdef LCD
  delay( 800 );
  lcd.clear();
#endif

}

// -----------------------------------------------------------------
void loop()
{
  get_samples();
  
#ifdef LCD
  updateLCD();
#endif

  checkSerial(); // Has a command been received?
}

