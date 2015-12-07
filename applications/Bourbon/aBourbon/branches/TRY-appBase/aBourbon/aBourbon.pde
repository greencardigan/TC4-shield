// aBourbon.pde
//
// N-channel Rise-o-Meter
// output on serial port:  timestamp, ambient, T1, RoR1, T2, RoR2
// output on LCD : timestamp, channel 2 temperature
//                 RoR 1,     channel 1 temperature

// Support for pBourbon.pde and 16 x 2 LCD

// *** BSD License ***
// ------------------------------------------------------------------------------------------
// Copyright (c) 2011, MLG Properties, LLC (www.pidkits.com)
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
//   Neither the name of the copyright owner nor the names of its contributors may be 
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

#define BANNER "Bourbon V3.beta"
// Revision history:
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
//   20110605  Complete rewrite (V3.beta) using TC4app library classes
//   20110607  Use appSerialRst as base class
//   20110608  Cleaned up some #ifdef commands for the LCD
//   20110609  Linked with revised TCapp classes.  Selectable ADC configuration.
//   20110613  Linked with new thermocouple library

// Parts of this code are derived from a_logger.pde file by Bill Welch (bvwelch.com)
// Bill's significant role in this project in gratefully acknowledged.

// Arduino library
#include <Wire.h>

// TC4 libraries
#include <TC4app.h>  // base class for application
#include <cADC.h>  // MCP3424 support
#include <mcEEPROM.h>  // EEPROM support
#include <cLCD.h>  // LCD display support (optional)
#include <cButton.h>  // buttons on the LCDapter (optional)
//#include <TCbase.h> // base class for thermocouples
#include <thermocouple.h>
#include <cmndproc.h>  // command interpreter

// user preferences
#include "user.h"

// memory checker
#include "MemoryFree.h"

// thermocouple sensor
typeK tcK; // uses addl 20 bytes RAM  743
typeT tcT; // uses addl 20 bytes RAM  723
typeJ tcJ; // uses  addl 20 bytes RAM 703

#define TC tcK

// ---------------------------------- LCD interface definition
#ifdef LCDAPTER
  cLCD lcd; // I2C LCD interface
  cButtonPE16 buttons; // class object to manage button presses
#else // parallel interface, standard LiquidCrystal
  #define RS 2
  #define ENABLE 4
  #define D4 7
  #define D5 8
  #define D6 12
  #define D7 13
  LiquidCrystal lcd( RS, ENABLE, D4, D5, D6, D7 ); // standard 4-bit parallel interface
#endif

// define a new class to get control of ADC and ambient chip configs
class appBourbon : public appSerialRst {
  public:
    appBourbon( tcBase* tc ) : appSerialRst( tc ){}
  protected:
    // these will be called by the start() method
    virtual void setAmbCfg(){amb.setCfg( AMB_BITS_12 );}
    virtual void setADCcfg(){adc.setCfg( ADC_BITS_18, ADC_GAIN_8, ADC_CONV_1SHOT );}
};
  
// the app constructor must identify a sensor that derives from TCbase
appBourbon app( &TC );

void setup() {
  app.setBanner( BANNER );
  
#ifdef LCDAPTER
  app.setLCD ( &lcd, 16, 2 );
  app.setButtons( &buttons );
#else 
#ifdef LIQUID_CRYSTAL
  app.setLCD( &lcd, 16, 2 );
#endif
#endif
  
#ifdef CELSIUS
  app.setUnits( 'C' );  // Fahrenheit is default
#endif
  
  app.setBaud( BAUD ); 
  app.setActiveChannels( 1, 2, 0, 0 ); 
  app.setAmbFilter( AMB_FILTER ); 
  app.initTempFilters(BT_FILTER, ET_FILTER, 0, 0 ); 
  app.initRiseFilters(RISE_FILTER, RISE_FILTER, 0 , 0 ); 
  app.initRoRFilters(ROR_FILTER, ROR_FILTER, 0, 0 );   
  app.start(1000); // minimum loop time (will be extended automatically if needed)

  Serial.print("# Free RAM = ");Serial.println( freeMemory() );
}

void loop() {
  app.run();
}



