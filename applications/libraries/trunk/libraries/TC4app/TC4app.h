/*
 * TC4app.h
 *
 *  Created on: Jun 2, 2011
 *      Author: Jim
 */
//-------------------------------------------
// Revision history
//
// Version 1.00
// 20110602  Created
// 20110618  Added code to allow selection of TCbase.h or thermocouple.h
//           Fixed a few minor things that were causing compiler warnings
//
//
// ------------------------------------------------
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
//   Neither the name of the copyright holder nor the names of its contributors may be
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

// Acknowledgement is given to Bill Welch for his development of the prototype hardware and software
// upon which much of this library is based.


#ifndef TC4APP_H_
#define TC4APP_H_

// -------------------------------------------------------------------
// Arduino libraries, licensed under LGPL
#include <Wire.h>
#include <WProgram.h>
// --------------------------------------------------------------------

#include <cADC.h>
#include <cLCD.h>
#include <cButton.h>
#include <mcEEPROM.h>
#include <cmndproc.h>

// --------------------- to use TCbase library
//#include <TCbase.h>
//#define tcBase TCbase
// ---------- or to use thermocouple library
#include <thermocouple.h>
// --------------------------------------------

#define _TF 10 // default value for filtering of display temperatures
#define _RF 85 // default value for filtering T prior to rise calc
#define _RORF 80 // default value for post-filtering of RoR values
#define _AMBF 80 // default value for ambient filter
#define _MIN_DELAY 300 // conversion time for ADC
#define _D_MULT 0.001 // conversion from uint32 to float for temps
#define _MAX_COMMAND 40 // length of command string
#define _DP 1 // decimal places for output string
#define _RESET "RESET" // reset command keyword
#define _CHAN "CHAN"
#define _UNITS "UNITS"
#define _READ "READ"
#define _DLMTR_STR ";, "  // default delimiters for commands
#define _LOOP_INCR 100 // ms  use to keep loop times on even increments
#define _NCHAN 4 // max number of ADC channels
#define _DEFAULT_BAUD 57600
#define _IDLE_TIME_ALARM 20


// forward declaration
class appBase;

// lists the active channels on the ADC, 1 through 4
class chanList {
  public:
    chanList( uint8_t c1 = 1, uint8_t c2 = 2, uint8_t c3 = 0, uint8_t c4 = 0 );
    uint8_t getChan( uint8_t i ){ return clist[i]; } // 0 means inactive
    void setMap( uint8_t chan1, uint8_t chan2, uint8_t chan3, uint8_t chan4 );
    uint8_t getNumActv(){ return nc; }
  protected:
    uint8_t clist[_NCHAN]; // inactive = 0; active = 1-based physical channel
    uint8_t nc; // number of active channels
};

// command object that has access to appBase
class appCmnd : public CmndBase {
  public:
    // pass a pointer to the application in constructor
    appCmnd( const char* cname, appBase* parent, boolean ak = false );
  protected:
    appBase* app;
    boolean ack;  // flag for whether to return an acknowledgment
};

// appCmnd that responds to RESET
class rstCmnd : public appCmnd {
  public:
    rstCmnd( appBase* parent, boolean ak );
    virtual boolean doCommand( CmndParser* pars );
};

// base class for TC4 applications
class appBase : public CmndInterp {
  public:
    appBase( tcBase*, uint8_t ADCaddr = A_ADC, uint8_t ambaddr = A_AMB, uint8_t epaddr = ADDR_BITS );
    void initTempFilters( uint8_t f1 = _TF, uint8_t f2 = _TF, uint8_t f3 = _TF, uint8_t f4 = _TF );
    void initRiseFilters( uint8_t f1 = _RF, uint8_t f2 = _RF, uint8_t f3 = _RF, uint8_t f4 = _RF );
    void initRoRFilters( uint8_t f1=_RORF, uint8_t f2=_RORF, uint8_t f3=_RORF, uint8_t f4=_RORF );
    void setAmbFilter( uint8_t filt ) { ambf = filt; }
    void setLCD( LCDbase* lc, uint8_t c = 16, uint8_t r = 2 ){lcd=lc;lcd_ncol=c;lcd_nrow=r;}
    void setButtons( cButtonPE16* btn ) { buttons = btn; }
    void setUnits( char cf = 'F' ) { celsius = toupper(cf) == 'C' ? true : false; }
    void setBanner( const char* bnr ){strncpy( banner,bnr,16); banner[16]='\0'; }
    void setActiveChannels( uint8_t c1, uint8_t c2, uint8_t c3, uint8_t c4);
    void setBaud( uint32_t baudrate ){ baud = baudrate; }
    virtual void start( uint32_t cycle = 0 ); // set loop time and start the app
    virtual void run(); // main loop

    // these are exposed so commands can get to them
    float getTimeStamp(){ return timestamp; }
    void setRefTime( float rt ){ reftime = rt; }
    void setNextLoop( uint32_t nL ){ nextLoop = nL; }
    virtual void logSamples(); // logs one set of samples to serial port

  protected:
    virtual void initAmb( uint8_t cmode = AMB_CONV_1SHOT ){ amb.init( ambf, cmode ) ;}
    virtual void setAmbCfg(){amb.setCfg( AMB_BITS_12 );}
    virtual void setADCcfg(){adc.setCfg( ADC_BITS_18, ADC_GAIN_8, ADC_CONV_1SHOT );}
    virtual void activeDelay( uint32_t ms ); // active delay loop
    virtual void readCal(); // try and read info from eeprom
    virtual boolean getSamples(); // retrieves samples from ADC
    virtual void checkInput(); // checks for user input
    virtual float calcRise( int32_t T1, int32_t T2, int32_t t1, int32_t t2 ); // derivative
    virtual void updateLCD( float, float, float, float, float=0.0, float=0.0 );  // probably only use 4 values
    // some placeholders for future use
    virtual void doControl(){} // gets called by run() each time after first time
    virtual void initControl(){} // gets called by run() on the first time through
    virtual boolean checkLimits( int32_t &uv, uint8_t &pchan ) { return true; } // checks input

    float timestamp;
    uint32_t nextLoop;
    float reftime;

    // this must be set to point to a TC defined in the main program
    tcBase* TC;

    // variables used for timing
    uint32_t looptime;
    uint32_t userloop;
    boolean first;

    // pointers to objects defined in main program (set to NULL if not active)
    LCDbase* lcd;
    cButtonPE16* buttons;

    // class objects
    mcEEPROM eeprm;
    cADC adc;
    ambSensor amb;
    chanList chan;
    filterRC fT[_NCHAN];
    filterRC fRise[_NCHAN];
    filterRC fRoR[_NCHAN];

    // arrays to store temperatures, times for each channel
    int32_t temps[_NCHAN]; //  stored temperatures are divided by D_MULT
    int32_t ftemps[_NCHAN]; // heavily filtered temps
    int32_t ftimes[_NCHAN]; // filtered sample timestamps
    int32_t flast[_NCHAN]; // for calculating derivative
    int32_t lasttimes[_NCHAN]; // for calculating derivative

    // misc variables
    boolean celsius;
    uint8_t lcd_ncol, lcd_nrow;  // usually 16, 2
    char banner[17];
    char command[_MAX_COMMAND];
    uint32_t baud;
    uint8_t ambf;
};

// responds to CHAN command
class chanCmnd : public appCmnd {
  public:
    chanCmnd( appBase* parent, boolean ak );
    virtual boolean doCommand( CmndParser* pars );
};

// responds to READ command
class readCmnd : public appCmnd {
  public:
    readCmnd( appBase* parent, boolean ak );
    virtual boolean doCommand( CmndParser* pars );
};

// responds to UNITS command
class unitsCmnd : public appCmnd {
  public:
    unitsCmnd( appBase* parent, boolean ak );
    virtual boolean doCommand( CmndParser* pars );
};

// extend appBase by adding response to RESET command
class appSerialRst : public appBase {
  public:
    appSerialRst( tcBase*, uint8_t ADCaddr = A_ADC, uint8_t ambaddr = A_AMB, uint8_t epaddr = ADDR_BITS );
  protected:
    rstCmnd rst;
};

// extends appSerialReset by adding capability to respond to set of basic commands:
//   READ, CHAN, UNITS
class appSerialComm : public appSerialRst {
  public:
    appSerialComm(tcBase*, uint8_t ADCaddr = A_ADC, uint8_t ambaddr = A_AMB, uint8_t epaddr = ADDR_BITS );
  protected:
    chanCmnd chn;
    readCmnd rd;
    unitsCmnd un;
};

#endif /* TC4APP_H_ */
