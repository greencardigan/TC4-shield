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

#include <Wire.h>
#include <WProgram.h>

#include <cADC.h>
#include <cLCD.h>
#include <cButton.h>
#include <mcEEPROM.h>
#include <TCbase.h>

#define _TF 10 // default value for filtering of display temperatures
#define _RF 85 // default value for filtering T prior to rise calc
#define _RORF 80 // default value for post-filtering of RoR values
#define _AMBF 80 // default value for ambient filter
#define _MIN_DELAY 300 // conversion time for ADC
#define _D_MULT 0.001 // conversion from uint32 to float for temps
#define _MAX_COMMAND 40 // length of command string
#define _DP 1 // decimal places for output string
#define _RESET "RESET" // reset command keyword

// lists the active channels on the ADC, 1 through 4
class chanList {
  public:
    chanList( uint8_t c1 = 1, uint8_t c2 = 2, uint8_t c3 = 0, uint8_t c4 = 0 );
    uint8_t getChan( uint8_t i ){ return clist[i]; } // 0 means inactive
    void setMap( uint8_t chan1, uint8_t chan2, uint8_t chan3, uint8_t chan4 );
    uint8_t getNumActv(){ return nc; }
  protected:
    uint8_t clist[4]; // inactive = 0; active = 1-based physical channel
    uint8_t nc; // number of active channels
};

class appBase {
  public:
    appBase( TCbase*, uint8_t ADCaddr = A_ADC, uint8_t ambaddr = A_AMB, uint8_t epaddr = ADDR_BITS );
    void initTempFilters( uint8_t f1 = _TF, uint8_t f2 = _TF, uint8_t f3 = _TF, uint8_t f4 = _TF );
    void initRiseFilters( uint8_t f1 = _RF, uint8_t f2 = _RF, uint8_t f3 = _RF, uint8_t f4 = _RF );
    void initRoRFilters( uint8_t f1=_RORF, uint8_t f2=_RORF, uint8_t f3=_RORF, uint8_t f4=_RORF );
    void initAmb(){ amb.init(ambf) ;}
    void setAmbFilter( uint8_t filt ) { ambf = filt; }
    void setLCD( LCDbase* lc, uint8_t c = 16, uint8_t r = 2 ){lcd=lc;lcd_ncol=c;lcd_nrow=r;}
    void setButtons( cButtonPE16* btn ) { buttons = btn; }
    void setUnits( char cf = 'F' ) { celsius = toupper(cf) == 'C' ? true : false; }
    void setBanner( const char* bnr ){strncpy( banner,bnr,16); banner[16]='\0'; }
    void setActiveChannels( uint8_t c1, uint8_t c2, uint8_t c3, uint8_t c4);
    virtual void activeDelay( uint32_t ms ); // active delay loop
    virtual void readCal(); // try and read info from eeprom
    virtual void setBaud( uint32_t baudrate ){ baud = baudrate; }
    virtual void start( uint32_t cycle = 1000 ); // start the app
    virtual void run(); // main loop
    virtual void logSamples(); // logs one set of samples to serial port
    virtual boolean getSamples(); // retrieves samples from ADC
    virtual void checkSerial(); // checks for incoming commands
    virtual void checkButtons(); // checks for user input
    virtual float calcRise( int32_t T1, int32_t T2, int32_t t1, int32_t t2 ); // derivative
    virtual void updateLCD( float, float, float, float, float=0.0, float=0.0 );  // probably only use 4 values

    // some placeholders for future use
    virtual void doControl(){} // gets called by run() each time after first time
    virtual void initControl(){} // gets called by run() on the first time through
    virtual boolean checkLimits( uint32_t uv, uint8_t pchan ) { return true; } // checks input
  protected:

    // this must be set to point to a TC defined in the main program
    TCbase* TC;

    // variables used for timing
    uint32_t looptime;
    float timestamp;
    boolean first;
    uint32_t nextLoop;
    float reftime;

    // pointers to objects defined in main program (set to NULL if not active)
    LCDbase* lcd;
    cButtonPE16* buttons;

    // class objects
    mcEEPROM eeprom;
    cADC adc;
    ambSensor amb;
    chanList chan;
    filterRC fT[4];
    filterRC fRise[4];
    filterRC fRoR[4];

    // arrays to store temperatures, times for each channel
    int32_t temps[4]; //  stored temperatures are divided by D_MULT
    int32_t ftemps[4]; // heavily filtered temps
    int32_t ftimes[4]; // filtered sample timestamps
    int32_t flast[4]; // for calculating derivative
    int32_t lasttimes[4]; // for calculating derivative

    // misc variables
    boolean celsius;
    uint8_t lcd_ncol, lcd_nrow;  // usually 16, 2
    char banner[17];
    char command[_MAX_COMMAND];
    uint32_t baud;
    uint8_t ambf;

};

#endif /* TC4APP_H_ */
