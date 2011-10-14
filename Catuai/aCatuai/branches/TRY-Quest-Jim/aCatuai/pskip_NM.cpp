// pskip_NM.cpp

// Period skipping (a.k.a. integral cycle control) method of AC
// control using zero crossing SSR's.  Most suitable for control
// of resistive loads, like heaters.
// inspired by post on arduino.cc forum by jwatte on 10-12-2011 -- Thanks!

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

// version 1.00  12-Oct-2011

#include <WProgram.h>
#include "pskip_NM.h"

uint16_t outport;

// for N:M quantization
int16_t ratioN;
volatile boolean newN = true;
volatile int16_t curr;

#ifdef INTERNAL_ZCD
// set up the timer to created zero cross interrupts
void setupTimer1( uint16_t zero_cross_count ) {
  TIMSK1 = 0; // disable all interrupts 
  // timer 1:  CTC mode 4, no output pins, clk/8 prescale (1 count = 0.5 usec)
  TCCR1A =  0;
  TCCR1B = _BV(TCCR1B_WGM12) | _BV(TCCR1B_CS11);
  TCCR1C = 0;
  OCR1A = zero_cross_count; // initialize output compare register A to track line frequency
  TIMSK1 = _BV(TIMSK1_OCIE1A); // enable interrupt on output compare A match
  TCNT1 = 0; // set the timer to zero
}
#endif

#ifdef EXTERNAL_ZCD
void RTC() { // use this version for externally generated interrupts
#else ifdef INTERNAL_ZCD
ISR( TIMER1_COMPA_vect ) { // this version creates timer interrupts at line frequency
#endif
  uint8_t state; // pin high or low
  if( newN ) {
    curr = -( ratioN + RATIO_M ) / 2; // restart sequence
    newN = false;
  }
  curr += ratioN;
  if( curr >= 0 ) {
    curr -= RATIO_M;
    state = HIGH;
  }
  else
    state = LOW;
  digitalWrite( outport, state );
  #ifdef DEBUG_PSKIP
  digitalWrite( DEBUG_PIN, state );
  #endif
} // return from interrupt routine

// initialize output port
void init_pskip( uint16_t ot ) {
  ps_output_level( 0 );
  outport = ot;
  pinMode( outport, OUTPUT );
  #ifdef DEBUG_PSKIP
  pinMode( DEBUG_PIN, OUTPUT ); // debugging code
  #endif
}

// call this to set output level, 0 to 100 
void ps_output_level( uint8_t ps_level ) {
  ratioN = ps_level;
  newN = true;  // tell the interrupt routine to restart sequence
}

