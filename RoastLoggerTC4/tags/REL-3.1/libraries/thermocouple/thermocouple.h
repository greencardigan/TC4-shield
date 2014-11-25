// thermocouple.h
// Version 20110615
// Revision history:
//  20120126: Compatibility with Arduino 1.0


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

#ifndef THERMOCOUPLE_H_
#define THERMOCOUPLE_H_

#if defined(ARDUINO) && ARDUINO >= 100
#include <Arduino.h>
#else
#include <WProgram.h>
#endif

#include <avr/pgmspace.h>

#define TC_RANGE_ERR 16000.0
#define C_TO_F(x) ( 1.8 * x + 32.0 )
#define F_TO_C(x) ( ( x - 32.0 ) / 1.8 )

typedef float FLOAT;
typedef float PFLOAT;

// ----------------- base class for thermocouples
//
class tcBase { // pure virtual base class
  public:
    tcBase();
    FLOAT Temp_C( FLOAT mV, FLOAT coldC = 0 );  // returns temperature referenced to coldC
    FLOAT Temp_F( FLOAT mV, FLOAT coldF = 0 );  // returns temperature referenced to coldF

    FLOAT mV_F ( FLOAT tempF );  // returns emf for temp referenced to 32F
    FLOAT mV_C ( FLOAT tempC );  // returns emf for temp referenced to 0C
    bool inrange_mV( FLOAT mV );
    bool inrange_C( FLOAT tempC );
    bool inrange_F( FLOAT tempF ){return inrange_C( F_TO_C( inrange_C( tempF ) ) );}
    virtual FLOAT mv_min() = 0;
    virtual FLOAT mv_max() = 0;
    virtual FLOAT C_max() = 0;
    virtual FLOAT C_min() = 0;

  protected:
    virtual FLOAT absTemp_C( FLOAT mV ) = 0;   // returns temperature (referenced to 0C) for mV
    virtual FLOAT absMV_C( FLOAT tempC ) = 0;  // returns raw mV reading for temp referenced to 0C
    virtual FLOAT _poly( FLOAT x, const FLOAT* coeff, uint8_t nrows, uint8_t ncols );
};

class tcLinear : public tcBase { // basic linear approximation
  public:
    tcLinear( FLOAT mVperC );
    FLOAT Temp_C( FLOAT mV );
    virtual FLOAT mv_min(){ return -6.00; }
    virtual FLOAT mv_max(){ return 55.00; }
    virtual FLOAT C_max() { return 1500.00; }
    virtual FLOAT C_min() { return -300.00; }
  protected:
    virtual FLOAT absTemp_C( FLOAT mV );   // returns temperature (referenced to 0C) for mV
    virtual FLOAT absMV_C( FLOAT C );
  private:
    FLOAT slope;
};

// ----------------- ITS-90 linearization of type K thermocouples
//
class typeK : public tcBase {
  public:
    typeK();
  protected:
    virtual FLOAT absTemp_C( FLOAT mV );   // returns temperature (referenced to 0C) for mV
    virtual FLOAT absMV_C( FLOAT tempC );
    virtual FLOAT mv_min(){ return pgm_read_float_near( &range_inv[0][0] ); }
    virtual FLOAT mv_max(){ return pgm_read_float_near( &range_inv[1][2] ); }
    virtual FLOAT C_max(){ return pgm_read_float_near( &range_dir[1][1] ); }
    virtual FLOAT C_min(){ return pgm_read_float_near( &range_dir[0][0] ); }
  private:    
    // inverse coefficients
    static PROGMEM const PFLOAT coeff_inv[10][3];
    static PROGMEM const PFLOAT range_inv[2][3];
    // direct coefficients
    static PROGMEM const PFLOAT coeff_dir[11][2];
    static PROGMEM const PFLOAT range_dir[2][2];
    static PROGMEM const PFLOAT a[3];
};

// ---------------------------------------------------
class typeT : public tcBase {
  public:
    typeT();
  protected:
    virtual FLOAT absTemp_C( FLOAT mV );   // returns temperature (referenced to 0C) for mV
    virtual FLOAT absMV_C( FLOAT tempC );
    virtual FLOAT mv_min(){ return pgm_read_float_near( &range_inv[0][0] ); }
    virtual FLOAT mv_max(){ return pgm_read_float_near( &range_inv[1][1] ); }
    virtual FLOAT C_max(){ return pgm_read_float_near( &range_dir[1][1] ); }
    virtual FLOAT C_min(){ return pgm_read_float_near( &range_dir[0][0] ); }
  private:
    // inverse coefficients
    static PROGMEM const PFLOAT coeff_inv[8][2];
    static PROGMEM const PFLOAT range_inv[2][2];
    // direct coefficients
    static PROGMEM const PFLOAT coeff_dir[15][2];
    static PROGMEM const PFLOAT range_dir[2][2];
};

// ---------------------------------------------------
class typeJ : public tcBase {
  public:
    typeJ();
  protected:
    virtual FLOAT absTemp_C( FLOAT mV );   // returns temperature (referenced to 0C) for mV
    virtual FLOAT absMV_C( FLOAT tempC );
    virtual FLOAT mv_min(){ return pgm_read_float_near( &range_inv[0][0] ); }
    virtual FLOAT mv_max(){ return pgm_read_float_near( &range_inv[1][2] ); }
    virtual FLOAT C_max(){ return pgm_read_float_near( &range_dir[1][1] ); }
    virtual FLOAT C_min(){ return pgm_read_float_near( &range_dir[0][0] ); }
  private:
    // inverse coefficients
    static PROGMEM const PFLOAT coeff_inv[9][3];
    static PROGMEM const PFLOAT range_inv[2][3];
    // direct coefficients
    static PROGMEM const PFLOAT coeff_dir[9][2];
    static PROGMEM const PFLOAT range_dir[2][2];
};
#endif

