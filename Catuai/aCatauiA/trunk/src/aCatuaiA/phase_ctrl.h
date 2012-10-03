// phase_ctrl.h
//
// Connect zero cross detector to D3 (logic low indicates zero cross) ONCE per cycle only
// Simple resistor + diode + opto pulling down INT_PIN pullup is sufficient

// Digital phase angle control on OT2(12) - connect to opto triac driver

// Integral cycle control on OT1(11).
// Connect OT1 to opto triac driver.  Suitable for heater control.

// Both outputs suitable to drive random fire SSRs

// created September 2012

// *** BSD License ***
// ------------------------------------------------------------------------------------------
// Copyright (c) 2012, Osiris Technology Pty Ltd
// All rights reserved.
//
// Contributor:  Eric Mills, Jim Gallt
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

#ifndef _phase_ctrl_h
#define _phase_ctrl_h

#include <Arduino.h>

#define ZC_LAG 1200	// Zero cross signal lags the actual crossing by < 600us
			// This may interfere with the 99.5% fan setting (not used)
			// Increase if PAC flashes full cycles due to running over ZC

#define ICC_MAX 100	// Must be < 128 (signed char)
#define PAC_MAX 200	// Hard coded in lookup array size

void init_phase_ctrl();
void output_level_icc(uint8_t icc_level);	// Set ICC output level, 0 to ICC_MAX
void output_level_pac(uint8_t pac_level);	// Set PAC output level, 0 to PAC_MAX 

#endif
