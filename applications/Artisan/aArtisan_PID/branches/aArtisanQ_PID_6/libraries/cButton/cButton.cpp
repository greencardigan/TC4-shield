/*
 * cButton.cpp
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
//  20150224:  Changed function result to boolean for anyPressed().
//             Needed for compatibility with Arduino 1.60

#include "cButton.h"

#if defined(ARDUINO) && ARDUINO >= 100
#define _READ read
#define _WRITE write
#else
#define _READ receive
#define _WRITE send
#endif

// ------------------------------------------ base class methods
cButtonBase::cButtonBase() {
  n = 0;
  bits = 0;
}

boolean cButtonBase::keyPressed( uint8_t key ) {
  return ( stable ) & ( 1 << key );
}

boolean cButtonBase::keyChanged( uint8_t key ) {
  return ( changed ) & ( 1 << key );
}

uint8_t cButtonBase::readButtons() {
  uint32_t ms = millis();
  if( ms >= nextCheck ) {
    debounce();
    nextCheck = ms + PERIOD;
    return changed;
  }
  else return 0;  // if a new value was not read, than nothing can change
}

boolean cButtonBase::anyPressed() {
  return !( stable == 0 );
}

// ------------------debounce code from www.ganssle.com/debouncing-pt2.htm
// ------------------debounces 8 switches at once (leading edge only)
// call this every PERIOD
void cButtonBase::debounce() {
  uint8_t i, j;
  uint8_t prevstable = stable;
  state[sidx++] = rawRead();
  j = 0xFF; // all ones
  for( i = 0; i < NCHECKS; i++ )
    j &= state[i];
// on exit from loop, a j bit will be 1 only if all NCHECK readings are 1
  stable = j; // if switch press is stable, bit = 1
  changed = j ^ prevstable; // XOR j with the previous stable to pick up changes
  if( sidx >= NCHECKS )
    sidx = 0; // circular buffer
}

// ----------------------------------------------------- MCP23017 port expander
void cButtonPE16::begin( uint8_t N, uint8_t addr ) {
// need to know how many active buttons so we can mask off the unused
  n = max(N,4);
  mask = ( 1 << n ) - 1; // for the buttons
  nextCheck = millis() + PERIOD;
  sidx = 0;

  // configure the port expander
  PEaddr = addr;
  Wire.beginTransmission( PEaddr );
  Wire._WRITE( IOCONZ );  // valid command only if BANK = 0, which is true upon reset
  Wire._WRITE( BANK ); // set BANK = 1 if it had been 0 (nothing happens if BANK = 1 already)
  Wire.endTransmission();

  // now, send our IO control byte with assurance BANK = 1
  Wire.beginTransmission( PEaddr );
  Wire._WRITE( IOCON );
  Wire._WRITE( BANK | SEQOP | DISSLW ); //  banked operation, non-sequential addressing
  Wire.endTransmission();

  // now, set up port B pins for input
  Wire.beginTransmission( PEaddr );
  Wire._WRITE( IODIRB );
  Wire._WRITE( 0x0F ); // configure port B pins:  input 0-3, output 4-7
  Wire.endTransmission();

  // reverse the polarity (so that 0 = not pressed, 1 = pressed)
  Wire.beginTransmission( PEaddr );
  Wire._WRITE( IPOLB );
  Wire._WRITE( 0x0F ); // configure port B polarity: reversed 0-3, normal 4-7
  Wire.endTransmission();

  ledAllOff(); // all LED's off by default
}

// ------------------------------------------
uint8_t cButtonPE16::rawRead() {
  Wire.beginTransmission( PEaddr );
  Wire._WRITE( GPIOB );
  Wire.endTransmission();
  Wire.requestFrom( PEaddr, (uint8_t) 1 );
  bits = Wire._READ() & mask;  // mask off the unused bits
  return bits;
};

// ----------------------------------------------
void cButtonPE16::ledUpdate( uint8_t b3) {
  LEDstate = b3;
  Wire.beginTransmission( PEaddr );
  Wire._WRITE( GPIOB );
  Wire._WRITE( (uint8_t)(LEDstate << 4) );
  Wire.endTransmission();
}

#undef _READ
#undef _WRITE

// ***********************************************************************************
