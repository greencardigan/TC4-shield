// basic_HID.cpp

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

#include "basic_HID.h"

// ---------------------- refreshes home screen parameters
void HIDbase::refresh( float t1, float t2, float RoR, float time, int8_t pow1, int8_t pow2 ) {
  T1 = t1;
  T2 = t2;
  RoR1 = RoR;
  timestamp = time;
  level_1 = pow1;
  level_2 = pow2;
  homeChanged = true;
}

// ----------------------- redraws the basic home screen
void HIDbase::homeScreen( ) {
  char smin[3],ssec[3],st1[6],st2[6],sRoR1[7];
  char pstr[5];

  // form the timer output string in min:sec format
  int itod;
  if( timestamp > 3599 ) 
    itod = 3599;
  else
    itod = round( timestamp );
    
  sprintf( smin, "%02u", itod / 60 );
  sprintf( ssec, "%02u", itod % 60 );
  setCursor(0,0);
  print( smin );
  print( ":" );
  print( ssec );
 
  // channel 2 temperature 
  int it02 = round( T2 );
  if( it02 > 999 ) it02 = 999;
  else if( it02 < -999 ) it02 = -999;
  sprintf( st2, "%3d", it02 );
  setCursor( 11, 0 );
  print( "E " );
  print( st2 ); 

  // channel 1 RoR
  int iRoR = round( RoR1 );
  if( iRoR > 99 ) 
    iRoR = 99;
  else
   if( iRoR < -99 ) iRoR = -99; 
  sprintf( sRoR1, "%0+3d", iRoR );
  setCursor(0,1);
  print( "RT");
  print( sRoR1 );

  // channel 1 temperature
  int it01 = round( T1 );
  if( it01 > 999 ) 
    it01 = 999;
  else
    if( it01 < -999 ) it01 = -999;
  sprintf( st1, "%3d", it01 );
  setCursor( 11, 1 );
  print("B ");
  print(st1);
  
  sprintf( pstr, "%3d", level_1 );
  setCursor( 6, 0 );
  print( pstr ); print("%");

  sprintf( pstr, "%3d", level_2 );
  setCursor( 6, 1 );
  print( pstr ); print("%");
}

// ------------------------------------
void HIDbase::begin( uint8_t LCDcols, uint8_t LCDrows, uint8_t Nbuttons ) {
  cLCD::begin( LCDcols, LCDrows );
  cButtonPE16::begin( Nbuttons );
  setMasterMode(); // assume standAlone is true
  T1 = 0.0;
  T2 = 0.0;
  RoR1 = 0.0;
  timestamp = 0.0;
  level_1 = 0;
  level_2 = 0;
  homeChanged = true;
  dTime = false;
  dLevel_1 = false;
  dLevel_2 = false;
}

// ------------------------------------------
boolean HIDbase::doButtons() {
  if( readButtons() ) {
    if( keyPressed( 3 ) && keyChanged( 3 ) ) {// left button = start the roast
      if( standAlone ) { // load beans
        dTime = true;
        ledOn( 2 ); // turn on leftmost LED to indicate beans loaded
      }
      else { // placeholder for possible future feature
      }
    }
    else if( keyPressed( 2 ) && keyChanged( 2 ) ) { // 2nd button marks first crack
      if( standAlone ) { // first crack
        ledOn( 1 );  // turn on LED to indicate first crack
      }
      else { // placeholder
      }
    }
    else if( keyPressed( 1 ) && keyChanged( 1 ) ) { // 3rd button marks second crack
      if( standAlone ) {
        ledOn( 0 ); // rightmost LED at 2nd crack
      }
      else { // placeholder
      }
    }
    else if( keyPressed( 0 ) && keyChanged( 0 ) ) { // 4th button marks eject
      if( standAlone ) {
        ledAllOff(); // turn off all LED's when beans are ejected
      }
      else { // placeholder
      }
    }
  }
  return dTime || dLevel_1 || dLevel_2 ;
}

// -------------------------------------------
boolean HIDbase::pollStatus() { // event processor
  if( homeChanged ) {
    homeScreen();
    homeChanged = false;
  }
  return doButtons();
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

