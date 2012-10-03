// phase_ctrl.cpp

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
// Contributors: Eric Mills, Jim Galt
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

#include <avr/io.h>
#include "phase_ctrl.h"
#include "user.h"

#define OT_ICC	11	// Pin 11 is OC1A, hard wired below in the code
#define OT_PAC	12	// Pin 12 is OC1B, hard wired below in the code

static uint8_t pacOutput;	// Output level, 0 to PAC_MAX, for phase angle control
static int8_t iccOutput;	// ICC output level, 0 to ICC_MAX

// Lookup table (index = rounded 1/2% output, 0 to 100)
// Based on 0.5 uS per count (sysclk prescale 8)
// Table entries are solution to: pi*x - sin(pi*x)cos(pi*x) = pi*y for y:1.0->0.5 in steps of 0.005
// then table entry = x*TOP [power = integral sin^2(x)]
#if MAINS_FREQ == 60
#define TOP 16667		// Half cycle time in counter timer 1 (8.3ms)
static const uint16_t phase_delay[PAC_MAX / 2 + 1] PROGMEM = {
 16667,  15137,  14733,  14447,  14218,  14022,  13851,  13696,  13554,  13423, 
 13301,  13186,  13076,  12973,  12874,  12779,  12687,  12599,  12514,  12432, 
 12352,  12274,  12198,  12124,  12052,  11981,  11912,  11845,  11778,  11713, 
 11649,  11587,  11525,  11464,  11404,  11345,  11287,  11229,  11173,  11117, 
 11061,  11007,  10953,  10899,  10846,  10794,  10742,  10691,  10640,  10590, 
 10540,  10490,  10441,  10392,  10343,  10295,  10248,  10200,  10153,  10106, 
 10060,  10013,   9967,   9922,   9876,   9831,   9786,   9741,   9696,   9652, 
  9608,   9563,   9520,   9476,   9432,   9389,   9346,   9302,   9259,   9216, 
  9174,   9131,   9088,   9046,   9004,   8961,   8919,   8877,   8835,   8793, 
  8751,   8709,   8667,   8625,   8584,   8542,   8500,   8458,   8417,   8375, 
  8333 
};
#elif MAINS_FREQ == 50
#define TOP 20000		// Half cycle time in counter timer 1 (10ms)
static const uint16_t phase_delay[(PAC_MAX / 2) + 1] PROGMEM = {
 20000,  18165,  17680,  17337,  17061,  16827,  16621,  16435,  16265,  16108, 
 15961,  15823,  15692,  15567,  15448,  15334,  15225,  15119,  15017,  14918, 
 14822,  14728,  14638,  14549,  14462,  14378,  14295,  14214,  14134,  14056, 
 13979,  13904,  13830,  13757,  13685,  13614,  13544,  13475,  13407,  13340, 
 13274,  13208,  13143,  13079,  13016,  12953,  12891,  12829,  12768,  12707, 
 12647,  12588,  12529,  12470,  12412,  12354,  12297,  12240,  12184,  12127, 
 12072,  12016,  11961,  11906,  11851,  11797,  11743,  11689,  11636,  11582, 
 11529,  11476,  11423,  11371,  11319,  11267,  11215,  11163,  11111,  11060, 
 11008,  10957,  10906,  10855,  10804,  10754,  10703,  10652,  10602,  10551, 
 10501,  10451,  10401,  10350,  10300,  10250,  10200,  10150,  10100,  10050, 
 10000 
};
#endif

// ISR for external zero cross detect - once per cycle only, falling edge
#if EXT_INT == 4			// ATmega2560 pin 2
ISR(INT4_vect) {
#elif EXT_INT == 1			// Uno pin 3
ISR(INT1_vect) {
#else
ISR(INT0_vect) {			// Uno pin 2
#endif
    static int8_t rem;			// Partial cycle carry forward
    TCNT1 = ZC_LAG;			// Sync counter to external mains, during first 1% time window (99% power)

    // Mirror about centre of 1/2 cycle, write thru on next counter reset
    OCR1B = pacOutput <= PAC_MAX / 2 ? pgm_read_word(&phase_delay[pacOutput])
				     : TOP - pgm_read_word(&phase_delay[PAC_MAX - pacOutput]);

    rem += iccOutput;
    if(rem > 0) {			// Whole cycle accumulated to be output
	rem -= ICC_MAX;
	OCR1A = 0;			// Turn on for whole next cycle, buffered write in timer1
    }
    else
	OCR1A = TOP;			// Stay off next whole cycle
    bitClear(EIMSK, EXT_INT);		// Disable this interrupt - debounce
}

// Check the INT pin and enable falling interrupt only if it is already HIGH mid cycle
ISR(TIMER1_COMPC_vect) {
    if (digitalRead(INT_PIN) == HIGH) {
	EIFR = 1 << EXT_INT;		// Clear any latched falling edge
	bitSet(EIMSK, EXT_INT);		// Enable above interrupt
    }
}

// Initialize ICC and PAC control using timer 1 all channels
void init_phase_ctrl() {
    pinMode(INT_PIN, INPUT);		// Enable input on the interrupt pin
    digitalWrite(INT_PIN, HIGH); 	// Enable internal pullup on the int pin
#if EXT_INT > 3
    EICRB |= 2 << ((EXT_INT - 4) << 1);	// Interrupt on falling edge, leave disabled
#else
    EICRA |= 2 << (EXT_INT << 1);	// Interrupt on falling edge, leave disabled
#endif

    // Timer1 is used for phase delay and ICC direct drive
    // It is freewheeling at 2x mains frequency, synchronised by ZCD interrupt
    TCCR1A = 0xf2;			// Inverting output (match=>HIGH) fast PWM channel A & B
    TCCR1B = 0x1a;			// Fast PWM with ICR1 TOP & prescaler to clk/8 (1 count = 0.5 uS)
    ICR1 = TOP;				// TOP set to half cycle time
    OCR1A = TOP;			// Turns off output OT_ICC
    OCR1B = TOP;			// Turns off output OT_PAC
    OCR1C = 3 * (TOP / 4);		// Generate interrupt later in 1/2 cycle to debounce EXT_INT
    delay(12);				// Wait for timer1 to wrap & set output pins low before output enable
    pinMode(OT_ICC, OUTPUT);
    pinMode(OT_PAC, OUTPUT);
    TIMSK1 = 1 << OCIE1C;		// Enable timer C match interupt, only interrupt this timer
}

// Set phase angle control output levels, 0 to 200 
void output_level_pac( uint8_t pac_level ) {
    pacOutput = pac_level <= PAC_MAX ? pac_level : PAC_MAX;
}

// Set integral cycle control output levels, 0 to 100 
void output_level_icc( uint8_t icc_level ) {
    iccOutput = icc_level <= ICC_MAX ? icc_level : ICC_MAX;
}
