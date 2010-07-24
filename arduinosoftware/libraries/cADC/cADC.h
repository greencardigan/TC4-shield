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
 
#ifndef _cADC_H
#define _cADC_H

#include <Wire.h>
#include <WProgram.h>

// -------------- ADC configuration
#define ADC_RDY 7  // ready bit
#define ADC_C1  6  // channel selection bit 1
#define ADC_C0  5  // channel selection bit 0
#define ADC_CMB 4  // conversion mode bit (1 = continuous)
#define ADC_SR1 3  // sample rate selection bit 1 (11 = 18 bit)
#define ADC_SR0 2  // sample rate selection bit 0
#define ADC_G1  1  // gain select bit 1
#define ADC_G0  0  // gain select bit 0

#define CFG1 (_BV(ADC_CMB) | _BV(ADC_SR1) | _BV(ADC_SR0) ) // 18 bit, gain = 1
#define CFG2 (_BV(ADC_CMB) | _BV(ADC_SR1) | _BV(ADC_SR0) | _BV(ADC_G0) ) // 18 bit, gain = 2 
#define CFG4 (_BV(ADC_CMB) | _BV(ADC_SR1) | _BV(ADC_SR0) | _BV(ADC_G1) ) // 18 bit, gain = 4 
#define CFG8 (_BV(ADC_CMB) | _BV(ADC_SR1) | _BV(ADC_SR0) | _BV(ADC_G1) | _BV(ADC_G0) ) // 18 bit, gain = 8

#define A_BITS9  B00000000
#define A_BITS10 B00100000
#define A_BITS11 B01000000
#define A_BITS12 B01100000

#define BITS_TO_uV 15.625  // LSB = 15.625 uV

// ---------------------------- calibration of ADC and ambient temp sensor
// fixme -- put this information in EEPROM
#define CAL_OFFSET  ( 0 )  // microvolts
#define CAL_GAIN 1.0035

// I2C address
#define A_ADC 0x68

// --------------------------------------------------------------
class cADC {
 public:
  cADC( uint8_t addr ); // constructor
  void initADC();  // set up the ADC
  int32_t getuV( byte& chan ); // retrieves sample and converts to uV
  void nextConversion( byte chan );  // sets up the next conversion
 protected:
 private:
  byte cfg;
  uint8_t a_adc;
  float cal_gain;
  float cal_offset;
};


// -------------------- MCP9800 configuration
#define RES_12 // use 12-bit resolution by default

#ifdef RES_12
#define A_BITS A_BITS12
#endif
#ifdef RES_11
#define A_BITS A_BITS11
#endif
#ifdef RES_10
#define A_BITS A_BITS10
#endif
#ifdef RES_9
#define A_BITS A_BITS9
#endif

// I2C address for MCP9800
#define A_AMB 0x48

#define MCP9800_DELAY 250 // sample period for MCP9800

#define NAMBIENT 4  // number of ambient samples to be averaged
#define TEMP_OFFSET ( 0.0 )  // Celsius offset -- fixme read from EEPROM
#define MAX_AMB 8 // array size for ambient samples
#define AMB_LSB 0.0625 // value of MCP9800 LSB in 12-bit mode

// ----------------------------------------------------------
// this class communicates with MCP9800 ambient sensor and performs averaging
class ambSensor {
 public:
  ambSensor( uint8_t addr, int navg ); // default constructor
  void config(); // configure the MCP9800
  void init(); // initialize array for averaging
  int32_t calcAvg(); // updates and returns average amb temp
  int32_t getCurrent(); // returns current value of averaged amb. temp
  int32_t readAmbientC(); // returns 16x the ambient Celsius temperature
  float getOffset(); // returns calibration information
  void setOffset( float tempC ); // allows override of default offset
 protected:
 private:
  int nsamp; // number of samples for averaging
  float temp_offset;  // calibration data
  uint8_t a_amb;  // I2C address
  int32_t sumamb; // used for averaging
  int32_t avgamb;
  int32_t current; // current value of ambient temp
  int32_t ambs[MAX_AMB];
};


#endif
