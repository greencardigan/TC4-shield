/*
 * MCPout.h
 *
 *  Created on: Oct 21, 2010
 */

// *** BSD License ***
// ------------------------------------------------------------------------------------------
// written by Randy Tsuchiyama based on code by  Jim Gallt
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


#ifndef MCPOUT_H_
#define MCPOUT_H_

#include <Wire.h>
#include <MCP23017.h>

#define MCP23_ADDR_01 (uint8_t)B0100101 // A2 = 1, A1 = 0 A0 = 1

class MCP_out {
public:
   void begin_A( uint8_t addr = MCP23_ADDR_01 );
   void port_A_init_out( uint8_t addr = MCP23_ADDR_01 );
   void port_A_on( uint8_t addr = MCP23_ADDR_01 );
   void port_A_off( uint8_t addr = MCP23_ADDR_01 );
   void port_A_out( uint8_t out, uint8_t addr = MCP23_ADDR_01 );

protected:
   uint8_t PEaddr;
//  virtual uint8_t rawRead(){ return 0; } // should be pure virtual
//  void debounce();
//  uint8_t n; // size of button array
//  uint8_t bits;
//  uint8_t mask;
//  uint32_t nextCheck;
//  uint8_t state[NCHECKS]; // circular buffer holding series of key states
//  uint8_t sidx; // index into the state buffer
//  uint8_t stable; // 1 bit per switch; bit = 1 if switch is stable
//  uint8_t changed; // 1 bit per switch; bit = 1 if switch changed
};

#endif
