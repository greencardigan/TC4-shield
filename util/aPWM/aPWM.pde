// aPWM.pde
//
// Digital PWM control on OT1 (SSR drive) and IO3 (DC fan??)
// Connect 10K pots to ANLG1 and ANLG2 to control output
// By default, time base is 1 second for OT1 (1Hz)
// PWM frequency is 490Hz for IO3 (2.04 ms)

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
//   Neither the name of the copyright holder nor the names of the contributors may be 
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

#include <Wire.h>
#include <cLCD.h>
#include <PWM16.h>

#define BANNER_PWM "PWM V1.00" // version
#define TIME_BASE pwmN1Hz // cycle time for PWM output to SSR on Ot1
#define BAUD 57600  // serial baud rate
#define IO3 3 // using pin 3 for PWM output

uint8_t anlg1 = 0; // analog input pins
uint8_t anlg2 = 1;
int32_t power1 = 0; // power outputs
int32_t power2 = 0;
PWM16 output1; // uses 16-bit timer for Ot1 and Ot2

// ---------------------------------- LCD interface definition
#define BACKLIGHT lcd.backlight();
cLCD lcd; // I2C LCD interface

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
void readPort1() { // read analog port1 and adjust OT1 output
  char pstr[5];
  int32_t reading;
  reading = getAnalogValue( anlg1 );
  if( reading <= 100 && reading != power1 ) { // did it change?
    power1 = reading;
    Serial.print( "ANLG1," ); Serial.println( power1 );
    output1.Out( power1, 0 ); // update the power output on the SSR drive Ot1
    sprintf( pstr, "%3d", (int)power1 );
    lcd.setCursor( 6, 0 );
    lcd.print( pstr ); lcd.print("%");
  }
}

// ---------------------------------
void readPort2() { // read analog port2 and adjust IO3 output
  char pstr[5];
  int32_t reading;
  reading = getAnalogValue( anlg2 );
  if( reading <= 100 && reading != power2 ) { // did it change?
    power2 = reading;
    Serial.print( "ANLG2," ); Serial.println( power2 );
    float pow = 2.55 * power2; // output values are 0 to 255
    analogWrite( IO3, round( pow ) );
    sprintf( pstr, "%3d", (int)power2 );
    lcd.setCursor( 6, 1 );
    lcd.print( pstr ); lcd.print("%");
  }
}

// ------------------------------------------------------------------------
//
void setup()
{
  delay(100);
  Wire.begin();
  Serial.begin( BAUD );
  lcd.begin(16, 2);
  BACKLIGHT;
  lcd.setCursor( 0, 0 );
  lcd.print( BANNER_PWM ); // display version banner

// set up the outputs
  pinMode( IO3, OUTPUT );
  output1.Setup( TIME_BASE );
  power1 = -50;  // initialize to impossible value to force immediate update
  power2 = -50;
  output1.Out( 0, 0 ); // start with zero output
  analogWrite( IO3, 0 );

  delay( 3000 ); // display banner for a while

// put static text on the LCD
  lcd.clear();
  lcd.setCursor( 0, 0 );
  lcd.print( "ANLG1" );
  lcd.setCursor( 11, 0 );
  lcd.print( "OT1");
  lcd.setCursor( 0, 1 );
  lcd.print( "ANLG2" );
  lcd.setCursor( 11, 1 );
  lcd.print( "IO3");
}

// -----------------------------------------------------------------
void loop() {
  delay( 100 );
  readPort1();
  readPort2();
}

