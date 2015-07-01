// Thermocouple library per ITS-90
// Version:  20110615

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

#include "thermocouple.h"
#include <math.h>

// ------------------------------------- tcBase class

tcBase::tcBase() {
//  mv_min = -6.00;
//  mv_max = 55.000;
//  C_max = 1500.0;
//  C_min = -300.0;
//  F_max = C_TO_F( C_max );
//  F_min = C_TO_F( C_min );
}

// --------- given mv reading and cold junction temp, returns
//           temperature at hot junction
FLOAT tcBase::Temp_C( FLOAT m, FLOAT coldC ) {
  FLOAT mv = m;
  if( coldC != 0.0 )
    mv += mV_C( coldC );
  if( inrange_mV( mv ) )
    return absTemp_C( mv );
  else
    return TC_RANGE_ERR;
};

// --------------------- returns compensated temperature in F units
FLOAT tcBase::Temp_F( FLOAT mv, FLOAT coldF ) {
  return C_TO_F( Temp_C( mv, F_TO_C( coldF ) ) );
};

// --------------------- checks to make sure mv signal in range
bool tcBase::inrange_mV( FLOAT mv ) {
  return ( mv >= mv_min() ) && ( mv <= mv_max() );
};

// ---------------------- checks to make sure temperature in range
bool tcBase::inrange_C( FLOAT tempC ) {
  return ( tempC >= C_min() ) && ( tempC <= C_max() );
};

// ----------------- use to calculate cold junction compensation in mV
FLOAT tcBase::mV_C( FLOAT tempC ) {
  if( inrange_C( tempC ) )
    return absMV_C( tempC );
  else
    return TC_RANGE_ERR;
};

// -------------------- cold junction compensation in F units
FLOAT tcBase::mV_F( FLOAT tempF ) {
  return C_TO_F( mV_C( F_TO_C( tempF ) ) );
};

// evaluate polynomial using Horner's rule
// coeff must point to top of selected column of coefficients in nrows x ncols array
FLOAT tcBase::_poly( FLOAT x, const FLOAT* coeff, uint8_t nrows, uint8_t ncols ) {
  uint8_t idx = ( nrows - 1 ) * ncols; // point to the bottom of the column
  FLOAT fx = 0.0; // initialize the summing variable
  for( ; ; ) { // iterate from bottom to top of column
    fx = fx * x + pgm_read_float_near( coeff + idx );
    if( idx == 0 )
      break;
    idx -= ncols; // move up to the next row in the same column
  }
  return fx;
}

// -------------------------------- class for simple linear approximation
tcLinear::tcLinear( FLOAT mVperC ){
  slope = mVperC;
}

FLOAT tcLinear::absTemp_C( FLOAT mV ) { return mV / slope; }
FLOAT tcLinear::absMV_C( FLOAT C ) { return C * slope; }


// ------------------------------------- Type K

// coefficients for inverse lookup (given mV, find C)
const PFLOAT typeK::coeff_inv[10][3] = {
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
const PFLOAT typeK::range_inv[2][3] = {
  { -5.891,          0.000,         20.644  },
  {  0.000,         20.644,         54.886  }
};

// coefficients for direct lookup (given C, find mV)
const PFLOAT typeK::coeff_dir[11][2] = {
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
const PFLOAT typeK::range_dir[2][2] = {
  { -270.000 ,  0.000 },
  {    0.000 ,1372.00 }
};

// coefficients for exponential portion of direct lookup
const PFLOAT typeK::a[3] = {
    0.118597600000E+00, -0.118343200000E-03, 0.126968600000E+03
};

// -------------------------- constructor
typeK::typeK() { }

// ------------------- given mv reading, returns absolute temp C
FLOAT typeK::absTemp_C( FLOAT mv ) {
  if ( ! inrange_mV( mv ) )
    return TC_RANGE_ERR;
  int j;
  int ind = 0;
  // first figure out which range of values
  for( j = 0; j < 3; j++ ) {
    if( ( mv >= pgm_read_float_near( &range_inv[0][j] ) ) &&
        ( mv <= pgm_read_float_near( &range_inv[1][j] ) ) )
      ind = j;
  };
  return _poly( mv, &(coeff_inv[0][ind]), 10, 3 );
}

// ---------------- returns mV corresponding to temp reading
//                  used for cold junction compensation
FLOAT typeK::absMV_C( FLOAT tempC ) {
  FLOAT sum;
  if( !inrange_C( tempC ) )
    return TC_RANGE_ERR;
  if( ( tempC >= pgm_read_float_near( &range_dir[0][0] ) ) &&
      ( tempC <= pgm_read_float_near( &range_dir[1][0] ) ) )
      return _poly( tempC, &(coeff_dir[0][0]), 11, 2 );
  else {
    sum = _poly( tempC, &(coeff_dir[0][1]), 11, 2 );
    return sum + pgm_read_float_near( &a[0] ) *
        exp( pgm_read_float_near( &a[1] ) *
        ( tempC - pgm_read_float_near( &a[2] ) ) *
        ( tempC - pgm_read_float_near( &a[2] ) ) );
  }
}

// ------------------------------------- Type T

const PFLOAT typeT::coeff_inv[8][2] = {
       {  0.0000000E+00,  0.000000E+00 },
       {  2.5949192E+01,  2.592800E+01 },
       { -2.1316967E-01, -7.602961E-01 },
       {  7.9018692E-01,  4.637791E-02 },
       {  4.2527777E-01, -2.165394E-03 },
       {  1.3304473E-01,  6.048144E-05 },
       {  2.0241446E-02, -7.293422E-07 },
       {  1.2668171E-03,  0.000000E+00 }
};

const PFLOAT typeT::range_inv[2][2] = {
   { -5.603,          0.000 },
   {  0.000,         20.872 }
};

const PFLOAT typeT::coeff_dir[15][2] = {
{ 0.000000000000E+00,  0.000000000000E+00 },
{ 0.387481063640E-01,  0.387481063640E-01 },
{ 0.441944343470E-04,  0.332922278800E-04 },
{ 0.118443231050E-06,  0.206182434040E-06 },
{ 0.200329735540E-07, -0.218822568460E-08 },
{ 0.901380195590E-09,  0.109968809280E-10 },
{ 0.226511565930E-10, -0.308157587720E-13 },
{ 0.360711542050E-12,  0.454791352900E-16 },
{ 0.384939398830E-14, -0.275129016730E-19 },
{ 0.282135219250E-16,  0.000000000000E+00 },
{ 0.142515947790E-18,  0.000000000000E+00 },
{ 0.487686622860E-21,  0.000000000000E+00 },
{ 0.107955392700E-23,  0.000000000000E+00 },
{ 0.139450270620E-26,  0.000000000000E+00 },
{ 0.797951539270E-30,  0.000000000000E+00 }
};

const PFLOAT typeT::range_dir[2][2] = {
  { -200.000 ,  0.000 },
  {    0.000 ,400.00 }
};

// ---------------------------------------------------
typeT::typeT() { }

// -------------------------------------
FLOAT typeT::absTemp_C( FLOAT mv ) {
  if ( ! inrange_mV( mv ) )
    return TC_RANGE_ERR;
  uint8_t j;
  uint8_t ind = 0;
  // first figure out which range of values
  for( j = 0; j < 2; j++ ) {
    if( ( mv >= pgm_read_float_near( &range_inv[0][j] ) ) &&
        ( mv <= pgm_read_float_near( &range_inv[1][j] ) ) )
      ind = j;
  };
  return _poly( mv, &(coeff_inv[0][ind]), 8, 2 );
}

// -------------------------------------
FLOAT typeT::absMV_C( FLOAT tempC ) {
  if( !inrange_C( tempC ) )
    return TC_RANGE_ERR;
  if( ( tempC >= pgm_read_float_near( &range_dir[0][0] ) ) &&
      ( tempC <= pgm_read_float_near( &range_dir[1][0] ) ) )
    return _poly( tempC, &(coeff_dir[0][0]), 15, 2 );
  else
    return _poly( tempC, &(coeff_dir[0][1]), 15, 2 );
};

// -------------------------------------

const PFLOAT typeJ::coeff_inv[9][3] = {
{  0.0000000E+00,  0.000000E+00, -3.11358187E+03 },
{  1.9528268E+01,  1.978425E+01,  3.00543684E+02 },
{ -1.2286185E+00, -2.001204E-01, -9.94773230E+00 },
{ -1.0752178E+00,  1.036969E-02,  1.70276630E-01 },
{ -5.9086933E-01, -2.549687E-04, -1.43033468E-03 },
{ -1.7256713E-01,  3.585153E-06,  4.73886084E-06 },
{ -2.8131513E-02, -5.344285E-08,  0.00000000E+00 },
{ -2.3963370E-03,  5.099890E-10,  0.00000000E+00 },
{ -8.3823321E-05,  0.000000E+00,  0.00000000E+00 }
};

const PFLOAT typeJ::range_inv[2][3] = {
    { -8.095,          0.000,         42.919 },
    {  0.000,         42.919,         69.553 }
};

const PFLOAT typeJ::coeff_dir[9][2] = {
    {   0.000000000000E+00,  0.296456256810E+03 },
    {   0.503811878150E-01, -0.149761277860E+01 },
    {   0.304758369300E-04,  0.317871039240E-02 },
    {  -0.856810657200E-07, -0.318476867010E-05 },
    {   0.132281952950E-09,  0.157208190040E-08 },
    {  -0.170529583370E-12, -0.306913690560E-12 },
    {   0.209480906970E-15,  0.000000000000E+00 },
    {  -0.125383953360E-18,  0.000000000000E+00 },
    {   0.156317256970E-22,  0.000000000000E+00 }
};

const PFLOAT typeJ::range_dir[2][2] = {
  { -210.000,  760.000 },
  {  760.000, 1200.000 }
};

// ---------------------------------------------------
typeJ::typeJ() { }

// -------------------------------------
FLOAT typeJ::absTemp_C( FLOAT mv ) {
  if ( ! inrange_mV( mv ) )
    return TC_RANGE_ERR;
  uint8_t j;
  uint8_t ind = 0;
  // first figure out which range of values
  for( j = 0; j < 3; j++ ) {
    if( ( mv >= pgm_read_float_near( &range_inv[0][j] ) ) &&
        ( mv <= pgm_read_float_near( &range_inv[1][j] ) ) )
      ind = j;
  }
  return _poly( mv, &(coeff_inv[0][ind]), 9, 3 );
}

// -------------------------------------
FLOAT typeJ::absMV_C( FLOAT tempC ) {
  if( !inrange_C( tempC ) )
    return TC_RANGE_ERR;
  if( ( tempC >= pgm_read_float_near( &range_dir[0][0] ) ) &&
      ( tempC <= pgm_read_float_near( &range_dir[1][0] ) ) )
    return _poly( tempC, &(coeff_dir[0][0]), 9, 2 );
  else
    return _poly( tempC, &(coeff_dir[0][1]), 9, 2 );
};

