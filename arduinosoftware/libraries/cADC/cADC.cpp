// cADC library
// Version date: July 24, 2010
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

// ----------------------------------------------------------
cADC::cADC( uint8_t addr ) {
  cfg = CFG8;  // select gain = 8 as default
  a_adc = addr; // address of ADC chip
  cal_gain = CAL_GAIN;
  cal_offset = CAL_OFFSET;
};

// -----------------------------------------------------------
int32_t cADC::getuV( byte& chan ) {
  int stat;
  byte a, b, c, gain;
//  byte rdy, mode, ss;
  int32_t v;
  
  Wire.requestFrom( a_adc, (uint8_t)4 );
  a = Wire.receive();
  b = Wire.receive();
  c = Wire.receive();
  stat = Wire.receive();

  // rdy = ( stat >> 7 ) & B01;
  chan = ( stat >> 5 ) & B11;
  // mode = ( stat >> 4 ) & B01;
  // ss = ( stat >> 2 ) & B11;
  gain = stat & B11;

  v = a;
  v <<= 24;
  v >>= 16;
  v |= b;
  v <<= 8;
  v |= c;

// convert to microvolts
  v = round( v * BITS_TO_uV );
  // divide by gain
  v >>= gain;
  // v /= 1 << ( gain );
  v += cal_offset;  // adjust calibration offset
  v *= cal_gain;    // calibration of gain

  return v;
};

// -------------------------------------
void cADC::nextConversion( byte chan ) {
  Wire.beginTransmission( a_adc );
  Wire.send( cfg | ( chan << 5 ) );
  Wire.endTransmission();
};

// ------------------------------------------
void cADC::initADC() {
  Wire.beginTransmission( a_adc );
  Wire.send( cfg );
  Wire.endTransmission();
};


// ----------------------------------------------------------- ambSensor
ambSensor::ambSensor( uint8_t addr, int navg ) {
 a_amb = addr; // I2C address
 if( nsamp > MAX_AMB ) nsamp = MAX_AMB;
 nsamp = navg; // number of samples for performing averaging
 if( nsamp < 1 ) nsamp = 1;
 temp_offset = TEMP_OFFSET; // fixme read calibration data from EEPROM
 sumamb = 0;
 avgamb = 0;
};

// ----------------------------------------
void ambSensor::config() {
  
  Wire.beginTransmission(A_AMB);
  Wire.send(1); // point to config reg
  Wire.send(A_BITS); 
  Wire.endTransmission();

/* debugging code disabled
  // see if we can read it back.
  byte a;
  Wire.beginTransmission(A_AMB);
  Wire.send(1); // point to config reg
  Wire.endTransmission();
  Wire.requestFrom(A_AMB, 1);
  a = 0xff;
  if (Wire.available()) {
    a = Wire.receive();
  }
  if (a != A_BITS) {
    Serial.println("# Error configuring mcp9800");
  } else {
    Serial.println("# mcp9800 Config reg OK");
  }
*/
 
};

// ------------------------------------------------
void ambSensor::init() { // populate array for averaging
 int i;
 int32_t tempC; 
 for( i = 0; i < nsamp; i++ ) {
  tempC = readAmbientC();
  delay( MCP9800_DELAY );
  sumamb += tempC;
  ambs[i] = tempC;
 }; 
};

// ----------------------------------------
int32_t ambSensor::calcAvg() {
 int i;
 if( nsamp <= 1 ) 
  return avgamb = current;
 else {
  sumamb += current - ambs[0];
  for( i = 0; i < nsamp - 1; i++ )
   ambs[i] = ambs[i+1];
  ambs[nsamp-1] = current;
  return avgamb = sumamb / nsamp;
 };
};

// -----------------------------------------------
int32_t ambSensor::getCurrent() {
 return current;
};

// -----------------------------------------
int32_t ambSensor::readAmbientC() { // returns 16X actual temp
  byte a, b;
  int32_t v, va, vb;

  Wire.beginTransmission( a_amb );
  Wire.send(0); // point to temperature reg.
  Wire.endTransmission();
  Wire.requestFrom( a_amb, (uint8_t)2 );
  va = a = Wire.receive();
  vb = b = Wire.receive();
  
#ifdef RES_12
// 12-bit code
  v = ( ( va << 8 ) +  vb ) >> 4; // LSB = 0.0625C
#endif
#ifdef RES_11
// 11-bit code
  v = ( ( va << 8 ) +  vb ) >> 5; // LSB = 0.125C
  v <<= 1;
#endif
#ifdef RES_10
// 10-bit code
  v = ( ( va << 8 ) +  vb ) >> 6; // LSB = 0.25C
  v <<= 2;
#endif
#ifdef RES_9
// 9-bit code
  v = ( ( va << 8 ) +  vb ) >> 7; // LSB = 0.5C
  v <<= 3;
#endif

 return current = v;  
};

// ------------------------------------
float ambSensor::getOffset() {
 return temp_offset;
};




