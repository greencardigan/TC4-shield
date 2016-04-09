// cADC library
// Version date: August 20, 2010
// interface with MCP3424 18-bit ADC

// *** BSD License ***
// ------------------------------------------------------------------------------------------
// Copyright (c) 2010, MLG Properties, LLC
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

// Acknowledgement is given to Bill Welch for his development of the prototype hardware and software 
// upon which much of this library is based.

// 20110609  Significant revision for flexibility in selecting modes of operation
// 20120126  Arduino 1.0 compatibility
//  (thanks and acknowledgement to Arnaud Kodeck for his code contributions).

#include "cADC.h"

#if defined(ARDUINO) && ARDUINO >= 100
#define _READ read
#define _WRITE write
#else
#define _READ receive
#define _WRITE send
#endif

// --------------------------------------------------- dFilterRC
filterRC::filterRC() {
 level = 0;
 y = 0;
 first = true;
};

// ----------------------------------------------------
void filterRC::init( int32_t percent ) {
 level = percent;
 first = true;
};

// ------------------------------------
int32_t filterRC::doFilter ( int32_t xi ) {
   if( first) {
     y = xi;
     first = false;
     return y;
   }
   float yy = (float)(100 - level) * (float)xi * 0.01;
   float yyy = (float)level * (float)y * 0.01;
   yy += yyy;
   return y = round( yy );
};

// ----------------------------------------------------------
cADC::cADC( uint8_t addr ) {
  a_adc = addr; // address of ADC chip
  cal_gain = CAL_GAIN;
  cal_offset = CAL_OFFSET;
  setCfg( ADC_BITS_18, ADC_GAIN_8, ADC_CONV_1SHOT ); // 18 bit, 8X, 1 shot
}

// --------------------------------------------------setCfg
void cADC::setCfg( uint8_t res, uint8_t gain, uint8_t conv  ){
  cfg = res | gain | conv;
  // set uV value of the LSB for conversions to uV
  switch ( res ){
    case ADC_BITS_12 :
      convTime = _CONV_TIME_12;
      nLSB = 0;  // bit shift count = ADC_BITS - 12
      break;
    case ADC_BITS_14 :
      convTime = _CONV_TIME_14;
      nLSB = 2;  // bit shift count = ADC_BITS - 12
      break;
    case ADC_BITS_16 :
      convTime = _CONV_TIME_16;
      nLSB = 4;  // bit shift count = ADC_BITS - 12
      break;
    case ADC_BITS_18 :
      convTime = _CONV_TIME_18;
      nLSB = 6;  // bit shift count = ADC_BITS - 12
      break;
    default :
      convTime = _CONV_TIME_18;
      nLSB = 6;  // bit shift count = ADC_BITS - 12
  }
}

// -------------------------------------------------- getConvTime
uint16_t cADC::getConvTime() {
  return convTime;
}

// --------------------------------------------------setCal
void cADC::setCal( float gain, int8_t offs ) {
  cal_gain = gain - 1.0;  // to reduce loss of significance
  cal_offset = offs;
};

// -----------------------------------------------------------
int32_t cADC::readuV() {
  int32_t v;
  // resolution determines number of bytes requested
  if( ( cfg & ADC_RES_MASK ) == ADC_BITS_18 ) { // 3 data bytes
    Wire.requestFrom( a_adc, (uint8_t) 4 );
    uint8_t a = Wire._READ(); // first data byte
    uint8_t b = Wire._READ(); // second data byte
    uint8_t c = Wire._READ(); // 3rd data byte
    v = a;
    v <<= 24; // v = a : 0 : 0 : 0
    v >>= 16; // v = s : s : a : 0
    v |= b; //   v = s : s : a : b
    v <<= 8; //  v = s : a : b : 0
    v |= c; //   v = s : a : b : c
  }
  else { // 2 data bytes
    Wire.requestFrom( a_adc, (uint8_t) 3 );
    uint8_t a = Wire._READ(); // first data byte
    uint8_t b = Wire._READ(); // second data byte
    v = a;
    v <<= 24; // v = a : 0 : 0 : 0
    v >>= 16; // v = s : s : a : 0
    v |= b; //   v = s : s : a : b
  }
  uint8_t stat = Wire._READ(); // read the status byte returned from the ADC
  v *= 1000;  // convert to uV.  This cannot overflow ( 10 bits + 18 bits < 31 bits )
  // bit shift count for ADC gain
  uint8_t gn = stat & ADC_GAIN_MASK;
  // shift based on ADC resolution plus ADC gain
  v >>= ( nLSB + gn ); // v = raw reading, uV
  // calculate effect of external calibration gain; minimize loss of significance
  int32_t deltaV = round( (float)v * cal_gain );
  return v + deltaV;  // returns corrected, unfiltered value of uV
};

// -------------------------------------
void cADC::nextConversion( uint8_t chan ) {
  Wire.beginTransmission( a_adc );
  Wire._WRITE( cfg | ( ( chan & B00000011 ) << ADC_C0 ) );
  Wire.endTransmission();
};

// ----------------------------------------------------------- ambSensor
ambSensor::ambSensor( uint8_t addr ) {
 a_amb = addr; // I2C address
 filter.init( 0 );
 setCfg( AMB_BITS_12 ); // default is 12 bits
}

// -----------------------------------------
// sets up the configuration byte
void ambSensor::setCfg( uint8_t res ) {
  cfg = res | convMode;
  switch ( res ) {
    case AMB_BITS_9 :
      convTime = _AMB_CONV_TIME_9;
      nLSB = 7;  // shift count
      break;
    case AMB_BITS_10 :
      convTime = _AMB_CONV_TIME_10;
      nLSB = 6;  // shift count
      break;
    case AMB_BITS_11 :
      convTime = _AMB_CONV_TIME_11;
      nLSB = 5;  // shift count
      break;
    case AMB_BITS_12 :
      convTime = _AMB_CONV_TIME_12;
      nLSB = 4;  // shift count
      break;
  }
}

// -----------------------------------------
// returns minimum time required for a conversion
uint16_t ambSensor::getConvTime() {
  return convTime;
}

// -----------------------------------------
// puts the 9800 in shutdown.  Required for one-shot mode
void ambSensor::ambShutdown() {
  Wire.beginTransmission( a_amb );
  Wire._WRITE( AMB_REGSEL_CFG ); // point to config reg
  Wire._WRITE( (uint8_t)AMB_SHUTDOWN );
  Wire.endTransmission();
  // delay needed here?
}

// ------------------------------------------------
void ambSensor::init( int fpercent, uint8_t cmode ) {
  filter.init( fpercent );
  convMode = cmode;
  if( cmode == AMB_CONV_1SHOT )
    ambShutdown();
}

// -----------------------------------------
void ambSensor::nextConversion() {
  Wire.beginTransmission( a_amb );
  Wire._WRITE( (uint8_t)AMB_REGSEL_CFG ); // configuration register
  Wire._WRITE( cfg ); // request a conversion
  Wire.endTransmission();
}

// -----------------------------------------
int32_t ambSensor::readSensor() {
  uint8_t a, b;
  Wire.beginTransmission( a_amb );
  Wire._WRITE( (uint8_t)AMB_REGSEL_TMP ); // point to temperature reg.
  Wire.endTransmission();
  Wire.requestFrom( a_amb, (uint8_t)2 );
  a = Wire._READ();
  b = Wire._READ();
  raw = a;     //  0 : 0 : 0 : a
  raw <<= 24;   // a : 0 : 0 : 0
  raw >>= 16;  //  s : s : a : 0
  raw |= b;    //  s : s : a : b
  // 12-bit, nLSB = 4
  // 11-bit, nLSB = 5
  // 10-bit, nLSB = 6
  //  9-bit, nLSB = 7
  raw >>= nLSB;  // first nLSB bits in b are undefined
  raw <<= nLSB;  // they are gone now, replaced by zero
  raw >>= 4;  // move bits to right to form raw code
  filtered = filter.doFilter( raw << AMB_FACTOR ); // create more resolution for filter
  ambC = (float)filtered;
  ambC += temp_offset * AMB_LSB_INV;  // calibration correction
  ambC *= AMB_LSB;  // Ta = code / 16 per MCP9800 datasheet
  ambF = 1.8 * ambC + 32.0;
  return filtered;
};

// -----------------------------------
float ambSensor::getAmbC() { return ambC; }
float ambSensor::getAmbF() { return ambF; }

// ------------------------------------
float ambSensor::getOffset() {
 return temp_offset;
};

// ---------------------------------------
void ambSensor::setOffset( float tempC ) {
 temp_offset = tempC;
};

#undef _READ
#undef _WRITE

