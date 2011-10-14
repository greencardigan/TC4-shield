// pskip_NM.h

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
// uses N:M quantization

#ifndef _pskip_NM_h
#define _pskip_NM_h

#define RATIO_M 100 // resolution of quantization of output levels

#include <avr/pgmspace.h>
#include "timer1defs.h"
#include "user.h"

#ifdef INTERNAL_ZCD // set up counters to match line frequency
  #ifdef FREQ_60
    //#define ZERO_CROSS_COUNT 16625
    #define ZERO_CROSS_COUNT 16667
  #else ifdef FREQ_50
    //#define ZERO_CROSS_COUNT 19950
    #define ZERO_CROSS_COUNT 20000
  #endif
#endif

#ifdef INTERNAL_ZCD
void setupTimer1( uint16_t zero_cross_count ); // call once to initialize timer
#endif

#ifdef EXTERNAL_ZCD
void RTC();
#endif

void ps_output_level( uint8_t ps_level ); // call this to set output level, 0 to 255 
void init_pskip( uint16_t ot );

#endif

