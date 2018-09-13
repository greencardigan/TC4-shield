// phase_ctrl.cpp
//
// Digital phase angle control on OT2 (SSR drive)
// Connect zero cross detector to D3 (logic low indicates zero cross)
// Connect OT2 to random fire SSR for small motor control.

// ICC (modified Bresenham) control on OT1.
// Connect OT1 to standard SSR.  Suitable for heater control.

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

#include "phase_ctrl.h"

#ifdef PHASE_ANGLE_CONTROL

extern int levelOT1;
extern int levelOT2;
//#ifndef PHASE_ANGLE_CONTROL
extern int levelIO3;
//#endif

// for phase angle control
enum output_state {delaying, pulse_on, disabled};
volatile output_state triac_state = disabled;
uint8_t pac_output; // output level, 0 to 100, for phase angle control

// for N:M quantization used by ICC control
int8_t ratioN; // ICC output level, 0 to 100
volatile boolean newN = true; // singles that output level has changed
volatile int8_t curr; // current value in N:M sequence
volatile uint32_t lastCross = 0;  // timer0 value at most recent zero cross
volatile boolean outputEnable = false;

// lookup table (index = rounded % output, 0 to 100)
// based on 0.5 uS per count
// FIXME: put this in PROGMEM
#ifdef FREQ60
uint16_t phase_delay[101] = { // 60Hz values based on linearizing power output
	/* 0      1      2      3      4      5      6     7      8       9 */
/* 00 */ 16667, 14733, 14218, 13851, 13554, 13301, 13076, 12874, 12687, 12514,
/* 10 */ 12352, 12198, 12052, 11912, 11778, 11649, 11525, 11404, 11287, 11173,
/* 20 */ 11061, 10953, 10846, 10742, 10640, 10540, 10441, 10343, 10248, 10153,
/* 30 */ 10060,  9967,  9876,  9786,  9696,  9608, 9520,  9432,  9346,  9259,
/* 40 */  9174,  9088,  9004,  8919,  8835,  8751, 8667,  8584,  8500,  8417,
/* 50 */  8333,  8250,  8167,  8083,  8000,  7916, 7832,  7748,  7663,  7578,
/* 60 */  7493,  7407,  7321,  7234,  7147,  7059, 6970,  6881,  6791,  6699,
/* 70 */  6607,  6514,  6419,  6323,  6226,  6127, 6027,  5924,  5820,  5714,
/* 80 */  5605,  5494,  5380,  5263,  5142,  5017, 4888,  4754,  4615,  4469,
/* 90 */  4315,  4153,  3979,  3793,  3590,  3366, 3113,  2816,  2449,  1933,
/* 100 */ 0	
};
#else //ifdef FREQ50
uint16_t phase_delay[101] = { // 50Hz values based on linearizing power output
	/* 0      1      2      3      4      5      6     7      8       9 */
/* 00 */ 20000, 17680, 17061, 16621, 16265, 15961, 15692, 15448, 15225, 15017,
/* 10 */ 14822, 14638, 14462, 14295, 14134, 13979, 13830, 13685, 13544, 13407,
/* 20 */ 13274, 13143, 13016, 12891, 12768, 12647, 12529, 12412, 12297, 12184,
/* 30 */ 12072, 11961, 11851, 11743, 11636, 11529, 11423, 11319, 11215, 11111,
/* 40 */ 11008, 10906, 10804, 10703, 10602, 10501, 10401, 10300, 10200, 10100,
/* 50 */ 10000,  9900,  9800,  9700,  9599,  9499,  9398,  9297,  9196,  9094,
/* 60 */  8992,  8889,  8785,  8681,  8577,  8471,  8364,  8257,  8149,  8039,
/* 70 */  7928,  7816,  7703,  7588,  7471,  7353,  7232,  7109,  6984,  6857,
/* 80 */  6726,  6593,  6456,  6315,  6170,  6021,  5866,  5705,  5538,  5362,
/* 90 */  5178,  4983,  4775,  4552,  4308,  4039,  3735,  3379,  2939,  2320,
/* 100 */ 0	
};
#endif

// timer1 is used for both phase delay and for TRIAC pulse width timing
void setupTimer1() {
  TIMSK1 = 0; // disable all interrupts 
  TCCR1A =  0; // put timer1 in normal mode; output pins under sketch control
  TCCR1B = _BV(TCCR1B_CS11); // set prescaler to clk/8 (1 count = 0.5 uS)
  OCR1A = 0xFFFF; // initialize output compare register A to max value
  TIMSK1 = _BV(TIMSK1_OCIE1A); // enable interrupt on output compare A match
  TCNT1 = 0; // set the timer to zero
}

// ------------------------- ISR for external zero cross detect
void ISR_ZCD() {
  TCNT1 = 0;  // reset timer1 counter
  // perform AC monitoring
  lastCross = millis(); // timer0
  // first, handle the phase angle control output
  triac_state = delaying;
  if( outputEnable )
    digitalWrite( OT_PAC, LOW ); // force output off
  // set output compare register A for delay time
  OCR1A = phase_delay[pac_output] + uint16_t(ZC_LEAD);
  
  // next, handle the integral cycle control output using modified Bresenham's algorithm
  // (inspired by post on arduino.cc forum by jwatte on 10-12-2011 -- Thanks!)
  if( newN ) {
    // restart sequence if new output level    
    curr = int8_t ( - ( int16_t( int16_t(ratioN) + int16_t(RATIO_M) ) ) / 2 );
    newN = false;
  }
  curr += ratioN;
  if( curr >= 0 ) {
    curr -= RATIO_M;
    if( outputEnable ) 
      digitalWrite( OT_ICC, HIGH );
  }
  else {
    digitalWrite( OT_ICC, LOW );
  }
}

// ------------------------ ISR for comparator A match
ISR( TIMER1_COMPA_vect ) { // this gets called every time there is a match on A
  // if triac output is delaying, then
  if( triac_state == delaying ) {  
    triac_state = pulse_on; // indicate output pulse is active
    if( outputEnable )
      digitalWrite( OT_PAC, HIGH );
    TCNT1 = 0; // reset timer count
    OCR1A = TRIAC_PULSE_WIDTH; // start counting for pulse
  }
  else if( triac_state == pulse_on ){  // if triac output is on, turn it off because pulse is done
    triac_state = disabled;
    digitalWrite( OT_PAC, LOW );
    TCNT1 = 0;  // reset timer count
    OCR1A = 0xFFFF; // keep triac output off until next zero cross
  }
}

// initialize ICC and PAC control
void init_control() {
  output_level_icc( 0 );
  output_level_pac( 0 );
  pinMode( OT_ICC, OUTPUT );
  pinMode( OT_PAC, OUTPUT );
  pinMode( INT_PIN, INPUT ); // enable input on the interrupt pin
  digitalWrite( INT_PIN, HIGH );  // enable internal pullup on the int pin
  triac_state = disabled;
  setupTimer1();
  attachInterrupt( EXT_INT, ISR_ZCD, FALLING );
}

// call this to set phase angle control output levels, 0 to 100 
void output_level_pac( uint8_t pac_level ) {
  ///if( pac_level < HTR_CUTOFF_FAN_VAL ) { // if new levelOT2 < cutoff value then turn off OT1
  ///  output_level_icc( 0 );
 ///}
 ///else {  // turn OT1 back on again if levelOT2 is above cutoff value. Might be a better way to handle this??
    ///output_level_icc( levelOT1 );    
  ///}
  if( pac_level > 100 ) // trap error condition
    pac_output = 0;
  else
    pac_output = pac_level;
}

// call this to set integral cycle control output levels, 0 to 100 
void output_level_icc( uint8_t icc_level ) {
  //if( FAN_DUTY < HTR_CUTOFF_FAN_VAL ) icc_level = 0;
  if( icc_level > 100 )
    ratioN = 0;
  else
    ratioN = icc_level;
  newN = true;  // tell the interrupt routine to restart sequence
}

// detects the presence of AC
boolean ACdetect() {
  return outputEnable = ! ( ( millis() - lastCross ) > AC_TIMEOUT_MS ) ;
}

#endif //PHASE_ANGLE_CONTROL
