// cADC library

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
 
// Revision history:
//  Original version date: 9-June-2011
//  20110609  Revisions to cADC for greater control over mode selection
//  20120126:  Compatibility with Arduino 1.0
//    (thanks and acknowledgement to Arnaud Kodeck for his code contributions).

#ifndef _cADC_H
#define _cADC_H

#include <Wire.h>

#if defined(ARDUINO) && ARDUINO >= 100
#include <Arduino.h>
#else
#include <WProgram.h>
#endif

// -------------------------------------------------------------------
// class for digital filtering of raw signals
class filterRC {
public:
 filterRC();
 void init( int32_t percent );
 int32_t doFilter( int32_t xi );
protected:
 int32_t level; // filtering level, 0 to 100%
 int32_t y; // most recent value of function
 bool first; // special handling of first call
};

// -------------- ADC configuration
#define ADC_RDY 7  // ready bit
#define ADC_C1  6  // channel selection bit 1
#define ADC_C0  5  // channel selection bit 0
#define ADC_CMB 4  // conversion mode bit (1 = continuous 0 = one shot)
#define ADC_SR1 3  // sample rate selection bit 1 (11 = 18 bit)
#define ADC_SR0 2  // sample rate selection bit 0
#define ADC_G1  1  // gain select bit 1
#define ADC_G0  0  // gain select bit 0

#define ADC_GAIN_MASK ( _BV(ADC_G1) | _BV(ADC_G0) )
#define ADC_RES_MASK  ( _BV(ADC_SR1) | _BV(ADC_SR0) )

// some 3424 config register values
#define ADC_BITS_18 ( _BV(ADC_SR1) | _BV(ADC_SR0) )
#define ADC_BITS_16 ( _BV(ADC_SR1) )
#define ADC_BITS_14 ( _BV(ADC_SR0) )
#define ADC_BITS_12 0
#define ADC_GAIN_8 ( _BV(ADC_G1) | _BV(ADC_G0) )
#define ADC_GAIN_4 ( _BV(ADC_G1) )
#define ADC_GAIN_2 ( _BV(ADC_G0) )
#define ADC_GAIN_1 0
#define ADC_CHAN_4 ( _BV(ADC_C1) | _BV(ADC_C0) )
#define ADC_CHAN_3 ( _BV(ADC_C1) )
#define ADC_CHAN_2 ( _BV(ADC_C0) )
#define ADC_CHAN_1 0
#define ADC_CONV_CONT  ( _BV(ADC_CMB) )
#define ADC_CONV_1SHOT ( _BV(ADC_RDY) )

// calibration of ADC
#define CAL_OFFSET  ( 0 )  // microvolts
#define CAL_GAIN 1.00

// ADC I2C address
#define A_ADC 0x68

#define BITS_TO_uV 15.625  // LSB = 15.625 uV, 18 bit mode
#define MAX_CHAN 4 // maximum number of channels to sample
#define _CONV_TIME_18 300 // millis
#define _CONV_TIME_16 80 // millis
#define _CONV_TIME_14 20 // millis
#define _CONV_TIME_12 5 // millis

// --------------------------------------------------------------
class cADC {
 public:
  cADC( uint8_t addr = A_ADC ); // constructor
  int32_t readuV(); // retrieves sample and converts to uV
  void nextConversion( uint8_t chan );  // requests the next conversion
  void setCal( float gaincal, int8_t offs ); // sets calibration gain/offset for 50000 uV and 0 uV
  void setCfg( uint8_t resolution = ADC_BITS_18, uint8_t gain = ADC_GAIN_8, uint8_t conversion = ADC_CONV_1SHOT );
  uint16_t getConvTime(); // returns time required for a conversion
 protected:
  uint8_t cfg; // resolution, gain, and conversion mode settings
  uint8_t a_adc;
  float cal_gain; // = calibration factor minus 1.0000
  int8_t cal_offset;
  uint16_t convTime;  // milliseconds
//  float xLSB;  // microvolt value of LSB
  // LSB uV = 1,000 * 2^12 / 2^n, where n = ADC resolution bits
  uint8_t nLSB; // shift count = resolution bits minus 12
};

// -------------------- MCP9800 configuration

#define AMB_REGSEL_CFG B00000001
#define AMB_REGSEL_TMP B00000000

// configuration register bits
#define AMB_CFG_CONV 7 // 1 shot vs continuous
#define AMB_CFG_RES1 6 // resolution MSB
#define AMB_CFG_RES0 5 // resolution LSB
#define AMB_CFG_FLT1 4 // fault queue
#define AMB_CFG_FLT0 3 // fault queue
#define AMB_CFG_PLRT 2 // active polarity
#define AMB_CFG_COMP 1 // comparator
#define AMB_CFG_SHUT 0 // shutdown

#define AMB_BITS_9  0
#define AMB_BITS_10 ( _BV( AMB_CFG_RES0 ) )
#define AMB_BITS_11 ( _BV( AMB_CFG_RES1 ) )
#define AMB_BITS_12 ( _BV( AMB_CFG_RES1 ) | _BV( AMB_CFG_RES0 ) )
#define AMB_SHUTDOWN ( _BV( AMB_CFG_SHUT ) )
#define AMB_CONV_1SHOT ( _BV( AMB_CFG_CONV ) | _BV( AMB_CFG_SHUT ) )
#define AMB_CONV_CONT 0
#define AMB_CONV_MASK ( _BV( AMB_CFG_CONV ) | _BV( AMB_CFG_SHUT ) )

#define _AMB_CONV_TIME_9 38 // 9-bit conversion time
#define _AMB_CONV_TIME_10 75 // 10-bit conversion time
#define _AMB_CONV_TIME_11 150 // 11-bit conversion time
#define _AMB_CONV_TIME_12 290 // 12-bit conversion time

#define A_AMB 0x48 // I2C address for MCP9800
//#define MCP9800_DELAY _AMB_CONV_TIME_12 // minimum sample period for MCP9800
#define TEMP_OFFSET ( 0.0 )  // Celsius offset
#define AMB_FACTOR 10 // n << 10 = 1024 use to create some additional resolution
#define AMB_LSB (0.0625/1024) // value of MCP9800 LSB in 12-bit mode, div. by 1000
#define AMB_LSB_INV (16.0*1024) // reciprocal of AMB_LSB

// ----------------------------------------------------------
// this class communicates with MCP9800 ambient sensor and optionally performs filtering
class ambSensor {
 public:
  ambSensor( uint8_t addr = A_AMB ); // default constructor
  void init( int fpercent = 0, uint8_t cmode = AMB_CONV_1SHOT ); // setup the MCP9800, initialize the filter
  void nextConversion(); // instruct 9800 to perform a conversion
  int32_t readSensor(); // reads chip, returns 16x the ambient Celsius temperature
  float getAmbF(); // computes and returns current F
  float getAmbC(); // computes and returns current C
  float getOffset(); // returns calibration information
  void setOffset( float tempC ); // set calibration offset
  void setCfg( uint8_t res );
  uint16_t getConvTime();
  void ambShutdown(); // put the 9800 in shutdown mode (must follow Wire.begin() )
 protected:
  uint8_t cfg; // configuration byte
  uint8_t convMode; // AMB_CONV_1SHOT or AMB_CONV_CONT
  uint16_t convTime; // required delay between conversions
  uint8_t nLSB;  // shift count to get rid of insignificant bits
  uint8_t a_amb;  // I2C address
  filterRC filter;
  float temp_offset;  // calibration offset (Celsius)
  float ambF, ambC; // most recent filtered readings
  int32_t filtered; // up to date filtered raw reading
  int32_t raw; // most recent raw sensor reading
};

#endif
