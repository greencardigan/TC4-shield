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

#include "TCbase.h"
#include "WProgram.h"


// -------------------------------------
const int typeK::nranges_inv = 3;  // number of mV ranges for inverse lookup
const int typeK::ncoeff_inv = 10;  // number of coefficients for inverse lookup
const float typeK::mv_min = -5.891;
const float typeK::mv_max = 54.886;

// coefficients for inverse lookup (given mV, find C)
const double typeK::coeff_inv[10][3] = {
         { 0.0000000E+00,  0.000000E+00, -1.318058E+02 },
         { 2.5173462E+01,  2.508355E+01,  4.830222E+01 }, 
         { -1.1662878E+00,  7.860106E-02, -1.646031E+00 },
         { -1.0833638E+00, -2.503131E-01,  5.464731E-02 },
         { -8.9773540E-01,  8.315270E-02, -9.650715E-04 },
         { -3.7342377E-01, -1.228034E-02,  8.802193E-06 },
         { -8.6632643E-02,  9.804036E-04, -3.110810E-08 },
         { -1.0450598E-02, -4.413030E-05,  0.000000E+00 },
         { -5.1920577E-04,  1.057734E-06,  0.000000E+00 },
         { 0.0000000E+00, -1.052755E-08,  0.000000E+00 }
};

// mV ranges for inverse lookup coefficients
const float typeK::range_inv[2][3] = {
  { -5.891,          0.000,         20.644  },
  {  0.000,         20.644,         54.886  }
};

// coefficients for direct lookup (given C, find mV)
const double typeK::coeff_dir[11][2] = {
         {  0.000000000000E+00, -0.176004136860E-01 },
         {  0.394501280250E-01,  0.389212049750E-01 },
         {  0.236223735980E-04,  0.185587700320E-04 },
         { -0.328589067840E-06, -0.994575928740E-07 },
         { -0.499048287770E-08,  0.318409457190E-09 },
         { -0.675090591730E-10, -0.560728448890E-12 },
         { -0.574103274280E-12,  0.560750590590E-15 },
         { -0.310888728940E-14, -0.320207200030E-18 },
         { -0.104516093650E-16,  0.971511471520E-22 },
         { -0.198892668780E-19, -0.121047212750E-25 },
         { -0.163226974860E-22,  0.0  }
};

// ranges for direct lookup
const double typeK::range_dir[2][2] = {
  { -270.000 ,  0.000 },
  {    0.000 ,1372.00 }
};

const float typeK::C_max = 1372.0;
const float typeK::C_min = -270.0;

// coefficients for exponential portion of direct lookup
const double typeK::a[3] = {
    0.118597600000E+00, -0.118343200000E-03, 0.126968600000E+03
};

// -------------------------- constructor
typeK::typeK() {
  F_max = C_TO_F( C_max );
  F_min = C_TO_F( C_min );
}

// ------------------- given mv reading, returns absolute temp C
double typeK::Temp_C( float mv ) {
  double x = 1.0;
  double sum = 0.0;
  int i,j,ind;
  ind = 0;
  if ( ! inrange_mV( mv ) ) return TC_RANGE_ERR;
  // first figure out which range of values
  for( j = 0; j < nranges_inv; j++ ) {
    if((mv >= range_inv[0][j]) && (mv <= range_inv[1][j]))
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
double typeK::Temp_C( float mv, float amb ) {
  float mv_amb;
  mv_amb = mV_C( amb );
  return Temp_C( mv + mv_amb );
};

// --------------------- returns compensated temperature in F units
double typeK::Temp_F( float mv, float amb ) {
  return C_TO_F( Temp_C( mv, F_TO_C( amb ) ) );
};

// --------------------- returns absolute temperature in F units
double typeK::Temp_F( float mv ) {
  float temp = Temp_C( mv );
  if( temp == TC_RANGE_ERR ) return TC_RANGE_ERR;
  return C_TO_F( temp );  
}

// --------------------- checks to make sure mv signal in range
boolean typeK::inrange_mV( float mv ) {
  return ( mv >= mv_min ) & ( mv <= mv_max );
};

// ---------------------- checks to make sure temperature in range
boolean typeK::inrange_C( float ambC ) {
  return ( ambC >= C_min ) & ( ambC <= C_max );
};

// ----------------------- checks to make sure temperature in range
boolean typeK::inrange_F( float ambF ) {
  return ( ambF >= F_min ) & ( ambF <= F_max );
};

// ---------------- returns mV corresponding to temp reading
//                  used for cold junction compensation
double typeK::mV_C( float ambC ) {
  double sum = 0.0;
  double x = 1.0;
  float sum2 = 0.0;
  int i;
  if( !inrange_C( ambC ) ) return TC_RANGE_ERR;

  if( (ambC >= range_dir[0][0]) && ( ambC <= range_dir[1][0] ) ) {
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
double typeK::mV_F( float ambF ) {
  if( inrange_F( ambF ) )
    return mV_C( F_TO_C( ambF ) );
  else
    return TC_RANGE_ERR;
};

