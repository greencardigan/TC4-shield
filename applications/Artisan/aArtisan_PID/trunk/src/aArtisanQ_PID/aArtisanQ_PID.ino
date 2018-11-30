// aArtisanQ_PID.ino
// ------------

// Written to support the Artisan roasting scope //http://code.google.com/p/artisan/

//   Heater is controlled from OT1 using a zero cross SSR (integral pulse control)
//   AC fan is controlled from OT2 using a random fire SSR (phase angle control)
//   zero cross detector (true on logic low) is connected to I/O3

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
// 20110601 Major rewrite to use cmndproc.h library
//          RF2000 and RC2000 set channel mapping to 1200
// 20110602 Added ACKS_ON to control verbose output
// ----------- Version 1.10
// 20111011 Added support for type J and type T thermocouples
//          Better error checking on EEPROM reads
// ----------- aArtsianQ version 0.xx
// 20111031 Created.
// ----------- aArtisanQ beta1
// 20111101 Beta 1 release


// ----------- aArtisanQ_PID (Brad Collins)
// 20120915 Created.
//          Added PID Library
//          Added code for analogue inputs
// 20120916 Added PID command allowing PID control to be activated and deactivated from Artisan
//          Added roast clock. Can be reset with PID;TIME command
//          Removed LCD ambient temp display and added roast clock display
// 20120918 Added code to read profile from EEPROM and interpolate to calculate setpoint. Time/Temp profiles
//          Added code to end PID control when end of profile is reached
//          Added additional PID command allowing roast profile to be selected
//          Added additional PID command allowing PID tunings to be adjusted on the fly (required MAX_TOKENS 5 in cmndproc.h library)
// 20120920 Added RoR calcs
// 20120921 Updated RoR calcs to better handle first loop issue (RoR not calculated in first loop)
//          Stopped ANLG1 being read during PID control
//          Added code to convert PID Setpoint temps to correct units.  Added temperature units data to profile format
//          Serial command echo to LCD now optional
// 20120922 Added support for LCDapter buttons and LEDs (button 1 currently activates or deactivates PID control if enabled)
//          Added code to allow power to OT1 to be cut if OT2 is below HTR_CUTOFF_FAN_VAL percentage as defined in user.h.  For heater protection if required. Required modification to phase_ctrl.cpp
//          Added code to allow OT2 to range between custom min and max percentages (defined in user.h)
// 20121007 Fixed PID tuning command so it handles doubles
//          Added inital PID tuning parameters in user.h
// 20121013 Added code to allow Artisan plotting of levelOT1 and levelOT2 if PLOT_POWER is defined in user.h
//          Swapped location of T1 and T2 on LCD display and renamed to ET and BT
// 20121014 Enhanced LCD display code and added support for 4x20 LCDs. Define LCD_4x20 in user.h
// 20121021 Added optional limits for Analogue1
// 20121120 Added support for pBourbon logging
// 20121213 Added UP and DOWN parameters for OT1 and OT2 commands.  Increments or decrements power levels by 5%
// 20130116 Added user adjustable analogue input rounding (DUTY_STEP) in user.h
// 20130119 aArtisanQ_PID release 3_5
//          Added code to allow for additional LCD display modes
// 20130120 Added ability to change roast profile using LCD and buttons
// 20130121 Tidied up button press code
// 20130203 Permits use of different TC types on individual channels as in aArtisan 2.10
//          Updated temperature sample filtering to match aArtisan 2.10
// 20130406 Added GO and STOP commands to use with Artisan 'Charge' and 'End' buttons
// 20140127 aArtisanQ_PID release 4_0 created
//          Added support for Roastlogger roasting software (responds to LOAD, POWER and FAN commands. Sends rorT1=, T1=, rorT2=, T2= and power levels to roastlogger)
// 20140128 Improved handling of heater and fan power limits
// 20140213 aArtisanQ_PID release 4_2
// 20140214 Added option in user.h to define software mode (Artisan, Roastlogger or pBourbon)
//          Fixed? bug causing crashes when receiving READ commands
// 20140214 aArtisanQ_PID release 4_3
// 20150328 Replaced pBourbon option with Android option
//          Bug fix in LCD menu code.  Menu code disabled when not roasting stand alone
//          Changed default PID channel to 0
//          Added SV to values sent to Android app
// 20150328 aArtisanQ_PID release 5_0
// 20150403 Added PID;SV command from aArtisan
//          Changed default PID roast profile to 0 when using logging software
//          Reduced SRAM usage
// 20150404 Added PID;CHAN PID;CT and FILT commands
//          Added Heater, Fan and SV values to Artisan Logger if PID active
//          Removed PLOT_POWER option. Send power levels and SV if PID is active for Artisan. Send all by default for Android
// 20150409 Made loop time variable. Default = 1000ms (1s) but changes to 2000ms (2s) if needed for reading 4 temperature channels
//          Adjusted Read command to match aArtisan. Runs logger() from command to provide immediate response to Artisan
// 20150426 Removed io3, rf2000 and rc2000 commands to save memory
//          Other small compile changes to save memory
//          Compile directive change to ensure output levels are displayed when analogue pots are not active
// 20160416 Added fast PWM (3.922kHz) available in Phase Angle Control Mode on IO3. Enable using IO3_HTR_PAC in user.h.
//          Moved default zero-cross interrupt to IO2 to allow PWM out on IO3.
//          Also does 3.922kHz PWM for DC fan on IO3 in PWM mode.
//          Added Min and Max for IO3 output
//          aArtisanQ_PID version 6_2 released for testing
// 20161214 Added some compile directives to disable the pwmio3 variable when IO3_HTR_PAC is not defined (JGG)
//          This was causing the pullup on IO3 to be disabled and intefered with use of IO3 as the ZCD input
// 20161216 Changes to user.h (and others) to implement pre-defined configurations
// 20171004 Changed definition of PID_CHAN from logical channel to physical channel
//          This was causing issues with Artisan Roasting Scope logic when doing background follow with TC4 PID and logical channels set using CHAN;2100
//          Artisan Roasting Scope is assuming X in PID;CHAN;X command is a physical channel
//          Adjusted ROR_CHAN code to match physical channel approach
//          Adjusted command.txt to suit above changes
//          Adjusted Logger() so Heater Duty and Fan Duty are always sent in serial stream regardless od PID state
// 20180214 Added support for cheap I2C LCDs
//          Added support for two directly connected buttons for reseting timer and toggle PID.
// 20180529 Added support for another 2 buttons for menu navigation
//          Modified compile directives to allow IO3 PWM control and DCFAN command in CONFIG_PAC2 mode
//          Minor bug fix in logger()
// 20180831 Added support for PID_V1.2 library with Proportional on Measurement mode option
//          Added flag in user.h to set default PID mode
//          Modified PID tuning serial command. Now accepts PID;T_POM;p;i;d to set P_ON_M mode. PID;T;p;i;d now switches to P_ON_E mode.
//          Added new PID;LIMIT;min;max serial command to allow the PID output limits to be set.
//          Cleaned code to remove compile warnings
// 20180913 Version 6_6 released
// 20181130 Added compile directives to allow CONFIG_PAC3 mode to compile
//          Minor changes to user.h defaults
//          Version 6_7 released
      
#define BANNER_ARTISAN "aArtisanQ_PID 6_7"

// this library included with the arduino distribution
#include <Wire.h>

// The user.h file contains user-definable and some other global compiler options
// It must be located in the same folder as aArtisan.pde
#include "user.h"

// command processor declarations -- must be in same folder as aArtisan
#include "cmndreader.h"

#ifdef MEMORY_CHK
  // debugging memory problems
  #include "MemoryFree.h"
#endif

#ifdef PHASE_ANGLE_CONTROL
  // code for integral cycle control and phase angle control
  #include "phase_ctrl.h"
#endif

#include <PWM16.h> // for SSR output

// these "contributed" libraries must be installed in your sketchbook's arduino/libraries folder
#include <cmndproc.h> // for command interpreter
#include <thermocouple.h> // type K, type J, and type T thermocouple support
#include <cADC.h> // MCP3424

#if defined LCD_PARALLEL || defined LCDAPTER
  #include <cLCD.h> // required only if LCD is used
#endif
#ifdef LCD_I2C
  #include <LiquidCrystal_I2C.h>
#endif

// ------------------------ other compile directives
#define MIN_DELAY 300   // ms between ADC samples (tested OK at 270)
#define DP 1  // decimal places for output on serial port
#define D_MULT 0.001 // multiplier to convert temperatures from int to float
#define DELIM "; ,=" // command line parameter delimiters

#include <mcEEPROM.h>
mcEEPROM eeprom;
calBlock caldata;

float AT; // ambient temp
float T[NC];  // final output values referenced to physical channels 0-3
int32_t ftemps[NC]; // heavily filtered temps
int32_t ftimes[NC]; // filtered sample timestamps
int32_t ftemps_old[NC]; // for calculating derivative
int32_t ftimes_old[NC]; // for calculating derivative
float RoR[NC]; // final RoR values
uint8_t actv[NC];  // identifies channel status, 0 = inactive, n = physical channel + 1

#ifdef CELSIUS // only affects startup conditions
boolean Cscale = true;
#else
boolean Cscale = false;
#endif

int levelOT1, levelOT2;  // parameters to control output levels
#if !(defined PHASE_ANGLE_CONTROL && (INT_PIN == 3) )
int levelIO3;
#endif

#ifdef MEMORY_CHK
uint32_t checktime;
#endif

#ifdef ANALOGUE1
  uint8_t anlg1 = 0; // analog input pins
  int32_t old_reading_anlg1; // previous analogue reading
  boolean analogue1_changed;
#endif

#ifdef ANALOGUE2
  uint8_t anlg2 = 1; // analog input pins
  int32_t old_reading_anlg2; // previous analogue reading
  boolean analogue2_changed;
#endif

#ifdef PID_CONTROL
  #include <PID_v1.h>

  //Define PID Variables we'll be connecting to
  double Setpoint, Input, Output, SV; // SV is for roasting software override of Setpoint

  //Specify the links and initial tuning parameters
  #ifdef POM
  PID myPID(&Input, &Output, &Setpoint,2,5,1,P_ON_M,DIRECT);
  #else
  PID myPID(&Input, &Output, &Setpoint,2,5,1,P_ON_E,DIRECT);
  #endif
  uint8_t pid_chan = PID_CHAN; // identify PV and set default value from user.h

  int profile_number; // number of the profile for PID control
  int profile_ptr; // EEPROM pointer for profile data
  char profile_name[40];
  char profile_description[80];
  int profile_number_new; // used when switching between profiles
  
  int times[2], temps[2]; // time and temp values read from EEPROM for setpoint calculation
  
  char profile_CorF; // profile temps stored as Centigrade or Fahrenheit

#endif

uint32_t counter; // second counter
uint32_t next_loop_time; // 
boolean first;
uint16_t looptime = 1000;

// class objects
cADC adc( A_ADC ); // MCP3424
ambSensor amb( A_AMB ); // MCP9800
filterRC fT[NC]; // filter for logged ET, BT
filterRC fRise[NC]; // heavily filtered for calculating RoR
filterRC fRoR[NC]; // post-filtering on RoR values
#ifndef PHASE_ANGLE_CONTROL
PWM16 ssr;  // object for SSR output on OT1, OT2
#endif
// -----------------------------------------
// revised 14-Dec-2016 by JGG to disable constructor of pwmio3 when IO3_HTR_PAC not used
// revised 24-Sep-2017 by Brad changed from #ifdef IO3_HTR_PAC to #ifndef CONFIG_PAC3
#ifndef CONFIG_PAC3
PWM_IO3 pwmio3;
#endif
// --------------------------------------
CmndInterp ci( DELIM ); // command interpreter object

// array of thermocouple types
tcBase * tcp[4];
TC_TYPE1 tc1;
TC_TYPE2 tc2;
TC_TYPE3 tc3;
TC_TYPE4 tc4;

// ---------------------------------- LCD interface definition

#if defined LCD_PARALLEL || defined LCDAPTER || defined LCD_I2C
  // LCD output strings
  char st1[6],st2[6];
  int LCD_mode = 0;
#endif

#ifdef LCDAPTER
  #include <cButton.h>
  cButtonPE16 buttons; // class object to manage button presses
  #define BACKLIGHT lcd.backlight();
  cLCD lcd; // I2C LCD interface
#endif

#ifdef LCD_I2C
  // Set the pins on the I2C chip used for LCD connections:
  //                    addr, en,rw,rs,d4,d5,d6,d7,bl,blpol
  LiquidCrystal_I2C lcd(LCD_I2C_ADDRESS, 2, 1, 0, 4, 5, 6, 7, 3, POSITIVE);  // Set the LCD I2C address
  #define BACKLIGHT lcd.backlight();
#endif

#ifdef LCD_PARALLEL
  #define BACKLIGHT ;
  #define RS 2
  #define ENABLE 4
  #define D4 7
  #define D5 8
  #define D6 12
  #define D7 13
  LiquidCrystal lcd( RS, ENABLE, D4, D5, D6, D7 ); // standard 4-bit parallel interface
#endif

unsigned long debounceDelay = 50;
#ifdef RESET_TIMER_BUTTON 
  unsigned long lastDebounceTimeRESET_TIMER_BUTTON = 0;
  int buttonStateRESET_TIMER_BUTTON;  // the current reading from the input pin
  int lastButtonStateRESET_TIMER_BUTTON = HIGH;  // the previous reading from the input pin
#endif
#ifdef TOGGLE_PID_BUTTON 
  unsigned long lastDebounceTimeTOGGLE_PID_BUTTON = 0;
  int buttonStateTOGGLE_PID_BUTTON;  // the current reading from the input pin
  int lastButtonStateTOGGLE_PID_BUTTON = HIGH;  // the previous reading from the input pin
#endif
#ifdef MODE_BUTTON
  unsigned long lastDebounceTimeMODE_BUTTON = 0;
  int buttonStateMODE_BUTTON;  // the current reading from the input pin
  int lastButtonStateMODE_BUTTON = HIGH;  // the previous reading from the input pin
#endif
#ifdef ENTER_BUTTON
  unsigned long lastDebounceTimeENTER_BUTTON = 0;
  int buttonStateENTER_BUTTON;  // the current reading from the input pin
  int lastButtonStateENTER_BUTTON = HIGH;  // the previous reading from the input pin
#endif


// --------------------------------------------- end LCD interface

// T1, T2 = temperatures x 1000
// t1, t2 = time marks, milliseconds
// ---------------------------------------------------
float calcRise( int32_t T1, int32_t T2, int32_t t1, int32_t t2 ) {
  int32_t dt = t2 - t1;
  if( dt == 0 ) return 0.0;  // fixme -- throw an exception here?
  float dT = ( convertUnits( T2 ) - convertUnits( T1 ) ) * D_MULT;
  float dS = dt * 0.001; // convert from milli-seconds to seconds
  return ( dT / dS ) * 60.0; // rise per minute
}


// ------------- wrapper for the command interpreter's serial line reader
void checkSerial() {
  const char* result = ci.checkSerial();
  if( result != NULL ) { // some things we might want to do after a command is executed
    #if defined LCD && defined COMMAND_ECHO
    lcd.setCursor( 0, 0 ); // echo all commands to the LCD
    lcd.print( result );
    #endif
    #ifdef MEMORY_CHK
    Serial.print(F("# freeMemory()="));
    Serial.print(freeMemory());
    Serial.print(F("  ,  "));
    Serial.println( result );
    #endif
  }
}

// ----------------------------------
void checkStatus( uint32_t ms ) { // this is an active delay loop
  uint32_t tod = millis();
  while( millis() < tod + ms ) {
    checkSerial();
    #if ( !defined( PHASE_ANGLE_CONTROL ) ) || ( INT_PIN != 3 ) // disable when PAC active and pin 3 reads the ZCD
    dcfan.slew_fan(); // keep the fan smoothly increasing in speed
    #endif
    #ifdef LCDAPTER
      #if not ( defined ROASTLOGGER || defined ARTISAN || defined ANDROID )
        checkButtons();
      #endif
    #endif
    #if not ( defined ROASTLOGGER || defined ARTISAN || defined ANDROID ) // Stops buttons being read unless in standalone mode. Added to fix crash (due to low memory?).
      checkButtonPins();
    #endif
  }
}

// ----------------------------------------------------
float convertUnits ( float t ) {
  if( Cscale ) return F_TO_C( t );
  else return t;
}

// ------------------------------------------------------------------
void logger() {

#ifdef ARTISAN
  // print ambient
  Serial.print( convertUnits( AT ), DP );
  // print active channels
  for( uint8_t jj = 0; jj < NC; ++jj ) {
    uint8_t k = actv[jj];
    if( k > 0 ) {
      --k;
      Serial.print(F(","));
      Serial.print( convertUnits( T[k] ),DP );

    }
  }

  Serial.print(F(","));
  if( FAN_DUTY < HTR_CUTOFF_FAN_VAL ) { // send 0 if OT1 has been cut off
      Serial.print( 0 );
  }
  else {  
    Serial.print( HEATER_DUTY );
  }
  Serial.print(F(","));
  Serial.print( FAN_DUTY );
  if( myPID.GetMode() != MANUAL ) { // If PID in AUTOMATIC mode
    Serial.print(F(","));
    Serial.print( Setpoint );
  } else {
    Serial.print(F(","));
    Serial.print( 0 ); // send 0 if PID is off
  }
  
  Serial.println();

#endif

#ifdef ROASTLOGGER
  for( uint8_t jj = 0; jj < NC; ++jj ) {
    uint8_t k = actv[jj];
    if( k > 0 ) {
      --k;
      Serial.print(F("rorT"));
      Serial.print(k+1);
      Serial.print(F("="));
      Serial.println( RoR[k], DP );
      Serial.print(F("T"));
      Serial.print(k+1);
      Serial.print(F("="));
      Serial.println( convertUnits( T[k] ) );
    }
  }
  Serial.print(F("Power%="));
  if( FAN_DUTY < HTR_CUTOFF_FAN_VAL ) { // send 0 if OT1 has been cut off
    Serial.println( 0 );
  }
  else {  
    Serial.println( HEATER_DUTY );
  }
  Serial.print(F("Fan="));
  Serial.print( FAN_DUTY );
#endif


#ifdef ANDROID

  // print counter
  //Serial.print( counter );
  //Serial.print( F(",") );

  // print ambient
  Serial.print( convertUnits( AT ), DP );
  // print active channels
  for( uint8_t jj = 0; jj < NC; ++jj ) {
    uint8_t k = actv[jj];
    if( k > 0 ) {
      --k;
      Serial.print(F(","));
      Serial.print( convertUnits( T[k] ) );
      Serial.print(F(","));
      Serial.print( RoR[k], DP );
    }
  }
    
  //#ifdef PLOT_POWER
  Serial.print(F(","));
  if( FAN_DUTY < HTR_CUTOFF_FAN_VAL ) { // send 0 if OT1 has been cut off
    Serial.print( 0 );
  }
  else {  
    Serial.print( HEATER_DUTY );
  }
  Serial.print(F(","));
  Serial.print( FAN_DUTY );
  //#endif  
  
  #ifdef PID_CONTROL
  Serial.print(F(","));
  Serial.print( Setpoint );

  #endif
  
  Serial.println();

#endif

}

// --------------------------------------------------------------------------
void get_samples() // this function talks to the amb sensor and ADC via I2C
{
  int32_t v;
  tcBase * tc;
  float tempF;
  int32_t itemp;
  float rx;

  uint16_t dly = amb.getConvTime(); // use delay based on slowest conversion
  uint16_t dADC = adc.getConvTime();
  dly = dly > dADC ? dly : dADC;
  
  for( uint8_t jj = 0; jj < NC; jj++ ) { // one-shot conversions on both chips
    uint8_t k = actv[jj]; // map logical channels to physical ADC channels
    if( k > 0 ) {
      --k;
      tc = tcp[k]; // each channel may have its own TC type
      adc.nextConversion( k ); // start ADC conversion on physical channel k
      amb.nextConversion(); // start ambient sensor conversion
      checkStatus( dly ); // give the chips time to perform the conversions

      if( !first ) { // on first loop dont save zero values
        ftemps_old[k] = ftemps[k]; // save old filtered temps for RoR calcs
        ftimes_old[k] = ftimes[k]; // save old timestamps for filtered temps for RoR calcs
      }
      
      ftimes[k] = millis(); // record timestamp for RoR calculations
      
      amb.readSensor(); // retrieve value from ambient temp register
      v = adc.readuV(); // retrieve microvolt sample from MCP3424
      tempF = tc->Temp_F( 0.001 * v, amb.getAmbF() ); // convert uV to Celsius

      // filter on direct ADC readings, not computed temperatures
      v = fT[k].doFilter( v << 10 );  // multiply by 1024 to create some resolution for filter
      v >>= 10; 
      AT = amb.getAmbF();
      T[k] = tc->Temp_F( 0.001 * v, AT ); // convert uV to Fahrenheit;

      ftemps[k] =fRise[k].doFilter( tempF * 1000 ); // heavier filtering for RoR

      if ( !first ) { // on first loop dont calc RoR
        rx = calcRise( ftemps_old[k], ftemps[k], ftimes_old[k], ftimes[k] );
        RoR[k] = fRoR[k].doFilter( rx / D_MULT ) * D_MULT; // perform post-filtering on RoR values
      }
    }
  }
  first = false;
};

#if defined LCD_PARALLEL || defined LCDAPTER || defined LCD_I2C
// --------------------------------------------
void updateLCD() {
  
  if( LCD_mode == 0 ) { // Display normal LCD screen
  
    lcd.setCursor(0,0);  
    if(counter/60 < 10) lcd.print(F("0")); lcd.print(counter/60); // Prob can do this better. Check aBourbon.
    lcd.print(F(":")); // make this blink?? :)
    if(counter - (counter/60)*60 < 10) lcd.print(F("0")); lcd.print(counter - (counter/60)*60);
    
  #ifdef LCD_4x20
  
  #ifdef COMMAND_ECHO
    lcd.print(F(" ")); // overwrite artisan commands
  #endif
  
    // display the first 2 active channels encountered, normally BT and ET
    int it01;
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
          lcd.setCursor( 13, 0 );
          lcd.print(F("ET:"));
        }
        else {
          lcd.setCursor( 13, 1 );
          lcd.print( F("BT:") );
        }
        lcd.print(st1);  
      }
    }
    
  // AT
    it01 = round( convertUnits( AT ) );
    if( it01 > 999 ) 
      it01 = 999;
    else
      if( it01 < -999 ) it01 = -999;
    sprintf( st1, "%3d", it01 );
    lcd.setCursor( 6, 0 );
    lcd.print(F("AT:"));
    lcd.print(st1);
    
  #ifdef PID_CONTROL
    if( myPID.GetMode() != MANUAL ) { // if PID is on then display PID: nnn% instead of OT1:
      lcd.setCursor( 0, 2 );
      lcd.print( F("PID:") );
      if( FAN_DUTY < HTR_CUTOFF_FAN_VAL ) { // display 0% if OT1 has been cut off
      sprintf( st1, "%4d", (int)0 );     
      }
      else {
        sprintf( st1, "%4d", (int)HEATER_DUTY );
      }
      lcd.print( st1 ); lcd.print(F("%"));
      
      lcd.setCursor( 13, 2 ); // display setpoint if PID is on
      lcd.print( F("SP:") );
      sprintf( st1, "%4d", (int)Setpoint );
      lcd.print( st1 );
    }
    else {
  //#ifdef ANALOGUE1
      lcd.setCursor( 13, 2 );
      lcd.print(F("       ")); // blank out SP: nnn if PID is off
  //#else
  //    lcd.setCursor( 0, 2 );
  //    lcd.print(F("                    ")); // blank out PID: nnn% and SP: nnn if PID is off and ANALOGUE1 isn't defined
  //#endif // end ifdef ANALOGUE1
    }
  #endif // end ifdef PID_CONTROL
  
    // RoR
    lcd.setCursor( 0, 1 );
    lcd.print( F("RoR:"));
    sprintf( st1, "%4d", (int)RoR[ROR_CHAN - 1] ); // adjust ROR_CHAN for 0-based array index
    lcd.print( st1 );
  
  
  //#ifdef ANALOGUE1
  #ifdef PID_CONTROL
    if( myPID.GetMode() == MANUAL ) { // only display OT2: nnn% if PID is off so PID display isn't overwriten
      lcd.setCursor( 0, 2 );
      lcd.print(F("HTR:"));
      if( FAN_DUTY < HTR_CUTOFF_FAN_VAL ) { // display 0% if OT1 has been cut off
      sprintf( st1, "%4d", (int)0 );     
      }
      else {
        sprintf( st1, "%4d", (int)HEATER_DUTY );
      }
      lcd.print( st1 ); lcd.print(F("%"));
    }
      
  #else // if PID_CONTROL isn't defined then always display OT1: nnn%
      lcd.setCursor( 0, 2 );
      lcd.print(F("HTR:"));
      if( FAN_DUTY < HTR_CUTOFF_FAN_VAL ) { // display 0% if OT1 has been cut off
      sprintf( st1, "%4d", (int)0 );     
      }
      else {
        sprintf( st1, "%4d", (int)HEATER_DUTY );
      }
      lcd.print( st1 ); lcd.print(F("%"));
  #endif // end ifdef PID_CONTROL
  //#endif // end ifdef ANALOGUE1
  
  //#ifdef ANALOGUE2
    lcd.setCursor( 0, 3 );
    lcd.print(F("FAN:"));
    sprintf( st1, "%4d", (int)FAN_DUTY );
    lcd.print( st1 ); lcd.print(F("%"));
  //#endif
  
  #else // if not def LCD_4x20 ie if using a standard 2x16 LCD
  
  #ifdef COMMAND_ECHO
    lcd.print(F("    ")); // overwrite artisan commands
  #endif
  
    // display the first 2 active channels encountered, normally BT and ET
    int it01;
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
          lcd.print(F("ET:"));
        }
        else {
          lcd.setCursor( 9, 1 );
          lcd.print( F("BT:") );
        }
        lcd.print(st1);  
      }
    }
  
  #ifdef PID_CONTROL
    if( myPID.GetMode() != MANUAL ) {
      lcd.setCursor( 0, 1 );
      if( FAN_DUTY < HTR_CUTOFF_FAN_VAL ) { // display 0% if OT1 has been cut off
        lcd.print( F("  0") );
      }
      else {
        sprintf( st1, "%3d", (int)HEATER_DUTY );
        lcd.print( st1 );
      }
      lcd.print(F("%"));
      sprintf( st1, "%4d", (int)Setpoint );
      lcd.print(st1);  
    }
    else {
      lcd.setCursor( 0, 1 );
      lcd.print( F("RoR:"));
      sprintf( st1, "%4d", (int)RoR[ROR_CHAN - 1] ); // adjust ROR_CHAN for 0-based array index
      lcd.print( st1 );
    }
  #else
      lcd.setCursor( 0, 1 );
      lcd.print( F("RoR:"));
      sprintf( st1, "%4d", (int)RoR[ROR_CHAN - 1] ); // adjust ROR_CHAN for 0-based array index
      lcd.print( st1 );
  #endif // end ifdef PID_CONTROL
  
  #ifdef ANALOGUE1
    if( analogue1_changed == true ) { // overwrite RoR or PID values
      lcd.setCursor( 0, 1 );
      lcd.print(F("HTR:     "));
      lcd.setCursor( 4, 1 );
      if( FAN_DUTY < HTR_CUTOFF_FAN_VAL ) { // display 0% if OT1 has been cut off
        sprintf( st1, "%3d", (int)0 );     
      }
      else {
        sprintf( st1, "%3d", (int)HEATER_DUTY );
      }
      lcd.print( st1 ); lcd.print(F("%"));
    }
  #endif //ifdef ANALOGUE1
  #ifdef ANALOGUE2
    if( analogue2_changed == true ) { // overwrite RoR or PID values
      lcd.setCursor( 0, 1 );
      lcd.print(F("FAN:     "));
      lcd.setCursor( 4, 1 );
      sprintf( st1, "%3d", (int)FAN_DUTY );
      lcd.print( st1 ); lcd.print(F("%"));
    }
  #endif // end ifdef ANALOGUE2
  
  #endif // end of ifdef LCD_4x20

  }

  else if( LCD_mode == 1 ) { // Display alternative 1 LCD display

  #ifdef PID_CONTROL
  #ifdef LCD_4x20
    lcd.setCursor( 0, 0 );
    for( int i = 0; i < 20; i++ ) {
      if( profile_name[i] != 0 ) lcd.print( profile_name[i] );
    }
    lcd.setCursor( 0, 1 );
    for( int i = 0; i < 20; i++ ) {
      if( profile_description[i] != 0 ) lcd.print( profile_description[i] );
    }
    lcd.setCursor( 0, 2 );
    for( int i = 20; i < 40; i++ ) {
      if( profile_description[i] != 0 ) lcd.print( profile_description[i] );
    }
    lcd.setCursor( 0, 3 );
    lcd.print(F("PID: ")); lcd.print( myPID.GetKp() ); lcd.print(F(",")); lcd.print( myPID.GetKi() ); lcd.print(F(",")); lcd.print( myPID.GetKd() ); 

  #else // if not def LCD_4x20 ie if using a standard 2x16 LCD
    lcd.setCursor( 0, 0 );
    for( int i = 0; i < 20; i++ ) {
      if( profile_name[i] != 0 ) lcd.print( profile_name[i] );
    }
    lcd.setCursor( 0, 1 );
    lcd.print(F("P:")); lcd.print( myPID.GetKp() ); lcd.print(F(",")); lcd.print( myPID.GetKi() ); lcd.print(F(",")); lcd.print( myPID.GetKd() ); 
  #endif // end ifdef LCD_4x20
  #endif // end ifdef PID_CONTROL
  }

} // end of updateLCD()
#endif

#if defined ANALOGUE1 || defined ANALOGUE2
// -------------------------------- reads analog value and maps it to 0 to 100
// -------------------------------- rounded to the nearest DUTY_STEP value
int32_t getAnalogValue( uint8_t port ) {
  int32_t mod, trial, min_anlg1, max_anlg1, min_anlg2, max_anlg2;
#ifdef PHASE_ANGLE_CONTROL
#ifdef IO3_HTR_PAC
  min_anlg1 = MIN_IO3;
  max_anlg1 = MAX_IO3;
  min_anlg2 = MIN_OT2;
  max_anlg2 = MAX_OT2;
#else
  min_anlg1 = MIN_OT1;
  max_anlg1 = MAX_OT1;
  min_anlg2 = MIN_OT2;
  max_anlg2 = MAX_OT2;
#endif
#else // PWM Mode
  min_anlg1 = MIN_OT1;
  max_anlg1 = MAX_OT1;
  min_anlg2 = MIN_IO3;
  max_anlg2 = MAX_IO3;
#endif
  float aval;
  aval = analogRead( port );
  #ifdef ANALOGUE1
    if( port == anlg1 ) {
      aval = min_anlg1 * 10.24 + ( aval / 1024 ) * 10.24 * ( max_anlg1 - min_anlg1 ) ; // scale analogue value to new range
      if ( aval == ( min_anlg1 * 10.24 ) ) aval = 0; // still allow OT1 to be switched off at minimum value. NOT SURE IF THIS FEATURE IS GOOD???????
      mod = min_anlg1;
    }
  #endif
  #ifdef ANALOGUE2
    if( port == anlg2 ) {
      aval = min_anlg2 * 10.24 + ( aval / 1024 ) * 10.24 * ( max_anlg2 - min_anlg2 ) ; // scale analogue value to new range
      if ( aval == ( min_anlg2 * 10.24 ) ) aval = 0; // still allow OT2 to be switched off at minimum value. NOT SURE IF THIS FEATURE IS GOOD???????
      mod = min_anlg2;
    }
  #endif
  trial = ( aval + 0.001 ) * 100; // to fix weird rounding error from previous calcs?????
  trial /= 1023;
  trial = ( trial / DUTY_STEP ) * DUTY_STEP; // truncate to multiple of DUTY_STEP
  if( trial < mod ) trial = 0;
//  mod = trial % DUTY_STEP;
//  trial = ( trial / DUTY_STEP ) * DUTY_STEP; // truncate to multiple of DUTY_STEP
//  if( mod >= DUTY_STEP / 2 )
//    trial += DUTY_STEP;
  return trial;
}
#endif // end if defined ANALOGUE1 || defined ANALOGUE2

#ifdef ANALOGUE1
// ---------------------------------
void readAnlg1() { // read analog port 1 and adjust OT1 output
  char pstr[5];
  int32_t reading;
  reading = getAnalogValue( anlg1 );
  if( reading <= 100 && reading != old_reading_anlg1 ) { // did it change?
    analogue1_changed = true;
    old_reading_anlg1 = reading; // save reading for next time
#ifdef PHASE_ANGLE_CONTROL
#ifdef IO3_HTR_PAC
    levelIO3 = reading;
    outIO3();
#else
    levelOT1 = reading;
    outOT1();
#endif
#else // PWM Mode
    levelOT1 = reading;
    outOT1();
#endif
  }
  else {
    analogue1_changed = false;
  }
}
#endif // end ifdef ANALOGUE1

#ifdef ANALOGUE2
// ---------------------------------
void readAnlg2() { // read analog port 2 and adjust OT2 output
  char pstr[5];
  int32_t reading;
  reading = getAnalogValue( anlg2 );
  if( reading <= 100 && reading != old_reading_anlg2 ) { // did it change?
    analogue2_changed = true;
    old_reading_anlg2 = reading; // save reading for next time
#ifdef PHASE_ANGLE_CONTROL
    levelOT2 = reading;
    outOT2(); // update fan output on OT2
#else // PWM Mode
    levelIO3 = reading;
    outIO3(); // update fan output on IO3
#endif
  }
  else {
    analogue2_changed = false;
  }
}
#endif // end ifdef ANALOGUE2


#ifdef PID_CONTROL
// ---------------------------------
void updateSetpoint() { //read profile data from EEPROM and calculate new setpoint
  
  if(profile_number > 0 ){
    while( counter < times[0] || counter >= times[1] ) { // if current time outside currently loaded interval then adjust profile pointer before reading new interval data from EEPROM
      if( counter < times[0] ) {
        profile_ptr = profile_ptr - 2; // two bytes per int
      }
      else {
        profile_ptr = profile_ptr + 2; // two bytes per int
      }
  
      eeprom.read( profile_ptr, (uint8_t*)&times, sizeof(times) ); // read two profile times
      eeprom.read( profile_ptr + 100, (uint8_t*)&temps, sizeof(temps) ); // read two profile temps.  100 = size of time data
      
      if( times[1] == 0 ) {
        Setpoint = 0;
        myPID.SetMode(MANUAL); // deactivate PID control
        Output = 0; // set PID output to 0
        break;
      }
    }
    
    float x = (float)( counter - times[0] ) / (float)( times[1] - times[0] ); // can probably be tidied up?? Calcs proportion of time through current profile interval
    Setpoint = temps[0] + x * ( temps[1] - temps[0] );  // then applies the proportion to the temps
    if( profile_CorF == 'F' && Cscale ) { // make setpoint units match current units
      Setpoint = convertUnits( Setpoint ); // convert F to C
    }
    else if( profile_CorF == 'C' & !Cscale) { // make setpoint units match current units
      Setpoint = Setpoint * 9 / 5 + 32; // convert C to F
    }
  }
  else {
    Setpoint = SV;
  }
}


void setProfile() { // set profile pointer and read initial profile data

  if( profile_number > 0 ) {
    profile_ptr = 1024 + ( 400 * ( profile_number - 1 ) ) + 4; // 1024 = start of profile storage in EEPROM. 400 = size of each profile. 4 = location of profile C or F data
    eeprom.read( profile_ptr, (uint8_t*)&profile_CorF, sizeof(profile_CorF) ); // read profile temp type
    
    getProfileDescription(profile_number); // read profile name and description data from eeprom for active profile number
    
    profile_ptr = 1024 + ( 400 * ( profile_number - 1 ) ) + 125; // 1024 = start of profile storage in EEPROM. 400 = size of each profile. 125 = size of profile header data
    eeprom.read( profile_ptr, (uint8_t*)&times, sizeof(times) ); // read 1st two profile times
    eeprom.read( profile_ptr + 100, (uint8_t*)&temps, sizeof(temps) ); // read 1st two profile temps.  100 = size of time data
    
    // profile_ptr is left set for profile temp/time reads
  }
  //else //do something?
}

void getProfileDescription(int pn) { // read profile name and description data from eeprom

  if( profile_number > 0 ) {
    int pp = 1024 + ( 400 * ( pn - 1 ) ) + 5; // 1024 = start of profile storage in EEPROM. 400 = size of each profile. 5 = location of profile name
    eeprom.read( pp, (uint8_t*)&profile_name, sizeof(profile_name) ); // read profile name  
  
    pp = 1024 + ( 400 * ( pn - 1 ) ) + 45; // 1024 = start of profile storage in EEPROM. 400 = size of each profile. 45 = location of profile description
    eeprom.read( pp, (uint8_t*)&profile_description, sizeof(profile_description) ); // read profile name  
  }
   //else //do something? 
}
#endif // end ifdef PID_CONTROL

#ifdef LCDAPTER
// ----------------------------------
void checkButtons() { // take action if a button is pressed
  if( buttons.readButtons() ) {
    
    switch (LCD_mode) {
    
      case 0: // Main LCD display
      
        if( buttons.keyPressed( 0 ) && buttons.keyChanged( 0 ) ) { // button 1 - PID on/off - PREVIOUS PROFILE
          #ifdef PID_CONTROL
          if( myPID.GetMode() == MANUAL ) {
            myPID.SetMode( AUTOMATIC );
          }
          else {
            myPID.SetMode( MANUAL );
          }
          #endif
        }
        else if( buttons.keyPressed( 1 ) && buttons.keyChanged( 1 ) ) { // button 2 - RESET TIMER - NEXT PROFILE
          counter = 0;
        }   
        else if( buttons.keyPressed( 2 ) && buttons.keyChanged( 2 ) ) { // button 3 - ENTER BUTTON
          // do something
        }
        else if( buttons.keyPressed( 3 ) && buttons.keyChanged( 3 ) ) { // button 4 - CHANGE LCD MODE
          lcd.clear();
          LCD_mode++; // change mode
          #ifndef PID_CONTROL
          if( LCD_mode == 1 ) LCD_mode++; // deactivate LCD mode 1 if PID control is disabled
          #endif
          if( LCD_mode > 1 ) LCD_mode = 0; // loop at limit of modes
          delay(5);
        }
        break;
        
      case 1: // Profile Selection and PID parameter LCD display
           
        if( buttons.keyPressed( 0 ) && buttons.keyChanged( 0 ) ) { // button 1 - PID on/off - PREVIOUS PROFILE
          #ifdef PID_CONTROL
          profile_number_new--;
          if( profile_number_new == 0 ) profile_number_new = NUM_PROFILES; // loop profile_number to end
          getProfileDescription(profile_number_new);
          #endif
        }
        else if( buttons.keyPressed( 1 ) && buttons.keyChanged( 1 ) ) { // button 2 - RESET TIMER - NEXT PROFILE
          #ifdef PID_CONTROL
          profile_number_new++;
          if( profile_number_new > NUM_PROFILES ) profile_number_new = 1; // loop profile_number to start
          getProfileDescription(profile_number_new);
          #endif
        }   
        else if( buttons.keyPressed( 2 ) && buttons.keyChanged( 2 ) ) { // button 3 - ENTER BUTTON
          #ifdef PID_CONTROL
          profile_number = profile_number_new; // change profile_number to new selection
          setProfile(); // call setProfile to load the profile selected
          lcd.clear();
          LCD_mode = 0; // jump back to main LCD display mode
          #endif
        }
        else if( buttons.keyPressed( 3 ) && buttons.keyChanged( 3 ) ) { // button 4 - CHANGE LCD MODE
          lcd.clear();
          #ifdef PID_CONTROL
          profile_number_new = profile_number; // reset profile_number_new if profile wasn't changed
          setProfile(); // or getProfileDescription()?????????
          #endif
          LCD_mode++; // change mode
          if( LCD_mode > 1 ) LCD_mode = 0; // loop at limit of modes
          delay(5);
        }
        break;
    } //end of switch
  } // end of if( buttons.readButtons() )
} // end of void checkButtons()
#endif // end ifdef LCDAPTER


// ----------------------------------
void outOT1() { // update output for OT1
  uint8_t new_levelot1;
#ifdef PHASE_ANGLE_CONTROL
#ifdef IO3_HTR_PAC // OT1 not cutoff by fan duty in IO3_HTR_PAC mode
  new_levelot1 = levelOT1;
#else
  if ( levelOT2 < HTR_CUTOFF_FAN_VAL ) {
    new_levelot1 = 0;
  }
  else {
    new_levelot1 = levelOT1;
  }
#endif
  output_level_icc( new_levelot1 );
#else // PWM Mode
  if ( levelIO3 < HTR_CUTOFF_FAN_VAL ) {
    new_levelot1 = 0;
  }
  else {
    new_levelot1 = levelOT1;
  }
  ssr.Out( new_levelot1, levelOT2 );
#endif

}

// ----------------------------------
void outOT2() { // update output for OT2

#ifdef PHASE_ANGLE_CONTROL
#ifdef IO3_HTR_PAC
  outIO3(); // update IO3 output to cut or reinstate power to heater if required
#else
  outOT1(); // update OT1 output to cut or reinstate power to heater if required
#endif
  output_level_pac( levelOT2 );
#else // PWM Mode
  if( levelIO3 < HTR_CUTOFF_FAN_VAL ) { // if levelIO3 < cutoff value then turn off heater
    ssr.Out( 0, levelOT2 );
  }
  else {  // turn OT1 and OT2 back on again if levelIO3 is above cutoff value.
    ssr.Out( levelOT1, levelOT2 );
  }
#endif

}

#if ( !defined( CONFIG_PAC3 ) )  // completely disable outIO3 if using CONFIG_PAC3 mode (uses IO3 for interrupt)
// ----------------------------------
void outIO3() { // update output for IO3

  float pow;

#ifdef PHASE_ANGLE_CONTROL
  uint8_t new_levelio3;
  new_levelio3 = levelIO3;
#ifdef IO3_HTR_PAC
  if( levelOT2 < HTR_CUTOFF_FAN_VAL ) { // if levelIO3 < cutoff value then turn off heater on IO3
    new_levelio3 = 0;
  }
#endif // IO3_HTR_PAC
  pow = 2.55 * new_levelio3;
  pwmio3.Out( round(pow) );
#else // PWM Mode, fan on IO3
  if( levelIO3 < HTR_CUTOFF_FAN_VAL ) { // if levelIO3 < cutoff value then turn off heater on OT1
    ssr.Out( 0, levelOT2 );
  }
  else {  // turn OT1 and OT2 back on again if levelIO3 is above cutoff value.
    ssr.Out( levelOT1, levelOT2 );
  }
  pow = 2.55 * levelIO3;
  pwmio3.Out( round(pow) );
#endif // PWM Mode, fan on IO3
}
#endif

// ----------------------------------
#if not ( defined ROASTLOGGER || defined ARTISAN || defined ANDROID ) // Stops buttons being read unless in standalone mode. Added to fix crash (due to low memory?).

void checkButtonPins() {
int reading;
#ifdef RESET_TIMER_BUTTON
  reading = digitalRead(RESET_TIMER_BUTTON);
  
  if (reading != lastButtonStateRESET_TIMER_BUTTON) {
    // reset the debouncing timer
    lastDebounceTimeRESET_TIMER_BUTTON = millis();
  }

  if ((millis() - lastDebounceTimeRESET_TIMER_BUTTON) > debounceDelay) {
    // whatever the reading is at, it's been there for longer than the debounce
    // delay, so take it as the actual current state:

    // if the button state has changed:
    if (reading != buttonStateRESET_TIMER_BUTTON) {
      buttonStateRESET_TIMER_BUTTON = reading;

      // only toggle the LED if the new button state is HIGH
      if (buttonStateRESET_TIMER_BUTTON == LOW) { // LOW = on with internal pullup active
        switch (LCD_mode) {
          case 0:
            counter = 0;
            break;
          case 1:
            #ifdef PID_CONTROL
            profile_number_new--;
            if( profile_number_new == 0 ) profile_number_new = NUM_PROFILES; // loop profile_number to end
            getProfileDescription(profile_number_new);
            #endif
            break;
        }
      }
    }
  }
  lastButtonStateRESET_TIMER_BUTTON = reading;
#endif
#ifdef TOGGLE_PID_BUTTON
  reading = digitalRead(TOGGLE_PID_BUTTON);
  
  if (reading != lastButtonStateTOGGLE_PID_BUTTON) {
    // reset the debouncing timer
    lastDebounceTimeTOGGLE_PID_BUTTON = millis();
  }

  if ((millis() - lastDebounceTimeTOGGLE_PID_BUTTON) > debounceDelay) {
    // whatever the reading is at, it's been there for longer than the debounce
    // delay, so take it as the actual current state:

    // if the button state has changed:
    if (reading != buttonStateTOGGLE_PID_BUTTON) {
      buttonStateTOGGLE_PID_BUTTON = reading;

      // only toggle the LED if the new button state is HIGH
      if (buttonStateTOGGLE_PID_BUTTON == LOW) { // LOW = on with internal pullup active
        switch (LCD_mode) {
          case 0:
          #ifdef PID_CONTROL
            if( myPID.GetMode() == MANUAL ) {
              myPID.SetMode( AUTOMATIC );
            }
            else {
              myPID.SetMode( MANUAL );
            }
          #endif
          break;
          
          case 1:
            #ifdef PID_CONTROL
            Serial.print(profile_number_new);
            profile_number_new++;
            if( profile_number_new > NUM_PROFILES ) profile_number_new = 1; // loop profile_number to start
            getProfileDescription(profile_number_new);
            #endif
            break;
        }
      }
    }
  }
  lastButtonStateTOGGLE_PID_BUTTON = reading;
#endif
#ifdef MODE_BUTTON
  reading = digitalRead(MODE_BUTTON);
  
  if (reading != lastButtonStateMODE_BUTTON) {
    // reset the debouncing timer
    lastDebounceTimeMODE_BUTTON = millis();
  }

  if ((millis() - lastDebounceTimeMODE_BUTTON) > debounceDelay) {
    // whatever the reading is at, it's been there for longer than the debounce
    // delay, so take it as the actual current state:

    // if the button state has changed:
    if (reading != buttonStateMODE_BUTTON) {
      buttonStateMODE_BUTTON = reading;

      // only toggle the LED if the new button state is HIGH
      if (buttonStateMODE_BUTTON == LOW) { // LOW = on with internal pullup active
        switch (LCD_mode) {
          case 0: // Main page
            lcd.clear();
            LCD_mode++; // change mode
            #ifndef PID_CONTROL
            if( LCD_mode == 1 ) LCD_mode++; // deactivate LCD mode 1 if PID control is disabled
            #endif
            if( LCD_mode > 1 ) LCD_mode = 0; // loop at limit of modes
            break;

          case 1: // Profile change page
            lcd.clear();
            #ifdef PID_CONTROL
            profile_number_new = profile_number; // reset profile_number_new if profile wasn't changed
            setProfile(); // or getProfileDescription()?????????
            #endif
            LCD_mode++; // change mode
            if( LCD_mode > 1 ) LCD_mode = 0; // loop at limit of modes
            break;
        }
      }
    }
  }
  lastButtonStateMODE_BUTTON = reading;
#endif
#ifdef ENTER_BUTTON
  reading = digitalRead(ENTER_BUTTON);
  
  if (reading != lastButtonStateENTER_BUTTON) {
    // reset the debouncing timer
    lastDebounceTimeENTER_BUTTON = millis();
  }

  if ((millis() - lastDebounceTimeENTER_BUTTON) > debounceDelay) {
    // whatever the reading is at, it's been there for longer than the debounce
    // delay, so take it as the actual current state:

    // if the button state has changed:
    if (reading != buttonStateENTER_BUTTON) {
      buttonStateENTER_BUTTON = reading;

      // only toggle the LED if the new button state is HIGH
      if (buttonStateENTER_BUTTON == LOW) { // LOW = on with internal pullup active
        switch (LCD_mode) {
          case 0: // Main page
              // do something?
            break;

          case 1: // Profile change page
            #ifdef PID_CONTROL
              profile_number = profile_number_new; // change profile_number to new selection
              setProfile(); // call setProfile to load the profile selected
              lcd.clear();
              LCD_mode = 0; // jump back to main LCD display mode
            #endif
            break;
        }
      }
    }
  }
  lastButtonStateENTER_BUTTON = reading;
#endif

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

#if defined LCD_PARALLEL || defined LCDAPTER || defined LCD_I2C
  #ifdef LCD_4x20
    lcd.begin(20, 4);
  #else
    lcd.begin(16, 2);
  #endif
    BACKLIGHT;
    lcd.setCursor( 0, 0 );
    lcd.print( BANNER_ARTISAN ); // display version banner
    lcd.setCursor( 0, 1 );
  #ifdef ANDROID
    lcd.print( F("ANDROID") ); // display version banner
  #endif // ANDROID
  #ifdef ARTISAN
    lcd.print( F("ARTISAN") ); // display version banner
  #endif // ARTISAN
  #ifdef ROASTLOGGER
    lcd.print( F("ROASTLOGGER") ); // display version banner
  #endif // ROASTLOGGER
  
#endif

#ifdef LCDAPTER
  buttons.begin( 4 );
  buttons.readButtons();
  buttons.ledAllOff();
#endif

#ifdef MEMORY_CHK
  Serial.print(F("# freeMemory()="));
  Serial.println(freeMemory());
#endif

  adc.setCal( CAL_GAIN, UV_OFFSET );
  amb.setOffset( AMB_OFFSET );

  // read calibration and identification data from eeprom
  if( readCalBlock( eeprom, caldata ) ) {
    adc.setCal( caldata.cal_gain, caldata.cal_offset );
    amb.setOffset( caldata.K_offset );
  }
  else { // if there was a problem with EEPROM read, then use default values
    adc.setCal( CAL_GAIN, UV_OFFSET );
    amb.setOffset( AMB_OFFSET );
  }   

  // initialize filters on all channels
  fT[0].init( ET_FILTER ); // digital filtering on ET
  fT[1].init( BT_FILTER ); // digital filtering on BT
  fT[2].init( ET_FILTER);
  fT[3].init( ET_FILTER);
  fRise[0].init( RISE_FILTER ); // digital filtering for RoR calculation
  fRise[1].init( RISE_FILTER ); // digital filtering for RoR calculation
  fRoR[0].init( ROR_FILTER ); // post-filtering on RoR values
  fRoR[1].init( ROR_FILTER ); // post-filtering on RoR values
  
  // set up output on OT1 and OT2 and IO3
  levelOT1 = levelOT2 = 0;
  #if !(defined PHASE_ANGLE_CONTROL && (INT_PIN == 3) )
  levelIO3 = 0;
  #endif
#ifndef PHASE_ANGLE_CONTROL
  ssr.Setup( TIME_BASE );
#else
  init_control();
#endif
// --------------------------
// modifed 14-Dec-2016 by JGG
// revised 22-Mar-2017 by Brad changed from #ifdef IO3_HTR_PAC to #ifndef CONFIG_PAC3
#ifndef CONFIG_PAC3
  pwmio3.Setup( IO3_PCORPWM, IO3_PRESCALE_8 ); // setup pmw frequency ion IO3
#endif
// ----------------------------


  #ifdef ANALOGUE1
  old_reading_anlg1 = getAnalogValue( anlg1 ); // initialize old_reading with initial analogue value
  #endif
  #ifdef ANALOGUE2
  old_reading_anlg2 = getAnalogValue( anlg2 ); // initialize old_reading with initial analogue value
  #endif  
  
  // initialize the active channels to default values
  actv[0] = 2; // ET on TC1
  actv[1] = 1; // BT on TC2
  actv[2] = 0; // default inactive
  actv[3] = 0; // default inactive
  
  // assign thermocouple types
  tcp[0] = &tc1;
  tcp[1] = &tc2;
  tcp[2] = &tc3;
  tcp[3] = &tc4;

// add active commands to the linked list in the command interpreter object
  ci.addCommand( &dwriter );
  ci.addCommand( &awriter );
  ci.addCommand( &units );
  ci.addCommand( &chan );
#if ( !defined( PHASE_ANGLE_CONTROL ) ) || ( INT_PIN != 3 ) // disable when PAC active and pin 3 reads the ZCD
  ci.addCommand( &io3 );
  ci.addCommand( &dcfan );
#endif
  ci.addCommand( &ot2 );
  ci.addCommand( &ot1 );
  ci.addCommand( &reader );
  ci.addCommand( &pid );
  ci.addCommand( &reset );
#ifdef ROASTLOGGER
  ci.addCommand( &load );
  ci.addCommand( &power );
  ci.addCommand( &fan );
#endif
  ci.addCommand( &filt );

#if ( !defined( PHASE_ANGLE_CONTROL ) ) || ( INT_PIN != 3 ) // disable when PAC active and pin 3 reads the ZCD
  dcfan.init(); // initialize conditions for dcfan
#endif
  
  pinMode( LED_PIN, OUTPUT );

#if defined LCD_PARALLEL || defined LCDAPTER || defined LCD_I2C
  delay( 500 );
  lcd.clear();
#endif
#ifdef MEMORY_CHK
  checktime = millis();
#endif

#ifdef PID_CONTROL
  myPID.SetSampleTime(CT); // set sample time to 1 second
#ifdef IO3_HTR_PAC
  myPID.SetOutputLimits(MIN_IO3, MAX_IO3); // set output limits to user defined limits
#else
  myPID.SetOutputLimits(MIN_OT1, MAX_OT1); // set output limits to user defined limits
#endif
  myPID.SetControllerDirection(DIRECT); // set PID to be direct acting mode. Increase in output leads to increase in input
#ifdef POM
  myPID.SetTunings(PRO, INT, DER, P_ON_M); // set initial PID tuning values and set Proportional on Measurement mode
#else
  myPID.SetTunings(PRO, INT, DER, P_ON_E); // set initial PID tuning values and set Proportional on Error mode
#endif
  myPID.SetMode(MANUAL); // start with PID control off
#if not ( defined ROASTLOGGER || defined ARTISAN || defined ANDROID )
  profile_number = 1; // set default profile, 0 is for override by roasting software
#else
  profile_number = 0; // set default profile, 0 is for override by roasting software
#endif
  profile_number_new = profile_number; 
  setProfile(); // read profile description initial time/temp data from eeprom and set profile_pointer
#endif

#ifdef RESET_TIMER_BUTTON
pinMode(RESET_TIMER_BUTTON, INPUT_PULLUP);
#endif
#ifdef TOGGLE_PID_BUTTON
pinMode(TOGGLE_PID_BUTTON, INPUT_PULLUP);
#endif
#ifdef MODE_BUTTON
pinMode(MODE_BUTTON, INPUT_PULLUP);
#endif
#ifdef ENTER_BUTTON
pinMode(ENTER_BUTTON, INPUT_PULLUP);
#endif

first = true;
counter = 3; // start counter at 3 to match with Artisan. Probably a better way to sync with Artisan???
next_loop_time = millis() + looptime; // needed?? 

}


// -----------------------------------------------------------------
void loop()
{
  #ifdef PHASE_ANGLE_CONTROL
  if( ACdetect() ) {
    digitalWrite( LED_PIN, HIGH ); // illuminate the Arduino IDE if ZCD is sending a signal
  }  
  else {
    digitalWrite( LED_PIN, LOW );
  }
  #endif
  #ifdef MEMORY_CHK  
    uint32_t now = millis();
    if( now - checktime > 1000 ) {
      Serial.print(F("# freeMemory()="));
      Serial.println(freeMemory());
      checktime = now;
    }
  #endif
  
  // Has a command been received?
  checkSerial();
  
  // Read temperatures
  get_samples();

  // Read analogue POT values if defined
  #ifdef ANALOGUE1
    #ifdef PID_CONTROL
      if( myPID.GetMode() == MANUAL ) readAnlg1(); // if PID is off allow ANLG1 read
    #else
      readAnlg1(); // if PID_CONTROL is not defined always allow ANLG1 read
    #endif // PID_CONTROL
  #endif // ANALOGUE1
  #ifdef ANALOGUE2
    readAnlg2();
  #endif
  
  // Run PID if defined and active
  #ifdef PID_CONTROL
    if( myPID.GetMode() != MANUAL ) { // If PID in AUTOMATIC mode calc new output and assign to OT1
      updateSetpoint(); // read profile data from EEPROM and calculate new setpoint
      uint8_t k = pid_chan;  // k = physical channel
      if( k != 0 ) --k; // adjust for 0-based array index
      // Input is the SV for the PID algorithm
      Input = convertUnits( T[k] );
      myPID.Compute();  // do PID calcs
#ifdef IO3_HTR_PAC
      levelIO3 = Output; // update levelOT1 based on PID optput
      outIO3();
#else
      levelOT1 = Output; // update levelOT1 based on PID optput
      outOT1();
#endif
      #ifdef ACKS_ON
      Serial.print(F("# PID input = " )); Serial.print( Input ); Serial.print(F("  "));
      Serial.print(F("# PID output = " )); Serial.println( levelOT1 );
      #endif
    }
  #endif

  // Update LCD if defined
  #if defined LCD_PARALLEL || defined LCDAPTER || defined LCD_I2C
    updateLCD();
  #endif
  
  // Send data to Roastlogger if defined
  #if defined ROASTLOGGER
    logger(); // send data every second to Roastlogger every loop (looptime)
  #endif

  // check if temp reads has taken longer than looptime. If so add 1 to counter + increase next looptime
  // Serial.println( next_loop_time - millis() ); // how much time spare in loop. approx 350ms
  if ( millis() > next_loop_time ) {
    counter = counter + ( looptime / 1000 ); if( counter > 3599 ) counter = 3599;
    next_loop_time = next_loop_time + looptime; // add time until next loop
  }
  
  // wait until looptiom is expired. Check serial and buttons while waiting
  while( millis() < next_loop_time ) {
    checkSerial();  // Has a command been received?
  #ifdef LCDAPTER
    #if not ( defined ROASTLOGGER || defined ARTISAN || defined ANDROID ) // Stops buttons being read unless in standalone mode. Added to fix crash (due to low memory?).
      checkButtons();
    #endif
  #endif
  #if not ( defined ROASTLOGGER || defined ARTISAN || defined ANDROID ) // Stops buttons being read unless in standalone mode. Added to fix crash (due to low memory?).
    checkButtonPins();
  #endif
  }
  
  // Set next loop time and increment counter
  next_loop_time = next_loop_time + looptime; // add time until next loop
  counter = counter + ( looptime / 1000 ); if( counter > 3599 ) counter = 3599;
}

