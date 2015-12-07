// Rate of rise calculation
// Version:  20100701

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

#include <Riser.h>


// ------------------------------------ class Riser methods

Riser::Riser( int nsamples ) {
  N = nsamples;
  n = 0;
  nm1 = N; nm1--;
};

// ------------------------------------ main method
float Riser::CalcRate( float tod, float temp ) {
  
  float rate;
  float avgtemp;
  float dt, newtime;
  
  if( n < nm1 ) {  // first, must fill the empty buffer
    samp[0][n] = tod;
    samp[1][n] = temp;
    n++;
    return 0.0;  // nothing to report yet
  };
  
  if( n == nm1 ) { // buffer full for first time so compute avg temp
    samp[0][n] = tod;
    samp[1][n] = temp;
    old_tod = 0.5 * ( samp[0][0] + tod ); // midpoint of N samples
    dt = tod - samp[0][0]; // period of N samples
    if( dt == 0.0 ) {  // fixme -- throw an exception if dt is zero
      old_avgtemp = 0.0;
      return 0.0;  // division by zero
    };
    old_avgtemp = integral() / dt;;
//    Serial.print( old_avgtemp ); Serial.print(",");
    n++;
    return 0.0;  // still nothing to report
  };
  
  // begin typical calculation
  // buffer is now full and first average has been computed
  for( int i = 0; i < nm1; i++ ) {  // move oldest value out
    samp[0][i] = samp[0][i+1];
    samp[1][i] = samp[1][i+1];
  }  // for
  samp[0][nm1] = tod;  // move newest value into buffer
  samp[1][nm1] = temp;
  
  // calculate new average temp and timestamp for midpoint of N samples
  dt = tod - samp[0][0];
  if( dt == 0.0 ) return 0.0; // fixme -- throw an exception if dt is zero
  else {
    avgtemp = integral() / dt;
//    Serial.print( avgtemp ); Serial.print(",");
    newtime = 0.5 * ( tod + samp[0][0] );
    dt = newtime - old_tod;
    if( dt == 0.0 ) return 0.0; // fixme -- throw an exception if dt is zero
    else {
      rate = (avgtemp - old_avgtemp ) / ( dt );
      old_avgtemp = avgtemp;
      old_tod = newtime;
      return rate * SEC_PER_MIN;  // success -- return the rate of rise
    };
  };
};

// ------------------------------------- integration by trapezoidal rule
float Riser::integral() {
  double sum = 0.0;  // summation
  for( int i = 1; i < N; i++ ) {
    sum+= ( samp[1][i] + samp[1][i-1] ) * ( samp[0][i] - samp[0][i-1] );
  };
//  Serial.print( 0.5 * sum ); Serial.print(",");
  return 0.5 * sum;
};
