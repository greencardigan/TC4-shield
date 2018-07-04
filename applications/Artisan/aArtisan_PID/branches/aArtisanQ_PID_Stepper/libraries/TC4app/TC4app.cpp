/*
 * TC4app.cpp
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
// 20110903  readCal now uses mcEEPROM routine readCalBlock
//
//
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

#include "TC4app.h"

// --------------------------------------------------------------
// class chanList

// constructor
chanList::chanList( uint8_t c1, uint8_t c2, uint8_t c3, uint8_t c4) {
  setMap( c1, c2, c3, c4 );
}

// fill the clist mapping array
void chanList::setMap( uint8_t c1, uint8_t c2, uint8_t c3, uint8_t c4 ) {
  uint8_t i = 0;
  nc = 0;
  if( i < _NCHAN ) { clist[i++] = c1; if( c1 != 0 ) ++nc; }
  if( i < _NCHAN ) { clist[i++] = c2; if( c2 != 0 ) ++nc; }
  if( i < _NCHAN ) { clist[i++] = c3; if( c3 != 0 ) ++nc; }
  if( i < _NCHAN ) { clist[i++] = c4; if( c4 != 0 ) ++nc; }
}

// ---------------------------------------------------------------
// class appCmnd
appCmnd::appCmnd( const char* cname, appBase* ap, boolean ak ) :
  CmndBase( cname ),
  app( ap ),
  ack( ak ) {
}

// --------------------------------------------------------------------
// class appBase

// constructor
appBase::appBase( tcBase* tc, uint8_t ADCaddr, uint8_t ambaddr, uint8_t epaddr ) :
  CmndInterp( _DLMTR_STR ),
  eeprm(epaddr),
  adc(ADCaddr),
  amb(ambaddr),
  chan(1,2,0,0)
{
  TC = tc;
  lcd = NULL;
  buttons = NULL;
  celsius = false;
  looptime = 2 * _LOOP_INCR; // initialize based on 2 active channels
  baud = _DEFAULT_BAUD;
  ambf = _AMBF; // default value
  banner[0] = '\0'; // initialize to blank string
}

// initialize the filters for display temperatures
void appBase::initTempFilters( uint8_t f1, uint8_t f2, uint8_t f3, uint8_t f4 ) {
  uint8_t i = 0;
  if( i < _NCHAN ) fT[i++].init( f1 );
  if( i < _NCHAN ) fT[i++].init( f2 );
  if( i < _NCHAN ) fT[i++].init( f3 );
  if( i < _NCHAN ) fT[i++].init( f4 );
}

// initialize the filters used to smooth temps prior to rise calculation
void appBase::initRiseFilters( uint8_t f1, uint8_t f2, uint8_t f3, uint8_t f4 ) {
  uint8_t i = 0;
  if( i < _NCHAN ) fRise[i++].init( f1 );
  if( i < _NCHAN ) fRise[i++].init( f2 );
  if( i < _NCHAN ) fRise[i++].init( f3 );
  if( i < _NCHAN ) fRise[i++].init( f4 );
}

// initialize the filters used post-filter computed RoR values
void appBase::initRoRFilters( uint8_t f1, uint8_t f2, uint8_t f3, uint8_t f4 ) {
  uint8_t i = 0;
  if( i < _NCHAN ) fRoR[i++].init( f1 );
  if( i < _NCHAN ) fRoR[i++].init( f2 );
  if( i < _NCHAN ) fRoR[i++].init( f3 );
  if( i < _NCHAN ) fRoR[i++].init( f4 );
}

// try and read info from eeprom
void appBase::readCal(){
  calBlock caldata;
  // read calibration and identification data from eeprom
  if( readCalBlock( eeprm, caldata )) {  // mcEEPROM library function
    adc.setCal( caldata.cal_gain, caldata.cal_offset );
    amb.setOffset( caldata.K_offset );
  }
  else { // if there was a problem with EEPROM read, then use default values
    adc.setCal( 1.00, 0.0 );
    amb.setOffset( 0.0 );
  }
}

// identify the active ADC channels
void appBase::setActiveChannels( uint8_t c1, uint8_t c2, uint8_t c3, uint8_t c4) {
  chan.setMap( c1, c2, c3, c4 );
  // increase the looptime if required
  uint32_t mincycle = chan.getNumActv() * _LOOP_INCR;
  looptime = ( userloop >= mincycle ) ? userloop : mincycle;
}

// initialize things and start the clock
void appBase::start( uint32_t cycle ) { // cycle == 0, program calculates loop time
  delay( 100 );
  Wire.begin();
  Serial.begin( baud );
  initAmb(); // initialize the ambient sensor
  setAmbCfg(); // set to default values
  setADCcfg(); // set to default values
  if( lcd != NULL ) {
    lcd->begin( lcd_ncol, lcd_nrow );
    lcd->backlight();
    lcd->setCursor( 0, 0 );
    lcd->print( banner ); // display version banner
  }
  if( buttons != NULL ) {
    buttons->begin( 4 );
    buttons->readButtons();
    buttons->ledAllOff();
  }
  readCal();

  // write header to serial port
  Serial.print("# time,ambient,T1,rate1");
  if( chan.getNumActv() >= 2 ) Serial.print(",T2,rate2");
  if( chan.getNumActv() >= 3 ) Serial.print(",T3,rate3");
  if( chan.getNumActv() >= 4 ) Serial.print(",T4,rate4");
  Serial.println();

  userloop = cycle;
  uint16_t dADC = adc.getConvTime();
  uint16_t tconv = amb.getConvTime();
  tconv = tconv > dADC ? tconv : dADC;
  uint16_t n = ( chan.getNumActv() * tconv + 50 ) / _LOOP_INCR + 1;
  looptime = _LOOP_INCR * n;
  looptime = ( cycle > looptime ) ? cycle : looptime;
  timestamp = 0.0;
  delay( 800 ); // to show banner
  nextLoop = millis() + 100; // allow 100ms float
  reftime = 0.001 * nextLoop; // initialize reftime to the time of first sample
  first = true;
  if( lcd != NULL ) lcd->clear();
}

// this is executed continuously
void appBase::run() {
  float idletime;
  uint32_t thisLoop;

  // delay loop to force update on even looptime boundaries
  while ( millis() < nextLoop ) { // delay until time for next loop
    if( /* lcd != NULL && */ buttons != NULL ) // check for button press
      checkInput();
    checkSerial(); // Has a command been received?
  }

  thisLoop = millis(); // actual time marker for this loop
  // time stamp = system time, seconds, for this set of samples
  timestamp = 0.001 * float( thisLoop ) - reftime;
  getSamples(); // retrieve values from MCP9800 and MCP3424
  if( first ) { // use first set of samples for RoR base values only
    first = false;
    initControl();
  }
  else {
    logSamples(); // output results to serial port
    doControl(); // perform control operations, if required
  }

  // save values for RoR calculation in next loop
  for( int j = 0; j < _NCHAN; j++ ) {
   int k = chan.getChan( j );
   if( k != 0 ) {
     --k;
     flast[k] = ftemps[k];
     lasttimes[k] = ftimes[k];
   }
  }

  idletime = looptime - ( millis() - thisLoop );
  // complain if we don't have some time left
  if (idletime < _IDLE_TIME_ALARM ) {
    Serial.print("# idle: ");
    Serial.println(idletime);
  }

  nextLoop += looptime; // time mark for start of next update
//  Serial.print("nextLoop="); Serial.print( nextLoop );
//  Serial.print("   looptime="); Serial.print( looptime );
//  Serial.println();
}

// retrieves samples from each active channel; returns true if values in limits
boolean appBase::getSamples()
{
  int32_t v,vt;
  float tempC;
  boolean isOK = true;
  uint16_t dly = amb.getConvTime(); // use delay based on slowest conversion
  uint16_t dADC = adc.getConvTime();
  dly = dly > dADC ? dly : dADC;

  for( uint8_t j = 0; j < _NCHAN; j++ ) { // one-shot conversions on both chips
    uint8_t k = chan.getChan( j );
    if( k != 0 ) {
      --k; // now k = physical ADC channel number
      adc.nextConversion( k ); // start ADC conversion on channel k
      amb.nextConversion(); // start ambient sensor conversion
      activeDelay( dly ); // give the chips time to perform the conversions
      ftimes[k] = millis(); // record timestamp for RoR calculations
      amb.readSensor(); // retrieve value from ambient temp register
      v = adc.readuV(); // retrieve microvolt sample from MCP3424
      isOK = checkLimits( v, j );  // v and j are available to calling program
      if( isOK ) {
        tempC = TC->Temp_C( 0.001 * v, amb.getAmbC() ); // convert to Celsius
        if( celsius )
          vt = round( tempC / _D_MULT ); // store results as integers
        else
          vt = round( C_TO_F( tempC ) / _D_MULT ); // store results as integers
        temps[k] = fT[k].doFilter( vt ); // apply digital filtering for display/logging
        ftemps[k] =fRise[k].doFilter( vt ); // filtering for RoR
      }
      else break;  // abort remaining samples if one is bad
    }
  }
  return isOK;
}

// active delay loop
void appBase::activeDelay( uint32_t ms ) { // this is an active delay loop
  uint32_t tod = millis();
  while( millis() < tod + ms ) {
    checkInput();
    // don't check serial here because we don't want to be caught between samples
    // when a command is executed
  }
}

// check for user input (probably button press)
void appBase::checkInput() { // take action if a button is pressed
  if( buttons == NULL ) return; // just to be safe
  if( buttons->readButtons() ) {
    if( buttons->keyPressed( 3 ) && buttons->keyChanged( 3 ) ) {// left button = start the roast
      Serial.print( "# STRT,");
      Serial.println( timestamp, _DP );
      buttons->ledOn ( 2 ); // turn on leftmost LED when start button is pushed
    }
    else if( buttons->keyPressed( 2 ) && buttons->keyChanged( 2 ) ) { // 2nd button marks first crack
      Serial.print( "# FC,");
      Serial.println( timestamp, _DP );
      buttons->ledOn ( 1 ); // turn on middle LED at first crack
    }
    else if( buttons->keyPressed( 1 ) && buttons->keyChanged( 1 ) ) { // 3rd button marks second crack
      Serial.print( "# SC,");
      Serial.println( timestamp, _DP );
      buttons->ledOn ( 0 ); // turn on rightmost LED at second crack
    }
    else if( buttons->keyPressed( 0 ) && buttons->keyChanged( 0 ) ) { // 4th button marks eject
      Serial.print( "# EJCT,");
      Serial.println( timestamp, _DP );
      buttons->ledAllOff(); // turn off all LED's when beans are ejected
    }
  }
}

// ------------------------------------------------------------------
void appBase::logSamples() { // log one set of samples to the serial port
  float t1 = 0.0; // first two active channels
  float t2 = 0.0;
  float rx;
  float RoR = 0.0;
  float t;
  boolean frst = false;
  boolean scnd = false;

  // print timestamp from when samples were taken
  Serial.print( timestamp, _DP );

  // print ambient
  Serial.print(",");
  if( celsius )
    Serial.print( amb.getAmbC(), _DP );
  else
    Serial.print( amb.getAmbF(), _DP );

  // print temperature, rate for each active channel
  for( uint8_t i = 0; i < _NCHAN; i++ ) {
    uint8_t k = chan.getChan( i );
    if( k != 0 ) {  // if zero, then channel not active
      --k; // now k will contain the physical ADC channel ID, 0 to 3
      Serial.print(",");
      Serial.print( t = _D_MULT*temps[k], _DP ); // temp on logical channel i
      Serial.print(",");
      // rx = rise rate of current channel
      rx = calcRise( flast[k], ftemps[k], lasttimes[k], ftimes[k] );
      // perform post-filtering on RoR values
      rx = fRoR[k].doFilter( rx /  _D_MULT ) * _D_MULT;
      Serial.print( rx , _DP ); // print post-filtered RoR for logical channel i
      // capture the values from the first two active channels
      if( !frst ) {
        frst = true;
        t1 = t;
        RoR = rx;
      }
      else if( frst && !scnd ) {
        scnd = true;
        t2 = t;
      }
    }
  }
  Serial.println();

  // display the values from the first two active channels
  if( lcd != NULL )
    updateLCD( timestamp, t1, t2, RoR );
}

// T1, T2 = temperatures x 1000
// t1, t2 = time marks, milliseconds
// ---------------------------------------------------
float appBase::calcRise( int32_t T1, int32_t T2, int32_t t1, int32_t t2 ) {
  int32_t dt = t2 - t1;
  if( dt <= 0 ) return 0.0;  // check for bad input data
  float dT = (T2 - T1) * _D_MULT;
  float dS = dt * 0.001; // convert from milli-seconds to seconds
  return ( dT / dS ) * 60.0; // rise per minute
}

// --------------------------------------------
void appBase::updateLCD( float time, float t1, float t2, float RoR, float x5, float x6 ) {
  if( lcd == NULL ) return;
  char smin[3],ssec[3],st1[6],st2[6],sRoR1[7];
  // form the timer output string in min:sec format
  int itod = round( time );
  if( itod > 3599 ) itod = 3599;
  sprintf( smin, "%02u", itod / 60 );
  sprintf( ssec, "%02u", itod % 60 );
  lcd->setCursor(0,0);
  lcd->print( smin );
  lcd->print( ":" );
  lcd->print( ssec );

  // channel 2 temperature
  int it02 = round( t2 );
  if( it02 > 999 ) it02 = 999;
  else if( it02 < -999 ) it02 = -999;
  sprintf( st2, "%3d", it02 );
  lcd->setCursor( 11, 0 );
  lcd->print( "E " );
  lcd->print( st2 );

  // channel 1 RoR
  int iRoR = round( RoR );
  if( iRoR > 99 )
    iRoR = 99;
  else
   if( iRoR < -99 ) iRoR = -99;
  sprintf( sRoR1, "%0+3d", iRoR );
  lcd->setCursor(0,1);
  lcd->print( "RoR1:");
  lcd->print( sRoR1 );

  // channel 1 temperature
  int it01 = round( t1 );
  if( it01 > 999 )
    it01 = 999;
  else
    if( it01 < -999 ) it01 = -999;
  sprintf( st1, "%3d", it01 );
  lcd->setCursor( 11, 1 );
  lcd->print("B ");
  lcd->print(st1);
}

// ------------------------------------------------------------------
// class rstCmnd
rstCmnd::rstCmnd( appBase* parent, boolean ak ) :
  appCmnd ( _RESET, parent, ak ) {
}

// respond to the command
boolean rstCmnd::doCommand( CmndParser* pars ) {
  if( app != NULL && ( strcmp( keyword, pars->cmndName() ) == 0 ) ) {
    if( ack ) {
      Serial.print( "# Reset, " );
      Serial.println( app->getTimeStamp() ); // write message to log
    }
    uint32_t nloop = 10 + millis();
    app->setNextLoop( nloop ); // wait 10 ms and force a sample/log cycle
    app->setRefTime( 0.001 * nloop ); // reset the reference point for timestamp
    return true;
  }
  else
    return false;
}

// ------------------------------------------------------------------
// class readCmnd
readCmnd::readCmnd( appBase* parent, boolean ak ) :
  appCmnd ( _READ, parent ) {
}

// respond to the command
boolean readCmnd::doCommand( CmndParser* pars ) {
  if( app != NULL && ( strcmp( keyword, pars->cmndName() ) == 0 ) ) {
    app->logSamples();
    return true;
  }
  else
    return false;
}

// ------------------------------------------
// class chanCmnd::chanCmnd() :
// execute the CHAN command
// CHAN;ijkl\n
chanCmnd::chanCmnd( appBase* parent, boolean ak ) :
  appCmnd( _CHAN, parent, ak ) {
}

// respond to the chan command
boolean chanCmnd::doCommand( CmndParser* pars ) {
  if( strcmp( keyword, pars->cmndName() ) == 0 ) {
    char str[2];
    uint8_t a[_NCHAN];
    uint8_t n;
    uint8_t len = strlen( pars->paramStr(1) );
    if( len == _NCHAN ) { // must match number of channels or take no action
      for( int i = 0; i < len; i++ ) {
        str[0] = pars->paramStr(1)[i]; // next character
        str[1] = '\0'; // force it to be char[2]
        n = atoi( str );
        if( n <= _NCHAN )
          a[i] = n;
        else
          a[i] = 0;
      }
      app->setActiveChannels( a[0], a[1], a[2], a[3] );
      if( ack ) {
        Serial.print("# Active channels set to ");
        Serial.println( pars->paramStr(1) );
      }
    }
    return true;
  }
  else {
    return false;
  }
}

// ------------------------------------------------------------------
// class uintsCmnd
unitsCmnd::unitsCmnd( appBase* parent, boolean ak ) :
  appCmnd ( _UNITS, parent, ak ) {
}

// respond to the command
boolean unitsCmnd::doCommand( CmndParser* pars ) {
  if( strcmp( keyword, pars->cmndName() ) == 0 ) {
    if( strcmp( pars->paramStr(1), "F" ) == 0 ) {
      app->setUnits('F');
      if( ack )
        Serial.println("# Changed units to F");
      return true;
    }
    else if( strcmp( pars->paramStr(1), "C" ) == 0 ) {
      app->setUnits('C');
      if( ack )
        Serial.println("# Changed units to C");
      return true;
    }
  }
  return false;
}

// --------------------------------------------------------
// class appSerialRst

// constructor
appSerialRst::appSerialRst( tcBase* tc, uint8_t ADCaddr, uint8_t ambaddr, uint8_t epaddr ) :
  appBase( tc, ADCaddr, ambaddr, epaddr ),
  rst( this, true ) {
  addCommand( &rst ); // reset command supported
}

// --------------------------------------------------------------------
// class appSerialComm

// constructor
appSerialComm::appSerialComm( tcBase* tc, uint8_t ADCaddr, uint8_t ambaddr, uint8_t epaddr ) :
  appSerialRst( tc, ADCaddr, ambaddr, epaddr ),
  chn( this, true ), // ack is sent by TC4
  rd( this, true ),
  un( this, true ) // ack is sent by TC4
{
  addCommand( &chn );  // channel command
  addCommand( &rd );  // read command
  addCommand( &un );  // units command
}

