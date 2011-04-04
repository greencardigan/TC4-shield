/*
 * MCPout.cpp
 *
 *  Created on: Oct 21, 2010
 */

// *** BSD License ***
// ------------------------------------------------------------------------------------------
// Written by Randy Tsuchiyama based on code by Jim Gallt
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

#include "MCPout.h"

// ----------------------------------------------------- MCP23017 port expander
void MCP_out::begin_A( uint8_t addr ) {

  // configure the port expander
  PEaddr = addr;
  Wire.beginTransmission( PEaddr );
  Wire.send( IOCONZ );  // valid command only if BANK = 0, which is true upon reset
  Wire.send( BANK ); // set BANK = 1 if it had been 0 (nothing happens if BANK = 1 already)
  Wire.endTransmission();

  // now, send our IO control byte with assurance BANK = 1
  Wire.beginTransmission( PEaddr );
  Wire.send( IOCON );
  Wire.send( BANK | SEQOP | DISSLW ); //  banked operation, non-sequential addressing
  Wire.endTransmission();

  // now, set up port A pins for output
  Wire.beginTransmission( PEaddr );
  Wire.send( IODIRA );
  Wire.send( 0 ); // 
  Wire.endTransmission();

}

void MCP_out::port_A_init_out( uint8_t addr ) {
// Set port A for all outputs
  PEaddr = addr;
  Wire.beginTransmission( PEaddr );
  Wire.send( IODIRA );
  Wire.send( 0 ); // configure port B pins:  outputs
  Wire.endTransmission();
}

void MCP_out::port_A_on( uint8_t addr ) {
// set all port A bits high
  PEaddr = addr;
  Wire.beginTransmission( PEaddr );
  Wire.send( GPIOA );
  Wire.send( 0xFF ); // 
  Wire.endTransmission();
}

void MCP_out::port_A_off( uint8_t addr ) {
// set all port A bits low
  PEaddr = addr;
  Wire.beginTransmission( PEaddr );
  Wire.send( GPIOA );
  Wire.send( 0 ); //
  Wire.endTransmission();
}

void MCP_out::port_A_out(uint8_t out, uint8_t addr ) {
// send out to port A
  PEaddr = addr;
  Wire.beginTransmission( PEaddr );
  Wire.send( GPIOA );
  Wire.send( out ); // 
  Wire.endTransmission();
}


