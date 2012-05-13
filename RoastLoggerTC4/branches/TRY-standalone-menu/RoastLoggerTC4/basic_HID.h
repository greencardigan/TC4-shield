// basic_HID.h

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

// Revision history
// 20120512  version 0.0  - created

#include <cLCD.h>
#include <cButton.h>

// --------------------------
class HIDbase : public cLCD, public cButtonPE16 {
  public:
  virtual void refresh( float t1, float t2, float RoR, float time, int8_t pow1, int8_t pow2 );
  virtual void homeScreen(); // repaints the home screen
  void begin( uint8_t LCDcols = 16, uint8_t LCDrows = 2, uint8_t Nbuttons = 4 );
  inline void setMasterMode(){ standAlone = true; }
  inline void setSlaveMode() { standAlone = false; }
  boolean pollStatus(); // main event handler; returns true on timer reset
  virtual boolean doButtons(); // take action based on user button presses; return true on timer reset
  boolean resetTimer(); // tells caller if timer reset requested
  boolean chgLevel_1(); // tells caller if output level 1 changed
  boolean chgLevel_2(); // tells caller if output level 2 changed
  inline int8_t getLevel_1() { return level_1; } // returns new value for level 1
  inline int8_t getLevel_2() { return level_2; } // returns new value for level 2
  
  protected:
  boolean standAlone;
  // home screen display fields
  float T1, T2, RoR1, timestamp;
  int8_t level_1, level_2;
  boolean homeChanged; // true when home screen needs to be redrawn
  boolean dTime, dLevel_1, dLevel_2; // flags to indicate a value has changed
  
};

