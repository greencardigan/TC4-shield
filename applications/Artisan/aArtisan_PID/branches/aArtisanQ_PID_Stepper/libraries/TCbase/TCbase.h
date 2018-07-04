// Thermocouple library per ITS-90
// Version:  20110602

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

// revised 6/2/2011 to include TCbase class

#ifndef _TCBASE_H_
#define _TCBASE_H_


#include <WProgram.h>

// ------------------- base class for thermocouples
class TCbase {
  public:
    TCbase(){}
    virtual double Temp_C( float mV ){ return 0; }   // returns temperature (referenced to 0C) for mV
    virtual double Temp_F( float mV ){ return 0; }
    virtual double Temp_C( float mV, float ambC ){ return 0; } // returns temperature referenced to ambC
    virtual double Temp_F( float mV, float ambF ){ return 0; } // returns temperature referenced to ambF
    virtual double mV_C ( float ambC ){ return 0; } // returns emf for ambient temperature
    virtual double mV_F ( float ambF ){ return 0; }
    virtual boolean inrange_mV( float mV ){ return false; }
    virtual boolean inrange_C( float ambC ){ return false; }
    virtual boolean inrange_F( float ambF ){ return false; }
};

#define TC_RANGE_ERR -99999.0
#define C_TO_F(x) ( 1.8 * x + 32.0 )
#define F_TO_C(x) ( ( x - 32.0 ) / 1.8 )

// ----------------- ITS-90 linearization of type K thermocouples
//
class typeK : public TCbase {
  public:
    typeK();
    virtual double Temp_C( float mV );   // returns temperature (referenced to 0C) for mV
    virtual double Temp_F( float mV );
    virtual double Temp_C( float mV, float ambC );  // returns temperature referenced to ambC
    virtual double Temp_F( float mV, float ambF );  // returns temperature referenced to ambF
    virtual double mV_C ( float ambC );  // returns emf for ambient temperature
    virtual double mV_F ( float ambF );
    virtual boolean inrange_mV( float mV );
    virtual boolean inrange_C( float ambC );
    virtual boolean inrange_F( float ambF );
  private:
    // inverse coefficients
    static const double coeff_inv[10][3];
    static const float range_inv[2][3];
    static const int nranges_inv;
    static const int ncoeff_inv;
    static const float mv_min;
    static const float mv_max;
    static const float C_max;
    float F_max;
    static const float C_min;
    float F_min;

    // direct coefficients
    static const double coeff_dir[11][2];
    static const double range_dir[2][2];
    static const double a[3];  
};

#endif
