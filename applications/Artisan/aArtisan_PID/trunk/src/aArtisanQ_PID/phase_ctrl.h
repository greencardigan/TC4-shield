// phase_ctrl.h
//
// Digital phase angle control on OT2 (random fire SSR drive)
// Connect zero cross detector to D3 (logic low indicates zero cross)
// Connect OT2 to random fire SSR
//
// ICC control on OT1.  Connect standard zero cross SSR to OT1.
// Period skipping (a.k.a. integral cycle control) method of AC
// control using zero crossing SSR's.  Most suitable for control
// of resistive loads, like heaters.
// Uses modified Bresenham algorithm (N in M) for ICC control.
// inspired by post on arduino.cc forum by jwatte on 10-12-2011 -- Thanks!

// created 14-October-2011

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

// July 1, 2012 -- Arduino 1.0 compatibility added by Jim Gallt

#ifndef _phase_ctrl_h
#define _phase_ctrl_h

#if defined(ARDUINO) && ARDUINO >= 100
#include <Arduino.h>
#else
#include <WProgram.h>
#endif

#include "user.h"

#ifdef PHASE_ANGLE_CONTROL

#include "timer1defs.h"

// define the pulse width for firing TRIAC (phase angle control)
#define TRIAC_PULSE_WIDTH 1000 // 500 uS default
#ifdef TRIAC_MOTOR
 #undef TRIAC_PULSE_WIDTH
 #define TRIAC_PULSE_WIDTH 4000 // 2000 uS needed for popper motor -- why?
#else //ifdef TRIAC_HEATER
 #undef TRIAC_PULSE_WIDTH
 #define TRIAC_PULSE_WIDTH 1000 // 500 uS works for heaters
#endif

#define ZC_LEAD 1000 // zero cross signal leads the actual crossing by approx 500us

#define AC_TIMEOUT_MS 100 // 0.1 second

// for integral cycle control
#define RATIO_M 100 // resolution of quantization of output levels

// call when output levels need to change
void output_level_icc( uint8_t icc_level ); // call this to set output level, 0 to 100
void output_level_pac( uint8_t pac_level ); // call this to set output level, 0 to 100 

// call to initialize integral cycle control
void init_control();

void setupTimer1();

// called at each zero cross by interrupt handler
void ISR_ZCD();

// detects the presence of AC
boolean ACdetect();

#endif // PHASE_ANGLE_CONTROL
#endif //_phase_ctrl_h

