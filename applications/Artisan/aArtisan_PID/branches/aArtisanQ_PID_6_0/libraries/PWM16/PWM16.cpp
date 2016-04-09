// Timer1 and timer2 PWM control
// Version date: July 22, 2011
// Revision history:
//  20120126: Arduino 1.0 compatibility

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

#include "PWM16.h"

//--------------------------------------------------------
// Constructor

PWM16::PWM16() {
  _pwmF = 0;
}

//--------------------------------------------------------
// Set up frequency / period and timer control registers
// pwmF = fixed time base frequency value
// This method must be called before using timer.  For some reason
// the initialization code does not work in the constructor.  fixme

void PWM16::Setup( unsigned int pwmF ) {
  _pwmF = pwmF;
  noInterrupts();
  // non inverting, fast PWM, TOP is in ICR1
  TCCR1A = _BV(COM1A1) | _BV(COM1B1) | _BV(WGM11); 
  // fast PWM, TOP in ICR1, prescale N = 1024
  TCCR1B = _BV(WGM13) | _BV(WGM12) | _BV(CS12) | _BV(CS10);
  ICR1 = _pwmF;
  interrupts();
}

//---------------------------------------------------------------
// Reset timer1 to its default state

void PWM16::Reset() {

  // first, disable timer1
  noInterrupts();
  TCCR1A = 0; 
  TCCR1B = 0; 
  interrupts();

  // next, reset timer1 to default values
  noInterrupts();
  TCCR1A = _BV(WGM10);             // 8-bit PWM, phase correct
  TCCR1B = _BV(CS11) | _BV(CS10);  // prescale = 64
  interrupts();
}

//--------------------------------------------------------------------------
// pwmF = fixed time base frequency value
// dutyA, dutyB = duty cycles, in percent
// dutyA = 0 and dutyB = 0 turns off timer 1
//

void PWM16::Out( unsigned int dutyA, unsigned int dutyB ){

  unsigned long nn;
  unsigned int nA;
  unsigned int nB;
  unsigned long pwmN1;

  // trap logic errors safely
  if( dutyA > pwmDutyMax ) dutyA = pwmDutyError;
  if( dutyB > pwmDutyMax ) dutyB = pwmDutyError;
  
  // special case: force no output for zero duty cycle
  // otherwise will get 1 clock cycle ON in most modes
  if( dutyA != 0 ) pinMode( pwmOutA, OUTPUT ); else pinMode( pwmOutA, INPUT );
  if( dutyB != 0 ) pinMode( pwmOutB, OUTPUT ); else pinMode( pwmOutB, INPUT );

  // change timer registers only if there is something to do
  if( dutyA != 0 || dutyB != 0 ) {
    pwmN1 = _pwmF + 1;
    nn = dutyA;  nn *= pwmN1 ; nn /= 100; nA = nn;
    nn = dutyB;  nn *= pwmN1 ; nn /= 100; nB = nn;
    OCR1A = nA;      // double buffered registers
    OCR1B = nB;      // change effective only after TCNT1 next reaches TOP
  }
}

// -------------------------------------------------------------------------
// returns TOP value for counter

unsigned int PWM16::GetTOP () {
  return _pwmF;
}

// ------------------------------------------- PWM_IO3 methods

// setup timer parameters
void PWM_IO3::Setup( uint8_t pwm_mode, uint8_t prescale ) {
  pinMode( IO3_PIN, OUTPUT );
  _pwm_mode = pwm_mode;
  _prescale = prescale;
  TCCR2A = _pwm_mode;
  TCCR2B = _prescale;  
}

// output
void PWM_IO3::Out( uint8_t duty ) {
  analogWrite( IO3_PIN, duty );
}

