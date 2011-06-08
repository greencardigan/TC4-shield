// cmndreader.cpp
//----------------

// code that defines specific commands for aArtisan

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
//   Neither the name of the copyright holder(s) nor the names of its contributors may be 
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

#include "cmndreader.h"

// define command objects (all are derived from CmndBase)
readCmnd reader;
awriteCmnd awriter;
dwriteCmnd dwriter;
chanCmnd chan;
portOT1Cmnd ot1;
portOT2Cmnd ot2;
portIO3Cmnd io3;
unitsCmnd units;
//rf2000Cmnd rf2000;
//rc2000Cmnd rc2000;

// ----------------------ArtisanInterp class
// constructor
ArtisanInterp::ArtisanInterp() :
  CmndInterp( DELIM ) {
  hashFlag = false;
}

// watch the serial port
const char* ArtisanInterp::checkSerial() {
  char c;
  while( Serial.available() > 0 ) {
    c = Serial.read();
    if( hashFlag ) { // if the hashflag is already set, then read the command
      // check for newline, buffer overflow
      uint8_t len = strlen( cmndstr );
      if( ( c == '\n' ) || ( len == MAX_CMND_LEN ) ) {
        // report input back to calling program
        strncpy( result, cmndstr, MAX_RESULT_LEN );
        result[MAX_RESULT_LEN] = '\0'; // for safety
        processCommand();
        cmndstr[0] = '\0'; // empty the buffer
        hashFlag = false;  // reset the flag
        return result;
      } // end if
      else { // append character
        cmndstr[len] = toupper(c);
        cmndstr[len+1] = '\0';
      } // end else
    }
    else {  // hashFlag not yet set, so see if this character sets it
      hashFlag = c == HASH;
    }  
  } // end while
  return NULL;
}

// --------------------- dwriteCmnd
// constructor
dwriteCmnd::dwriteCmnd() :
  CmndBase( DIGITAL_WRITE_CMD ) {
}

// --------------------------- specify digital output to arbitrary pin
// WARNING - this action is not really error checked.
// DWRT;ppp;ddd\n

boolean dwriteCmnd::doCommand( CmndParser* pars ) {
  if( strcmp( keyword, pars->cmndName() ) == 0 ) {
    uint8_t dpin;
    int pinID;
    uint8_t len1 = strlen( pars->paramStr(1) );
    uint8_t len2 = strlen( pars->paramStr(2) );
    if( len1 > 0 && len2 > 0 ) {
      // determine if pin ID is analog (A0, A1, etc)
      if( pars->paramStr(1)[0] == 'A' ) {
        dpin = atoi( pars->paramStr(1) + 1 ); // skip first character, convert remaining to integer
        switch (dpin) {
          case 0: pinID = A0; break;
          case 1: pinID = A1; break;
          case 2: pinID = A2; break;
          case 3: pinID = A3; break;
          case 4: pinID = A4; break;
          case 5: pinID = A5; break;
          default: return true;
        } // end switch
        if( strcmp( pars->paramStr(2), PIN_HIGH ) == 0 ) {
          pinMode( pinID, OUTPUT );
          digitalWrite( pinID, HIGH );
          #ifdef ACKS_ON
          Serial.print("# Pin A");
          Serial.print( (int) dpin );
          Serial.println(" set to HIGH");
          #endif
        }
        else if( strcmp( pars->paramStr(2), PIN_LOW ) == 0 ) {
          pinMode( pinID, INPUT);
          digitalWrite( pinID, LOW ); // must turn off pull-up on A pins
          pinMode( pinID, OUTPUT );
          digitalWrite( dpin, LOW );
          #ifdef ACKS_ON
          Serial.print("# Pin A");
          Serial.print( (int) dpin );
          Serial.println(" set to LOW");
          #endif
        }
        return true;
      } // end if analog
      else {  // not analog pin, so assume digital
        if( pars->paramStr(1)[0] == 'D' )  // permit pin ID to be D01, D13, etc
          dpin = atoi( pars->paramStr(1) + 1 );
        else
          dpin = atoi( pars->paramStr(1) ); // or if no leading character, assume digital
        if( dpin == 0 || dpin == 1 ) // don't mess with the RX, TX pins !!
          return true;
        pinMode( dpin, OUTPUT );
        if( strcmp( pars->paramStr(2), PIN_HIGH ) == 0 ) {
          digitalWrite( dpin, HIGH );
          #ifdef ACKS_ON
          Serial.print("# Pin D");
          Serial.print( (int) dpin );
          Serial.println(" set to HIGH");
          #endif
         }
        else if( strcmp( pars->paramStr(2), PIN_LOW ) == 0 ) {
          digitalWrite( dpin, LOW );
          #ifdef ACKS_ON
          Serial.print("# Pin D");
          Serial.print( (int) dpin );
          Serial.println(" set to LOW");
          #endif
        }
        /*
        else if( strcmp( pars->paramStr(2), PIN_TOGL ) == 0 ) {
          pinMode( dpin, INPUT );  // set up to read signal on pin
          if( digitalRead( dpin ) == HIGH ) {
            pinMode( dpin, OUTPUT );
            digitalWrite( dpin, LOW );
            #ifdef ACKS_ON
            Serial.print("# Pin D");
            Serial.print( (int) dpin );
            Serial.println(" set to LOW");
            #endif
          } // end if pin is HIGH
          else { // if pin is LOW
            pinMode( dpin, OUTPUT );
            digitalWrite( dpin, HIGH );
            #ifdef ACKS_ON
            Serial.print("# Pin D");
            Serial.print( (int) dpin );
            Serial.println(" set to HIGH");
            #endif
          } // end else if pin LOW
        } // end if action is TOGL
        */
      } // end if digital pin
    } // end if parameters are OK
    return true;
  }
  else {
    return false;
  }
}

// ----------------------------- awriteCmnd
// constructor
awriteCmnd::awriteCmnd() :
  CmndBase( ANALOG_WRITE_CMD ) {
}

// --------------------------- specify analog output to arbitrary pin
// WARNING - this action is not really error checked.
// AWRT;ppp;ddd\n

boolean awriteCmnd::doCommand( CmndParser* pars ) {
  if( strcmp( keyword, pars->cmndName() ) == 0 ) {
    uint8_t apin;
    int level;
    uint8_t len1 = strlen( pars->paramStr(1) );
    uint8_t len2 = strlen( pars->paramStr(2) );
    if( len1 > 0 && len2 > 0 ) {
      if( pars->paramStr(1)[0] == 'D' )  // permit pin ID to be D01, D13, etc
        apin = atoi( pars->paramStr(1) + 1 );
      else if( pars->paramStr(1)[0] == 'A' ) // invalid for the A pins
        return true;  // true because there was a command match
      else
        apin = atoi( pars->paramStr(1) ); // or if no leading character, assume digital
      level = atoi( pars->paramStr(2) );
      analogWrite( apin, level );
      #ifdef ACKS_ON
      Serial.print("# Analog (PWM) ");
      Serial.print( pars->paramStr(1) );
      Serial.print(" output level set to "); Serial.println( level );
      #endif
      }
    return true;
  }
  else {
    return false;
  }
}

// ----------------------------- readCmnd
// constructor
readCmnd::readCmnd() :
  CmndBase( READ_CMD ) {
}

// execute the READ command
// READ\n

boolean readCmnd::doCommand( CmndParser* pars ) {
  if( strcmp( keyword, pars->cmndName() ) == 0 ) {
    logger();
    return true;
  }
  else {
    return false;
  }
}

// ----------------------------- chanCmnd
// constructor
chanCmnd::chanCmnd() :
  CmndBase( CHAN_CMD ) {
}

// execute the CHAN command
// CHAN;ijkl\n

boolean chanCmnd::doCommand( CmndParser* pars ) {
  if( strcmp( keyword, pars->cmndName() ) == 0 ) {
    char str[2];
    uint8_t n;
    uint8_t len = strlen( pars->paramStr(1) );
    if( len == NC ) { // must match number of channels or take no action
      for( int i = 0; i < len; i++ ) {
        str[0] = pars->paramStr(1)[i]; // next character
        str[1] = '\0'; // force it to be char[2]
        n = atoi( str );
        if( n <= NC ) 
          actv[i] = n;
        else 
          actv[i] = 0;
      }
      // #ifdef ACKS_ON
      Serial.print("# Active channels set to ");
      Serial.println( pars->paramStr(1) );
      // #endif
    }
    return true;
  }
  else {
    return false;
  }
}

// ----------------------------- ot1Cmnd
// constructor
portOT1Cmnd::portOT1Cmnd() :
  CmndBase( PORT_CMD ) {
}

// execute the OT1 command
// PORT;OT1;ddd\n

boolean portOT1Cmnd::doCommand( CmndParser* pars ) {
  if( strcmp( keyword, pars->cmndName() ) == 0 && strcmp( OT1_CMD, pars->paramStr(1) ) == 0  ) {
    uint8_t len = strlen( pars->paramStr(2) );
    if( len > 0 ) {
      levelOT1 = atoi( pars->paramStr(2) );
      ssr.Out( levelOT1, levelOT2 );
      #ifdef ACKS_ON
      Serial.print("# Port OT1 level set to "); Serial.println( levelOT1 );
      #endif
    }
    return true;
  }
  else {
    return false;
  }
}

// ----------------------------- ot2Cmnd
// constructor
portOT2Cmnd::portOT2Cmnd() :
  CmndBase( PORT_CMD ) {
}

// execute the OT2 command
// PORT;OT2;ddd\n

boolean portOT2Cmnd::doCommand( CmndParser* pars ) {
  if( strcmp( keyword, pars->cmndName() ) == 0 && strcmp( OT2_CMD, pars->paramStr(1) ) == 0 ) {
    uint8_t len = strlen( pars->paramStr(2) );
    if( len > 0 ) {
      levelOT2 = atoi( pars->paramStr(2) );
      ssr.Out( levelOT1, levelOT2 );
      #ifdef ACKS_ON
      Serial.print("# Port OT2 level set to "); Serial.println( levelOT2 );
      #endif
    }
    return true;
  }
  else {
    return false;
  }
}

// ----------------------------- io3Cmnd
// constructor
portIO3Cmnd::portIO3Cmnd() :
  CmndBase( PORT_CMD ) {
}

// execute the IO3 command
// IO3;ddd\n

boolean portIO3Cmnd::doCommand( CmndParser* pars ) {
  if( strcmp( keyword, pars->cmndName() ) == 0 && strcmp( IO3_CMD, pars->paramStr(1) ) == 0 ) {
    uint8_t len = strlen( pars->paramStr(2) );
    int levelIO3;
    if( len > 0 ) {
      levelIO3 = atoi( pars->paramStr(2) );
      float pow = 2.55 * levelIO3;
      analogWrite( IO3, round( pow ) );
      #ifdef ACKS_ON
      Serial.print("# IO3 level set to "); Serial.println( levelIO3 );
      #endif
    }
    return true;
  }
  else {
    return false;
  }
}

// ----------------------------- unitsCmnd
// constructor
unitsCmnd::unitsCmnd() :
  CmndBase( UNITS_CMD ) {
}

// execute the UNITS command
// UNIT;F\n or UNITS;C\n

boolean unitsCmnd::doCommand( CmndParser* pars ) {
  if( strcmp( keyword, pars->cmndName() ) == 0 ) {
    if( strcmp( pars->paramStr(1), "F" ) == 0 ) {
      Cscale = false;
      #ifdef ACKS_ON
      Serial.println("# Changed units to F");
      #endif
      return true;
    }
    else if( strcmp( pars->paramStr(1), "C" ) == 0 ) {
      Cscale = true;
      #ifdef ACKS_ON
      Serial.println("# Changed units to C");
      #endif
      return true;
    }
  }
  else {
    return false;
  }
}

/*
// ----------------------------- rf2000Cmnd (legacy)
// constructor
rf2000Cmnd::rf2000Cmnd() :
  CmndBase( RF2000_CMD ) {
}

// execute the command
boolean rf2000Cmnd::doCommand( CmndParser* pars ) {
  if( strcmp( keyword, pars->cmndName() ) == 0 ) {
    Cscale = false;
    actv[0] = 1;
    actv[1] = 2;
    actv[2] = actv[3] = 0;
    logger();
    return true;
  }
  else {
    return false;
  }
}

// ----------------------------- rc2000Cmnd (legacy)
// constructor
rc2000Cmnd::rc2000Cmnd() :
  CmndBase( RC2000_CMD ) {
}

// execute the command
boolean rc2000Cmnd::doCommand( CmndParser* pars ) {
  if( strcmp( keyword, pars->cmndName() ) == 0 ) {
    Cscale = true;
    actv[0] = 1;
    actv[1] = 2;
    actv[2] = actv[3] = 0;
    logger();
    return true;
  }
  else {
    return false;
  }
}
*/
