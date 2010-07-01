// Rate of rise calculation -- demo
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

// --------------------------------------- main

const float temps[36] = {
  199.2,
  194.1,
  188.1,
  181.9,
  177.3,
  173.0,
  169.4,
  165.9,
  163.2,
  160.8,
  158.9,
  157.2,
  155.8,
  154.9,
  154.3,
  153.9,
  154.0,
  154.1,
  154.4,
  155.1,
  155.3,
  156.3,
  157.1,
  157.8,
  158.5,
  159.5,
  160.8,
  162.0,
  163.4,
  164.2,
  165.5,
  166.8,
  168.7,
  169.5,
  170.9,
  172.9
};

const float times[36] = {
  0,
  3,
  6,
  9,
  12,
  15,
  18,
  21,
  24,
  27,
  30,
  33,
  36,
  39,
  42,
  45,
  48,
  51,
  54,
  57,
  60,
  63,
  66,
  69,
  72,
  75,
  78,
  81,
  84,
  87,
  90,
  93,
  96,
  99,
  102,
  105 
};

void setup() {
  Riser rise1( 10 );  // number of samples must be 2 to 16
  delay( 4000 );
  Serial.begin( 57600 );
  for( int j = 0; j < 36; j++ ) {
    Serial.print( times[j] );
    Serial.print( "," );
//    Serial.print( temps[j] ); Serial.print(",");
    Serial.println( rise1.CalcRate( times[j], temps[j] ));
  };
};

void loop() {
};



