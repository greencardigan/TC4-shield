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

// Version 1.10

#ifndef CMNDREADER_H
#define CMNDREADER_H

#include <cmndproc.h>
#ifndef PHASE_ANGLE_CONTROL
#include <PWM16.h>
#endif

#include <cADC.h>
#include <PID_v1.h>

#include "user.h"
#include "phase_ctrl.h"
#include "PID_v1.h"

// ----------------------- commands
#define READ_CMD "READ" // triggers the TC4 to output current temps on serial line
#define UNITS_CMD "UNITS" // changes units, F or C
#define CHAN_CMD "CHAN" // maps logical channels to physical channels
#define OT1_CMD "OT1" // 0 to 100 percent output on SSR drive OT1
#define OT2_CMD "OT2" // 0 to 100 percent output on SSR drive OT2
#if ( !defined( PHASE_ANGLE_CONTROL ) ) || ( INT_PIN != 3 )
#define IO3_CMD "IO3" // 0 to 100 percent PWM 5V output on IO3
#define DCFAN_CMD "DCFAN" // 0 to 100 percent PWM 5V output on IO3, with slew rate checks
#endif
#define DIGITAL_WRITE_CMD "DWRITE" // turn digital pin LOW or HIGH
#define ANALOG_WRITE_CMD "AWRITE" // write a value 0 to 255 to PWM pin
#define IO3 3 // use DIO3 for PWM output
#define PID_CMD "PID" // turn PID ON or OFF
#define RESET_CMD "RESET" // pBourbon reset command
#ifdef ROASTLOGGER
#define LOAD_CMD "LOAD" // Roastlogger LOAD command
#define POWER_CMD "POWER" // Roastlogger POWER command
#define FAN_CMD "FAN" // Roastlogger FAN command
#endif
#define FILT_CMD "FILT" // runtime changes to digital filtering on input channels
#define FAN_PORT 3 // use DI03 for PWM fan output

// -------------------------- slew rate limitations for fan control
#define MAX_SLEW 25 // percent per second
#define SLEW_STEP 5 // increase in steps of 5% for smooth transition
#define SLEW_STEP_TIME (uint32_t)(SLEW_STEP * 1000 / MAX_SLEW) // min ms delay between steps


// forward declarations
class dwriteCmnd;
class awriteCmnd;
class readCmnd;
class chanCmnd;
class ot1Cmnd;
class ot2Cmnd;
#if ( !defined( PHASE_ANGLE_CONTROL ) ) || ( INT_PIN != 3 )
class io3Cmnd;
class dcfanCmnd;
#endif
class unitsCmnd;
class pidCmnd;
class resetCmnd;
#ifdef ROASTLOGGER
class loadCmnd;
class powerCmnd;
class fanCmnd;
#endif
class filtCmnd;

// external declarations of class objects
extern readCmnd reader;
extern awriteCmnd awriter;
extern dwriteCmnd dwriter;
extern chanCmnd chan;
extern ot1Cmnd ot1;
extern ot2Cmnd ot2;
#if ( !defined( PHASE_ANGLE_CONTROL ) ) || ( INT_PIN != 3 )
extern io3Cmnd io3;
extern dcfanCmnd dcfan;
#endif
extern unitsCmnd units;
extern pidCmnd pid;
extern resetCmnd reset;
#ifdef ROASTLOGGER
extern loadCmnd load;
extern powerCmnd power;
extern fanCmnd fan;
#endif
extern filtCmnd filt;


// extern declarations for functions, variables in the main program
#ifndef PHASE_ANGLE_CONTROL
extern PWM16 ssr;
#endif
extern int levelOT1;
extern int levelOT2;
extern int levelIO3;
extern void logger();
extern boolean Cscale;
extern uint8_t actv[NC];
extern PID myPID;
extern uint32_t counter;
extern int profile_number;
extern void setProfile();
//extern boolean pBourbon;
//extern boolean roastlogger;
extern boolean artisan_logger;
extern double SV;
extern double Output;
extern uint8_t pid_chan;
extern filterRC fT[NC]; // filters for logged ET, BT
extern void outOT1();
extern void outOT2();
extern void outIO3();


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

class ot1Cmnd : public CmndBase {
  public:
    ot1Cmnd();
    virtual boolean doCommand( CmndParser* pars );
};

class ot2Cmnd : public CmndBase {
  public:
    ot2Cmnd();
    virtual boolean doCommand( CmndParser* pars );
};

#if ( !defined( PHASE_ANGLE_CONTROL ) ) || ( INT_PIN != 3 )
class io3Cmnd : public CmndBase {
  public:
    io3Cmnd();
    virtual boolean doCommand( CmndParser* pars );
};

class dcfanCmnd : public CmndBase {
  protected:
    uint8_t target; // duty cycle value requested by user
    uint8_t current; // instantaneous value
    uint32_t last_fan_change; // ms value when duty cycle last updated
  public:
    dcfanCmnd();
    void init();  // initialize conditions
    virtual boolean doCommand( CmndParser* pars ); // records the target rate only
    void set_fan( uint8_t duty ); // sets the fan output duty cycle
    void slew_fan(); // smoothly ramp up the fan speed
};
#endif

class unitsCmnd : public CmndBase {
  public:
    unitsCmnd();
    virtual boolean doCommand( CmndParser* pars );
};

class pidCmnd : public CmndBase {
  public:
    pidCmnd();
    virtual boolean doCommand( CmndParser* pars );
    void pidOFF(); // puts PID in MANUAL mode, resets outputs
    void pidON(); // puts PID in AUTOMATIC mode
};

class filtCmnd : public CmndBase {
  public:
    filtCmnd();
    virtual boolean doCommand( CmndParser* pars );
};

class resetCmnd : public CmndBase {
  public:
    resetCmnd();
    virtual boolean doCommand( CmndParser* pars );
};

class loadCmnd : public CmndBase {
  public:
    loadCmnd();
    virtual boolean doCommand( CmndParser* pars );
};

class powerCmnd : public CmndBase {
  public:
    powerCmnd();
    virtual boolean doCommand( CmndParser* pars );
};

class fanCmnd : public CmndBase {
  public:
    fanCmnd();
    virtual boolean doCommand( CmndParser* pars );
};

#endif

