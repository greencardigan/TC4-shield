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

#include <cADC.h>

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
  cfg = CFG8;  // select gain = 8 as default
//  cfg = B10001111;
  a_adc = addr; // address of ADC chip
  cal_gain = CAL_GAIN;
  cal_offset = CAL_OFFSET;
}

// --------------------------------------------------setCal
void cADC::setCal( float gain, int8_t offs ) {
  cal_gain = gain;
  cal_offset = offs;
};

// -----------------------------------------------------------
int32_t cADC::readuV() {
  uint8_t stat;
  uint8_t a, b, c, gain;
  int32_t v;
  float xv;
  
  Wire.requestFrom( a_adc, (uint8_t)4 );
  a = Wire.receive();
  b = Wire.receive();
  c = Wire.receive();
  stat = Wire.receive();
  gain = stat & B11;

  v = a;
  v <<= 24;
  v >>= 16;
  v |= b;
  v <<= 8;
  v |= c;

// convert to microvolts
  xv = v;
  v = round( xv * BITS_TO_uV );
  // divide by gain
  v >>= gain;
  v *= cal_gain;    // calibration of gain
  v += cal_offset;  // adjust calibration offset
  return v;
};

// -------------------------------------
void cADC::nextConversion( uint8_t chan ) {
  Wire.beginTransmission( a_adc );
  Wire.send( cfg | ( chan << 5 ) );
  Wire.endTransmission();
};

// ----------------------------------------------------------- ambSensor
ambSensor::ambSensor( uint8_t addr ) {
 a_amb = addr; // I2C address
};

// ------------------------------------------------
void ambSensor::init( int fpercent ) {
  filter.init( fpercent );
  Wire.beginTransmission( a_amb );
  Wire.send(1); // point to config reg
  Wire.send( (uint8_t)SHUTDOWN );  // have to start in shutdown mode for one-shot conversions
  Wire.endTransmission();
};

// -----------------------------------------
void ambSensor::nextConversion() {
  Wire.beginTransmission( a_amb );
  Wire.send( 1 ); // configuration register
  Wire.send( A_BITS ); // request a one-shot conversion
  Wire.endTransmission();
}

// -----------------------------------------
int32_t ambSensor::readSensor() {
  byte a, b;
  int32_t va, vb;

  Wire.beginTransmission( a_amb );
  Wire.send(0); // point to temperature reg.
  Wire.endTransmission();
  Wire.requestFrom( a_amb, (uint8_t)2 );
  va = a = Wire.receive();
  vb = b = Wire.receive();
  
#ifdef RES_12
// 12-bit code
  raw = ( ( va << 8 ) +  vb ) >> 4; // LSB = 0.0625C
#endif
#ifdef RES_11
// 11-bit code
  raw = ( ( va << 8 ) +  vb ) >> 5; // LSB = 0.125C
  raw <<= 1;
#endif
#ifdef RES_10
// 10-bit code
  raw = ( ( va << 8 ) +  vb ) >> 6; // LSB = 0.25C
  raw <<= 2;
#endif
#ifdef RES_9
// 9-bit code
  raw = ( ( va << 8 ) +  vb ) >> 7; // LSB = 0.5C
  raw <<= 3;
#endif

  filtered = filter.doFilter( raw );
  ambC = (float)filtered * AMB_LSB + temp_offset;
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

