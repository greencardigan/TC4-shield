// cmndproc.h

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
// 20120126 version 1.02 : updated for Arduino 1.0 compatibility
// 20140426 version 1.03 : allows 5 tokens, 5 char per token

#ifndef CMNDPROC_H
#define CMNDPROC_H

#if defined(ARDUINO) && ARDUINO >= 100
#include <Arduino.h>
#else
#include <WProgram.h>
#endif

#define MAX_TOKENS 5  // maximum number of tokens in a command line
#define MAX_TOKEN_LEN 5  // max characters read per token (input may be longer)
#define MAX_CMND_LEN 40 // max overall characters in a command line
#define MAX_DLMTR 4 // max number of delimiter characters
#define MAX_RESULT_LEN 9 // max length of result string sent back to caller

// --------------------------- command line parser
class CmndParser {
  public:
    // constructor requires the delimiters string
    CmndParser( const char* dlmtr );
    // tokenizes the command line, returns the total number of tokens, incl. cmnd name
    uint8_t doParse( char* commandLine );
    // returns a pointer to the command name (first token)
    char* cmndName(){ return tokens[0]; }
    // returns a pointer to the i'th parameter (i = 1 is first parameter after name)
    char* paramStr( uint8_t i ){ return tokens[i]; }
    // clears all token strings to start fresh
    void clrTokens();
    // returns number of tokens
    uint8_t nTokens(){ return ntok; }
  protected:
    char tokens[MAX_TOKENS][MAX_TOKEN_LEN + 1]; // space to store the tokenized string
    char dlmtr[MAX_DLMTR + 1]; // string of delimiters
    uint8_t ntok; // token count
};

// ----------------- base class for a command definition (linked list member)
class CmndBase {
  public:
    CmndBase( const char* cname );  // constructor with command name
    CmndBase* getNext(){ return next; } // next object in linked list
    void setNext( CmndBase* link ){ next = link; }  // sets the link to next
    // executes the command, given the parsed command line
    virtual boolean doCommand( CmndParser* pars );  // override this always
    char* getName(){ return keyword; }
  protected:
    char keyword[MAX_TOKEN_LEN + 1];  // string that identifies the command
    CmndBase* next;  // pointer to next command in the linked list
};

// -------------------------- command interpreter class
class CmndInterp {
  public:
    CmndInterp( const char* dstr ); // initialize with delimiters string
    void setCmndStr( const char* cstr ); // alternative to reading from serial port
    uint8_t addCommand( CmndBase* newCmnd ); // add a new command to the list
    // reads characters until newline, then execute processCommand
    virtual const char* checkSerial(); // return non NULL if a command was processed
    // step through linked list of commands; quit after there was a match
    virtual void processCommand();
  protected:
    char cmndstr[MAX_CMND_LEN + 1];  // unparsed raw input string
    char result[MAX_RESULT_LEN + 1]; // return value
    CmndParser parser;  // parser object
    CmndBase* cmndList;  // head of linked list
    uint8_t numCmnds;  // number of commands in the linked list
};

#endif
