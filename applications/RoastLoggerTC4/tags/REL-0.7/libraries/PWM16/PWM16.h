// Timer1 and timer2 PWM control
// Version date: November 30, 2011
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

// ----------------------------------------------------------------------------
// Fast PWM mode on timer 1
//
// compare output mode, fast PWM mode, TCCR1A register
// COM1A1/COM1B1     COM1A0/COM1B0
//       0                 0          Normal port operation; OC1A/OC1B disconnected
//       0                 1          WGM13:0 = 14 or 15:  toggle OC1A on compare match,
//                                    OC1B disconnected (normal port operation)
//                                    For all other WGM13:0 settings, normal port, OC1A/B disconnected
//       1                 0          non-inverting mode
//       1                 1          inverting mode

// waveform generation mode settings, TCCR1A and TCCR1B registers
// register         TCCR1B           TCCR1A
//   mode      WGM13    WGM12    WGM11   WGM10    MODE                          TOP
//    0          0        0        0       0      Normal port                   0xFFFF
//    1          0        0        0       1      PWM phase correct 8-bit       0x00FF  255
//    2          0        0        1       0      PWM phase correct 9-bit       0x01FF  511
//    3          0        0        1       1      PWM phase correct 10-bit      0x03FF 1023
//    5          0        1        0       1      Fast PWM, 8-bit               0x00FF  255
//    6          0        1        1       0      Fast PWM, 9-bit               0x01FF  511
//    7          0        1        1       1      Fast PWM, 10-bit              0x03FF 1023
//   14          1        1        1       0      Fast PWM                      ICR1  
//   15          1        1        1       1      Fast PWM                      OCR1A


// prescale settings, TCCR1B register
// CS12      CS11       CS10
//   0         0          0       No clock source (Timer/Counter stopped)
//   0         0          1       N = 1
//   0         1          0       N = 8
//   0         1          1       N = 64
//   1         0          0       N = 256
//   1         0          1       N = 1024

// set prescale to N = 1024
//
// f = 16,000,000 / [ 1024 * ( 1 + TOP ) ] for fast PWM mode
// TOP  in ICR1      f
// 127   0x007F  122.070 Hz 
// 255   0x00FF   61.035 Hz 
// 511   0x01FF   30.518 Hz
// 1023  0x03FF   15.259 Hz
// 2047  0x07FF    7.629 Hz 
// 4095  0x0FFF    3.815 Hz
// 8191  0x1FFF    1.907 Hz
// 16383 0x3FFF    0.954 Hz  approx. 1 sec period
// 32767 0x7FFF    0.477 Hz  approx. 2 sec period
// 65535 0xFFFF    0.238 Hz  approx. 4 sec period
//
// My preferred settings for heater control application
//
// TCCR1A    1   0   1   0   x    x    1    0   non inverting, fast PWM, TOP in ICR1
// TCCR1B    x   x   x   1   1    1    0    1   fast PWM, TOP in ICR1, N = 1024
//
// ------------------------------------------------------------------------------

#ifndef PWM16_h
#define PWM16_h

#if defined(ARDUINO) && ARDUINO >= 100
#include <Arduino.h>
#else
#include <WProgram.h>
#endif

// values below courtesy of Bhante (BM)
// TOP values for various frequencies
// f = 16,000,000 / [ 1024 * ( 1 + TOP ) ] for fast PWM mode
#define pwmN128Hz 121  // 128.074 Hz
#define pwmN64Hz 243   // 64.037 Hz
#define pwmN60Hz 259   // 60.096 Hz
#define pwmN50Hz 312   // 49.920 Hz (BM)
#define pwmN32Hz 487   // 32.018 Hz
#define pwmN30Hz 520   // 29.990 Hz
#define pwmN25Hz 624   // 25.000 Hz (BM)
#define pwmN20Hz 780   // 20.006 Hz (BM)
#define pwmN16Hz 976   // 15.993 Hz (BM)
#define pwmN10Hz 1562  // 9.9968 Hz (BM)
#define pwmN8Hz 1952   // 8.0005 Hz
#define pwmN5Hz 3124   // 5.0000 Hz (BM)
#define pwmN4Hz 3905   // 4.0003 Hz
#define pwmN2Hz 7812   // 1.9999 Hz
#define pwmN1Hz 15624  // 1.0000 Hz
#define pwmN1sec 15624 // 1.0000 sec
#define pwmN2sec 31249 // 2.0000 sec
#define pwmN4sec 62499 // 4.0000 sec

#define pwmOff   0       // zero period effectively turns off timer
#define pwmDutyMax  100  // maximum duty cycle is 100%
#define pwmDutyError  0  // in case requested duty > 100
                         // change to 100 if safe for your application

#define pwmOutA 9   // pin 9
#define pwmOutB 10  // pin 10

// ---------------------------------------------------
// Class definition for 16-bit counter on timer 1

class PWM16 {
  public:
    PWM16();
    void Setup( unsigned int pwmF );  // pwmF = TOP value for desired frequency
    void Reset();  // restores timer1 to Arduino defaults
    void Out( unsigned int dutyA, unsigned int dutyB );  // set duty cycle for PWM output on 
                                                         // channels A and B
                                                         // duty = 0 to 100
    unsigned int GetTOP(); // returns TOP value for counter
  private:
    unsigned int _pwmF;

};

// definitions for PWM frequency selection on IO3

#define IO3_PIN 3 // pin DIO3 for IO3

#define IO3_FASTPWM _BV(COM2A1) | _BV(COM2B1) | _BV(WGM21) | _BV(WGM20) // fast PWM
#define IO3_PCORPWM _BV(COM2A1) | _BV(COM2B1) | _BV(WGM20) // phase correct PWM

// BOTTOM to TOP 00 to TOP, setting TOP value in OCR2A:
#define IO3_FASTPWM_TOP _BV(COM2A0) | _BV(COM2B1) | _BV(WGM21) | _BV(WGM20) // fast PWM
#define IO3_PCORPWM_TOP _BV(COM2A0) | _BV(COM2B1) | _BV(WGM20) // phase correct PWM

#define IO3_PRESCALE_1 _BV(CS20) // 0x01, divide by 1
#define IO3_PRESCALE_8 _BV(CS21) // 0x02, divide by 8
#define IO3_PRESCALE_32 _BV(CS21) | _BV(CS20) // 0x03, divide by 32
#define IO3_PRESCALE_64 _BV(CS22) // 0x04, divide by 64
#define IO3_PRESCALE_128 _BV(CS22) | _BV(CS20) // 0x05, divide by 128
#define IO3_PRESCALE_256 _BV(CS22) | _BV(CS21) // 0x06, divide by 256
#define IO3_PRESCALE_1024 _BV(CS22) | _BV(CS21) | _BV(CS20) // 0x07, divide by 1024

class PWM_IO3 {
  public:
    void Setup( uint8_t pwm = IO3_FASTPWM, uint8_t prescale = IO3_PRESCALE_1024 );
    void Out( uint8_t duty );
  private:
    uint8_t _prescale;
    uint8_t _pwm_mode;
};

// void setupIO3( uint8_t pwm = IO3_FASTPWM, uint8_t prescale = IO3_PRESCALE_1024 );

/*
PWM Frequencies

fast = 16,000,000 / prescale / 256
pcor = 16,000,000 / prescale / 2 / 255

Mode        Prescale              Frequency
----        --------              --------- 
fast            1                  62.5kHz
fast            8                  7.8125kHz
fast           32                  1.953125kHz
fast           64                  976.5625Hz
fast          128                  488.28125Hz
fast          256                  244.140625Hz
fast         1024                  61.03515625Hz (PWM16 library default)

pcor            1                  31.37kHz
pcor            8                  3.922kHz
pcor           32                  980.4Hz
pcor           64                  490.2Hz (arduino default)
pcor          128                  245.1Hz
pcor          256                  122.5Hz
pcor         1024                  30.64Hz

*/

#endif
