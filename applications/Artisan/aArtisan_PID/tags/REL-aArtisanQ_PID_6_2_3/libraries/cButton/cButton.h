/*
 * cButton.h
 *
 *  Created on: Sep 8, 2010
 */

// *** BSD License ***
// ------------------------------------------------------------------------------------------
// Copyright (c) 2010, MLG Properties, LLC
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

// Revision history:
//  20120126: Arduino 1.0 compatibility
//   (thanks and acknowledgement to Arnaud Kodeck for his code contributions).

#ifndef CBUTTON_H_
#define CBUTTON_H_

#if defined(ARDUINO) && ARDUINO >= 100
#include <Arduino.h>
#else
#include <WProgram.h>
#endif

#include <Wire.h>
#include <MCP23017.h>


#define PERIOD 5  // ms between status checks
#define NCHECKS 2 // how many raw reads until switch is considered stable

class cButtonBase {
public:
  cButtonBase();
  virtual void begin( uint8_t N, uint8_t addr = 0 ) {}; // should be pure virtual
  uint8_t readButtons(); // returns bit = 1 if key has changed since last debounce
  boolean keyPressed( uint8_t key );
  boolean keyChanged( uint8_t key );
  boolean anyPressed(); // true if any button is pressed

protected:
  virtual uint8_t rawRead(){ return 0; } // should be pure virtual
  void debounce();
  uint8_t n; // size of button array
  uint8_t bits;
  uint8_t mask;
  uint32_t nextCheck;
  uint8_t state[NCHECKS]; // circular buffer holding series of key states
  uint8_t sidx; // index into the state buffer
  uint8_t stable; // 1 bit per switch; bit = 1 if switch is stable
  uint8_t changed; // 1 bit per switch; bit = 1 if switch changed
};

class cButtonPE16 : public cButtonBase {
public:
   virtual void begin( uint8_t N, uint8_t addr = MCP23_ADDR ); // n = number active buttons (8 max)
   virtual void ledOn( uint8_t n ){ ledUpdate( LEDstate | ( 1 << n ) ); }
   virtual void ledOff( uint8_t n ){ ledUpdate( LEDstate & (~(1 << n)) );}
   virtual void ledAllOff(){ ledUpdate( 0 ); }
   virtual void ledAllOn(){ ledUpdate( 0x07 ); }
   virtual void ledUpdate( uint8_t b3 );
protected:
   virtual uint8_t rawRead(); // returns 8 input bits from port expander
   uint8_t PEaddr;
   uint8_t LEDstate;
};

#endif /* CBUTTON_H_ */
