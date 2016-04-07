// cmndproc.cpp

// command processor library for Arduino TC4 applications
// To use:
//    1.  create an instance of CmndInterp
//    2.  derive a class from CmndBase for each active command desired
//        a.  constructor must initialize the command keyword text
//        b.  override doCommand() with a function that will carry out the command
//    3.  add each command to the linked list, using CmndInterp::addCommand();
//    4.  CmndInterp::checkSerial() will watch the serial line, parse the strings,
//        and step through the linked list until one of the CmndBase objects is executed.

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
//   Neither the name of the copyright holder(s) nor the names of its contributors may be
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

// Revision history:
// 20110601 version 1.00 : created library
// 20120126 version 1.01 : improved handling of CR and LF


#include "cmndproc.h"

// ------------------------------ CmndParser class
// constructor
CmndParser::CmndParser( const char* dstr ){
  strncpy( dlmtr, dstr, MAX_DLMTR );
  dlmtr[MAX_DLMTR] = '\0';  // for safety
}

// parse the long command string
uint8_t CmndParser::doParse( char* command ){
  clrTokens();  // reinitialize
  char* pch = strtok( command, dlmtr );
  while( pch != NULL && ntok < MAX_TOKENS ) {
   strncpy( tokens[ntok], pch, MAX_TOKEN_LEN );
   tokens[ntok][MAX_TOKEN_LEN] = '\0'; // for safety
   pch = strtok( NULL, dlmtr );
   ++ntok;
  }
//  Serial.println( ntok );
  return ntok;
}

// clear token strings
void CmndParser::clrTokens() {
  for( uint8_t i = 0; i < MAX_TOKENS; i++ )
    tokens[i][0] = '\0';  // clear out old tokens
  ntok = 0;
}

// ----------------------------- CmndBase class
// constructor
CmndBase::CmndBase( const char* cname ) {
  strncpy( keyword, cname, MAX_TOKEN_LEN );
  keyword[MAX_TOKEN_LEN] = '\0'; // for safety
}

// override this with a function that actually does something
boolean CmndBase::doCommand( CmndParser* pars ) {
  return( strcmp( keyword, pars->cmndName() ) == 0 );
}

// --------------------------- CmndInterp class
// constructor
CmndInterp::CmndInterp( const char* dstr )
  : parser( dstr ){
  cmndList = NULL;
  numCmnds = 0;
}

// add objects from the front of linked list
uint8_t CmndInterp::addCommand( CmndBase* newCmnd ) {
  newCmnd->setNext( cmndList );  // point to previous 1st command
//  Serial.println( newCmnd->getName() );
  cmndList = newCmnd; // new head of list
  return ++numCmnds;
}

// step through list and process each command
void CmndInterp::processCommand() {
  if( cmndList == NULL ) return;
  uint8_t ntokens = parser.doParse( cmndstr );
  if( ntokens == 0 ) return;
  CmndBase* cmnd = cmndList;
  while( cmnd != NULL ) {
    if( cmnd->doCommand( &parser ) )
      return;
    else
      cmnd = cmnd->getNext();
  }
}

// read data from the serial port
const char* CmndInterp::checkSerial() {
  char c;
  while( Serial.available() > 0 ) {
    c = Serial.read();
    // check for newline, buffer overflow
    uint8_t len = strlen( cmndstr );
    if( ( c == '\n' ) || ( len == MAX_CMND_LEN ) ) {
      // report input back to calling program
      strncpy( result, cmndstr, MAX_RESULT_LEN );
      result[MAX_RESULT_LEN] = '\0'; // for safety
      processCommand();
      cmndstr[0] = '\0'; // empty the buffer
      return result;
    } // end if
    else if( c != '\r' ) { // skip CR, otherwise append character
      cmndstr[len] = toupper(c);
      cmndstr[len+1] = '\0';
    } // end else
  } // end while
  return NULL;
}

// input a string directly (not using serial read)
void CmndInterp::setCmndStr( const char* cstr ) {
  strncpy( cmndstr, cstr, MAX_CMND_LEN );
  cmndstr[MAX_CMND_LEN] = '\0';  // for safety
}

