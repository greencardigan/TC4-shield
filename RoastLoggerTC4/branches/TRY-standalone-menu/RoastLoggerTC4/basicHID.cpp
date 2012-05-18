// basicHID.cpp

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

#include "basicHID.h"

// ---------------------- refreshes local parameters
void HIDbase::refresh( float t1, float t2, float RoR, float time, int8_t pow1, int8_t pow2 ) {
  T1 = t1;
  T2 = t2;
  RoR1 = RoR;
  timestamp = time;
  level_1 = pow1;
  level_2 = pow2;
  // all fields are stale
  statusLCD |= ALL_FIELDS;
}

// --------------------- draw the timer field in 00:00 format
void HIDbase::drawTimer() {
  char s[3];
  uint16_t itod;
  if( timestamp > 3599 ) 
    itod = 3599;
  else
    itod = round( timestamp );
  setCursor( TIMER_X, TIMER_Y );
  sprintf( s, "%02u", itod / 60 );  
  print( s );
  print(':');
  sprintf( s, "%02u", itod % 60 );
  print( s );
  print(' '); // padding 
}

// --------------------- draw the level_1 output level field
void HIDbase::drawLevel_1() {
  char pstr[5]; // buffer to contain string
  sprintf( pstr, "%3d", level_1 );
  setCursor( LEVEL_1_X, LEVEL_1_Y );
  print( pstr ); 
  if( HIDstate != level_1_state ) 
    print('%');
  else
    print('_'); // indicate we are in edit mode for level_1
  print(' '); // padding
}

// --------------------- draw the level_1 output level field
void HIDbase::drawLevel_2() {
  char pstr[5]; // buffer to contain string
  sprintf( pstr, "%3d", level_2 );
  setCursor( LEVEL_2_X, LEVEL_2_Y );
  print( pstr ); 
  if( HIDstate != level_2_state ) 
    print('%');
  else
    print('_'); // indicate we are in edit mode for level_2
  print(' '); // padding
}

// ------------------------ draw the T2 output field
void HIDbase::drawT2() {
  char st2[6]; // character buffer
  // channel 2 temperature 
  int it02 = round( T2 );
  if( it02 > 999 ) it02 = 999;
  else if( it02 < -999 ) it02 = -999;
  sprintf( st2, "%3d", it02 );
  setCursor( T2_X, T2_Y );
  print( T2_LABEL );
  print( st2 );  
}

// ------------------------ draw the T1 output field
void HIDbase::drawT1() {
  char st1[6]; // character buffer
  // channel 1 temperature 
  int it01 = round( T1 );
  if( it01 > 999 ) it01 = 999;
  else if( it01 < -999 ) it01 = -999;
  sprintf( st1, "%3d", it01 );
  setCursor( T1_X, T1_Y );
  print( T1_LABEL );
  print( st1 );  
}

// ------------------------ draw RoR of channel 1
void HIDbase::drawRoR() {
  char sRoR1[7];
  // channel 1 RoR
  int iRoR = round( RoR1 );
  if( iRoR > 99 ) 
    iRoR = 99;
  else
   if( iRoR < -99 ) iRoR = -99; 
  sprintf( sRoR1, "%0+3d", iRoR );
  setCursor( ROR_X, ROR_Y );
  print( ROR_LABEL );
  print( sRoR1 );
  print(' '); // padding
}

// --------------------- request user confirmation to reset timer
void HIDbase::drawConfirmReset() {
  clear();
  print( "RESET timer?" );
  setCursor( 11, 1 );
  print( "Y   N" );
}

// ----------------------- draws the display
void HIDbase::paintLCD( ) { 
  if( HIDstate != confirm_reset_state ) { // normal display, draw it one row at a time
    if( ! (statusLCD & (1 << ROW_BIT)) ) { // draw the fields in the first row
      statusLCD |= ( 1 << ROW_BIT );  // set up for drawing second row in next loop
      if( statusLCD & (1 << TIMER_BIT) ) {
        drawTimer();  // first line of display
        statusLCD &= ~(1 << TIMER_BIT); // clear status bit for field
      }
      if( statusLCD & (1 << LEVEL_1_BIT) ) {
        drawLevel_1();  // first line of display
        statusLCD &= ~(1 << LEVEL_1_BIT); // clear status bit for field
      }
      if( statusLCD & (1 << T2_BIT) ) {
        drawT2();  // first line of display
        statusLCD &= ~(1 << T2_BIT); // clear status bit for field
      }
    }
    else { // draw the fields in the second row
      statusLCD &= ~( 1 << ROW_BIT );  // set up for drawing first row in next loop
      if( statusLCD & (1 << ROR_BIT) ) {
        drawRoR();  // second line of display
        statusLCD &= ~(1 << ROR_BIT); // clear status bit for field
      }
      if( statusLCD & (1 << LEVEL_2_BIT) ) {
        drawLevel_2();  // second line of display
        statusLCD &= ~(1 << LEVEL_2_BIT); // clear status bit for field
      }
      if( statusLCD & (1 << T1_BIT) ) {
        drawT1();  // second line of display
        statusLCD &= ~(1 << T1_BIT); // clear status bit for field
      }
    }
  }
  else {
    if( statusLCD & (1 << CONFIRM_BIT) ) {
      drawConfirmReset(); // screen asking for user confirmation
      statusLCD = 0; // paint display only once
    }
  }
}

// --------------------------- initialize
void HIDbase::begin( uint8_t LCDcols, uint8_t LCDrows, uint8_t Nbuttons ) {
  cLCD::begin( LCDcols, LCDrows );
  cButtonPE16::begin( Nbuttons );
  setMasterMode(); // stand alone mode until serial command is received
  T1 = 0.0;
  T2 = 0.0;
  RoR1 = 0.0;
  timestamp = 0.0;
  level_1 = 0;
  level_2 = 0;
  statusLCD = 0; // start with all fields fresh
  dTime = false;
  dLevel_1 = false;
  dLevel_2 = false;
}

// ------------------------------------------
void HIDbase::doButtons() {
  if( readButtons() ) { // do nothing if no buttons have been pressed
    switch ( HIDstate ) {
      
      // --------------- do nothing if in slave mode
      case slave_state :
      break;

      // ---------------
      case confirm_reset_state :
      if( keyPressed( BTN_UP ) && keyChanged( BTN_UP ) ) { // Y)es key
        dTime = true;
        ledFlash( LED_3 );
        HIDstate = running_state;
        statusLCD = ALL_FIELDS;
      }
      else if( keyPressed( BTN_DOWN ) && keyChanged( BTN_DOWN ) ) { // N)o key
        ledFlash( LED_3 );
        HIDstate = running_state;
        statusLCD = ALL_FIELDS;
      }
      break;
      
      // --------------
      case running_state :
      if( keyPressed( BTN_HOME ) && keyChanged( BTN_HOME ) ) {// left button = start the roast
        ledFlash( LED_1 ); // bump the leftmost LED to indicate beans loaded
        HIDstate = confirm_reset_state; // ask for confirmation before resetting timer
        statusLCD = (1 << CONFIRM_BIT);
      }
      else if( keyPressed( BTN_SEL_MODE ) && keyChanged( BTN_SEL_MODE ) ) { // 2nd button selects mode
        ledFlash( LED_2 );  // bump LED to acknowledge
        HIDstate = level_1_state;
        statusLCD |= (1 << LEVEL_1_BIT);  // repaint the level_1 field
        statusLCD &= ~(1 << ROW_BIT); // make first row active
      }
      break;
    
      // --------------
      case level_1_state :
      if( keyPressed( BTN_HOME ) && keyChanged( BTN_HOME ) ) {// left button = return to home screen
        ledFlash( LED_1 ); // bump the leftmost LED to acknowledge
        HIDstate = running_state; // return to "home" screen
        statusLCD = ALL_FIELDS;
      }    
      else if( keyPressed( BTN_UP ) && keyChanged( BTN_UP ) ) { // increase the value of level_1
        ledFlash( LED_3 );
        int8_t trial = level_1;
        trial += 5;
        if( trial > 100 ) trial = 100;
        if( trial != level_1 ) {
          level_1 = trial;
          dLevel_1 = true;
          statusLCD |= (1 << LEVEL_1_BIT); // repaint the level_1 field
          statusLCD &= ~(1 << ROW_BIT); // make first row active
        }
      }
      else if( keyPressed( BTN_DOWN ) && keyChanged( BTN_DOWN ) ) { // increase the value of level_1
        ledFlash( LED_3 );
        int8_t trial = level_1;
        trial -= 5;
        if( trial < 0 ) trial = 0;
        if( trial != level_1 ) {
          level_1 = trial;
          dLevel_1 = true;
          statusLCD |= (1 << LEVEL_1_BIT); // repaint the level_1 field
          statusLCD &= ~(1 << ROW_BIT); // make first row active
        }
      }
      else if( keyPressed( BTN_SEL_MODE ) && keyChanged( BTN_SEL_MODE ) ) { // 2nd button selects mode
        ledFlash( LED_2 );  // bump LED to acknowledge
        HIDstate = level_2_state;
        statusLCD |= (1 << LEVEL_2_BIT);
        statusLCD &= ~(1 << ROW_BIT); // make first row active
      }
      break;
    
      // --------------
      case level_2_state :
      if( keyPressed( BTN_HOME ) && keyChanged( BTN_HOME ) ) {// left button = return to home screen
        ledFlash( LED_1 ); // bump the leftmost LED to indicate beans loaded
        HIDstate = running_state; // return to "home" screen
        statusLCD = ALL_FIELDS;
      }    
      else if( keyPressed( BTN_UP ) && keyChanged( BTN_UP ) ) { // increase the value of level_1
        ledFlash( LED_3 );
        int8_t trial = level_2;
        trial += 5;
        if( trial > 100 ) trial = 100;
        if( trial != level_2 ) {
          level_2 = trial;
          dLevel_2 = true;
          statusLCD |= (1 << LEVEL_2_BIT);
          statusLCD |= (1 << ROW_BIT); // make second row active

        }
      }
      else if( keyPressed( BTN_DOWN ) && keyChanged( BTN_DOWN ) ) { // increase the value of level_1
        ledFlash( LED_3 );
        int8_t trial = level_2;
        trial -= 5;
        if( trial < 0 ) trial = 0;
        if( trial != level_2 ) {
          level_2 = trial;
          dLevel_2 = true;
          statusLCD |= (1 << LEVEL_2_BIT);
          statusLCD |= (1 << ROW_BIT); // make second row active
        }
      }
      else if( keyPressed( BTN_SEL_MODE ) && keyChanged( BTN_SEL_MODE ) ) { // 2nd button selects mode
        ledFlash( LED_2 );  // bump LED to acknowledge
        HIDstate = running_state;
        statusLCD = ALL_FIELDS;
        statusLCD |= (1 << ROW_BIT); // make second row active
      }
      break;
    } // end switch
  } // end if readButtons()
}

// ----------------------------- event processer
boolean HIDbase::processEvents() {
  doButtons();
  paintLCD();
  return dTime || dLevel_1 || dLevel_2;
}

// ------------------- tells caller if timer reset requested
boolean HIDbase::resetTimer() { 
  boolean ret = dTime;
  dTime = false; // clear the flag
  return ret; 
} 

// ------------------- tells caller if level 1 was changed by user
boolean HIDbase::chgLevel_1() {
  boolean ret = dLevel_1;
  dLevel_1 = false; // clear the flag
  return ret; 
} 

// ------------------- tells caller if level 2 was changed by user
boolean HIDbase::chgLevel_2() { 
  boolean ret = dLevel_2;
  dLevel_2 = false; // clear the flag
  return ret; 
} 

// ------------------- flashes LED
void HIDbase::ledFlash( uint8_t nLED ) {
  ledToggle( nLED );
  delay( 5 );
  ledToggle( nLED );
}

