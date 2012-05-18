// basic_HID.h

// universal user interface for TC4 applications
// display and control features require LCDapter

// *** BSD License ***
// ------------------------------------------------------------------------------------------
// Copyright (c) 2012, MLG Properties, LLC
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

// Revision history
// 20120512  version 0.0  - created
// 20120513  version 0.1  - alpha version
// 20120518  version 0.2  - beta release

#ifndef _BASIC_HID_H
#define _BASIC_HID_H

#include <cLCD.h>
#include <cButton.h>

#define BTN_HOME 3 // leftmost button
#define BTN_SEL_MODE 2
#define BTN_UP 1
#define BTN_DOWN 0 // rightmost button

#define LED_1 2 // leftmost LED
#define LED_2 1
#define LED_3 0 // rightmost LED

// ----------------- screen positions
#define TIMER_Y 0 // first line
#define TIMER_X 0 // first column
#define TIMER_LEN 5 // 5 characters
#define TIMER_BIT 0 // bit position of flag indicating stale timer value (bit = 1)

#define LEVEL_1_X ( TIMER_X + TIMER_LEN + 1 ) // 1 character padding
#define LEVEL_1_Y 0 // first line
#define LEVEL_1_LEN 4 // 4 characters of data, incl. %
#define LEVEL_1_BIT 1 // bit position of flag indicating stale value (bit = 1)

#define T2_X ( LEVEL_1_X + LEVEL_1_LEN + 1 ) // 1 character padding
#define T2_Y 0 // first line
#define T2_LEN 5 // 2 character label + 3 digits
#define T2_LABEL "E "
#define T2_BIT 2 // bit position of flag indicating stale value (bit = 1)

#define ROR_X 0  // first character
#define ROR_Y 1  // 2nd line
#define ROR_LEN 5
#define ROR_LABEL "RT"
#define ROR_BIT 3 // bit position of flag indicating stale value (bit = 1)

#define LEVEL_2_X ( ROR_X + ROR_LEN + 1 ) // 1 character padding
#define LEVEL_2_Y 1 // 2nd line
#define LEVEL_2_LEN 4 // 4 characters of data, incl. %
#define LEVEL_2_BIT 4 // bit position of flag indicating stale value (bit = 1)

#define T1_X ( LEVEL_2_X + LEVEL_2_LEN + 1 ) // 1 character padding
#define T1_Y 1 // 2nd line
#define T1_LEN 5 // 2 character label + 3 digits
#define T1_LABEL "B "
#define T1_BIT 5 // bit position of flag indicating stale value (bit = 1)

#define CONFIRM_BIT 6 // tells us when to repaint the "confirm reset" display
#define ROW_BIT 7 // which row we are drawing

#define ALL_FIELDS ( (1 << T1_BIT) | (1 << T2_BIT) | (1 << ROR_BIT) | (1 << TIMER_BIT) \
                   | (1 << LEVEL_1_BIT) | (1 << LEVEL_2_BIT) )


// --------------------------
class HIDbase : public cLCD, public cButtonPE16 {
  public:
  void begin( uint8_t LCDcols = 16, uint8_t LCDrows = 2, uint8_t Nbuttons = 4 );
  virtual void refresh( float t1, float t2, float RoR, float time, int8_t pow1, int8_t pow2 );
  inline void setMasterMode(){ HIDstate = running_state; }
  inline void setSlaveMode() { HIDstate = slave_state; }
  boolean processEvents(); // main event handler; returns true if any user changes made
  boolean resetTimer(); // tells caller if timer reset requested
  boolean chgLevel_1(); // tells caller if output level 1 changed
  boolean chgLevel_2(); // tells caller if output level 2 changed
  inline int8_t getLevel_1() { return level_1; } // returns new value for level 1
  inline int8_t getLevel_2() { return level_2; } // returns new value for level 2

  protected:
  virtual void paintLCD(); // causes the display to be repainted 
  void drawTimer();  // first line of display
  void drawLevel_1();
  void drawT2();
  void drawRoR();  // second line of display
  void drawLevel_2();
  void drawT1();
  void drawConfirmReset(); // request user confirmation before resetting timer

  virtual void doButtons(); // take action based on user button presses
  virtual void ledToggle( uint8_t n ){ ledUpdate( LEDstate ^ ( 1 << n ) );}
  void ledFlash( uint8_t whichLED );

  float T1, T2, RoR1, timestamp; // local values for display
  int8_t level_1, level_2; // local values for display, user modify
  boolean dTime, dLevel_1, dLevel_2; // flags to indicate a value has changed
  boolean statusLCD; // indicator of need to refresh the display
  
  typedef enum { // state machine for interpreting user input
    running_state,
    level_1_state,
    level_2_state,
    slave_state,
    confirm_reset_state
  } HIDstate_t;
  
  HIDstate_t HIDstate;
};

#endif
