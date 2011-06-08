// cmndreader.h
//----------------

// code that defines specific commands for aArtisan

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

#ifndef CMNDREADER_H
#define CMNDREADER_H

#include <cmndproc.h>
#include <PWM16.h>

#include "user.h"

// ----------------------- commands (only first 4 characters are significant)
#define READ_CMD "READ" // triggers the TC4 to output current temps on serial line
//#define RF2000_CMD "RF20" // legacy code
//#define RC2000_CMD "RC20" // legacy code
#define UNITS_CMD "UNIT" // changes units, F or C
#define CHAN_CMD "CHAN" // maps logical channels to physical channels
#define OT1_CMD "OT1" // 0 to 100 percent output on SSR drive OT1
#define OT2_CMD "OT2" // 0 to 100 percent output on SSR drive OT2
#define IO3_CMD "IO3" // 0 to 100 percent PWM 5V output on IO3
#define PORT_CMD "PORT" // added 6/8/2011 per conv. with Lee, Sebastien
#define DIGITAL_WRITE_CMD "DWRT" // turn digital pin LOW or HIGH
#define ANALOG_WRITE_CMD "AWRT" // write a value 0 to 255 to PWM pin
#define IO3 3 // use DIO3 for PWM output
#define HASH '#' // precedes every command 6/8/2011
#define DELIM "; ," // command line parameter delimiters

#define PIN_HIGH "HIGH"  // states used in DWRT
#define PIN_LOW "LOW"
#define PIN_TOGL "TOGL"

// forward declarations
class ArtisanInterp;
class dwriteCmnd;
class awriteCmnd;
class readCmnd;
class chanCmnd;
class portOT1Cmnd;
class portOT2Cmnd;
class portIO3Cmnd;
class unitsCmnd;
//class rf2000Cmnd;
//class rc2000Cmnd;

// external declarations of class objects
extern readCmnd reader;
extern awriteCmnd awriter;
extern dwriteCmnd dwriter;
extern chanCmnd chan;
extern portOT1Cmnd ot1;
extern portOT2Cmnd ot2;
extern portIO3Cmnd io3;
//extern rf2000Cmnd rf2000;
//extern rc2000Cmnd rc2000;
extern unitsCmnd units;

// extern declarations for functions, variables in the main program
extern PWM16 ssr;
extern int levelOT1;
extern int levelOT2;
extern void logger();
extern boolean Cscale;
extern uint8_t actv[NC];

// class declaration for ArtisanInterp
class ArtisanInterp : public CmndInterp {
  public:
  ArtisanInterp();
  virtual const char* checkSerial();  // override so we can watch for the HASH
  protected:
  boolean hashFlag;
};

// class declarations for commands

class dwriteCmnd : public CmndBase {
  public:
    dwriteCmnd();
    virtual boolean doCommand( CmndParser* pars );
};

class awriteCmnd : public CmndBase {
  public:
    awriteCmnd();
    virtual boolean doCommand( CmndParser* pars );
};

class readCmnd : public CmndBase {
  public:
    readCmnd();
    virtual boolean doCommand( CmndParser* pars );
};

class chanCmnd : public CmndBase {
  public:
    chanCmnd();
    virtual boolean doCommand( CmndParser* pars );
};

class portOT1Cmnd : public CmndBase {
  public:
    portOT1Cmnd();
    virtual boolean doCommand( CmndParser* pars );
};

class portOT2Cmnd : public CmndBase {
  public:
    portOT2Cmnd();
    virtual boolean doCommand( CmndParser* pars );
};

class portIO3Cmnd : public CmndBase {
  public:
    portIO3Cmnd();
    virtual boolean doCommand( CmndParser* pars );
};

class unitsCmnd : public CmndBase {
  public:
    unitsCmnd();
    virtual boolean doCommand( CmndParser* pars );
};

/*
class rf2000Cmnd : public CmndBase {
  public:
    rf2000Cmnd();
    virtual boolean doCommand( CmndParser* pars );
};

class rc2000Cmnd : public CmndBase {
  public:
    rc2000Cmnd();
    virtual boolean doCommand( CmndParser* pars );
};
*/

#endif

