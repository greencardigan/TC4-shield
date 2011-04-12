//Modified for TypeT

// Thermocouple library per ITS-90
// Version:  20100625

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

#include "TypeT.h"
#include "WProgram.h"


// -------------------------------------
const int TypeT::nranges_inv = 2;  // number of mV ranges for inverse lookup
const int TypeT::ncoeff_inv = 8;  // number of coefficients for inverse lookup
const float TypeT::mv_min = -5.603;
const float TypeT::mv_max = 20.872;

// coefficients for inverse lookup (given mV, find C)
const double TypeT::coeff_inv[8][2] = {
        {  0.0000000E+00,   0.000000E+00  },
        {  2.5949192E+01,   2.592800E+01  },
        { -2.1316967E-01,  -7.602961E-01  },
        {  7.9018692E-01,   4.637791E-02  },
        {  4.2527777E-01,  -2.165394E-03  },
        {  1.3304473E-01,   6.048144E-05  },
        {  2.0241446E-02,  -7.293422E-07  },
        {  1.2668171E-03,   0.000000E+00  }
};

// mV ranges for inverse lookup coefficients
const float TypeT::range_inv[2][2] = {
  { -5.603,          0.000   },
  {  0.000,         20.644   }
};

// coefficients for direct lookup (given C, find mV)
const double TypeT::coeff_dir[15][2] = {
  {0.000000000000E+00,   0.000000000000E+00},
  {0.387481063640E-01,   0.387481063640E-01},
  {0.441944343470E-04,   0.332922278800E-04},
  {0.118443231050E-06,   0.206182434040E-06},
  {0.200329735540E-07,  -0.218822568460E-08},
  {0.901380195590E-09,   0.109968809280E-10},
  {0.226511565930E-10,  -0.308157587720E-13},
  {0.360711542050E-12,   0.454791352900E-16},
  {0.384939398830E-14,  -0.275129016730E-19},
  {0.282135219250E-16,   0.0},
  {0.142515947790E-18,   0.0},
  {0.487686622860E-21,   0.0},
  {0.107955392700E-23,   0.0},
  {0.139450270620E-26,   0.0},
  {0.797951539270E-30,   0.0}

};

// ranges for direct lookup
const double TypeT::range_dir[2][2] = {
  { -270.000 ,  0.000 },
  {    0.000 ,400.00 }
};

const float TypeT::C_max = 400.0;
const float TypeT::C_min = -270.0;

// coefficients for exponential portion of direct lookup
const double TypeT::a[3] = {
   0.0, 0.0, 0.0
};

// -------------------------- constructor
TypeT::TypeT() {
  F_max = C_TO_F( C_max );
  F_min = C_TO_F( C_min );
}

// ------------------- given mv reading, returns absolute temp C
double TypeT::Temp_C( float mv ) {
  double x = 1.0;
  double sum = 0.0;
  int i,j,ind;
  if ( ! inrange_mV( mv ) ) return TC_RANGE_ERR;
  // first figure out which range of values
  for( j = 0; j < nranges_inv; j++ ) {
    if(mv >= range_inv[0][j] & mv <= range_inv[1][j])
      ind = j;
  };
//  Serial.println(ind);
  for( i = 0; i < ncoeff_inv; i++ ) {
    sum += x * coeff_inv[i][ind];
    x *= mv;
  }
  return sum;
}

// --------- given mv reading and ambient temp, returns compensated (true)
//           temperature at tip of sensor
double TypeT::Temp_C( float mv, float amb ) {
  float mv_amb;
  mv_amb = mV_C( amb );
  return Temp_C( mv + mv_amb );
};

// --------------------- returns compensated temperature in F units
double TypeT::Temp_F( float mv, float amb ) {
  return C_TO_F( Temp_C( mv, F_TO_C( amb ) ) );
};

// --------------------- returns absolute temperature in F units
double TypeT::Temp_F( float mv ) {
  float temp = Temp_C( mv );
  if( temp == TC_RANGE_ERR ) return TC_RANGE_ERR;
  return C_TO_F( temp );
}

// --------------------- checks to make sure mv signal in range
boolean TypeT::inrange_mV( float mv ) {
  return ( mv >= mv_min ) & ( mv <= mv_max );
};

// ---------------------- checks to make sure temperature in range
boolean TypeT::inrange_C( float ambC ) {
  return ( ambC >= C_min ) & ( ambC <= C_max );
};

// ----------------------- checks to make sure temperature in range
boolean TypeT::inrange_F( float ambF ) {
  return ( ambF >= F_min ) & ( ambF <= F_max );
};

// ---------------- returns mV corresponding to temp reading
//                  used for cold junction compensation
double TypeT::mV_C( float ambC ) {
  double sum = 0.0;
  double x = 1.0;
  float sum2 = 0.0;
  int i;
  if( !inrange_C( ambC ) ) return TC_RANGE_ERR;

  if( ambC >= range_dir[0][0] & ambC <= range_dir[1][0] ) {
    for( i = 0; i < 11; i++ ) {
      sum += x * coeff_dir[i][0];
      x *= ambC;
    }
  }
  else {
    for( i = 0; i < 10; i++ ) {
      sum += x * coeff_dir[i][1];
      x *= ambC;
    };
    sum2 = a[0] * exp( a[1] * ( ambC - a[2] ) * ( ambC - a[2] ) );
//    Serial.print( sum ); Serial.print(" , "); Serial.println( sum2 );
    sum += sum2;
  };
  return sum;
};

// -------------------- cold junction compensation in F units
double TypeT::mV_F( float ambF ) {
  if( inrange_F( ambF ) )
    return mV_C( F_TO_C( ambF ) );
  else
    return TC_RANGE_ERR;
};
