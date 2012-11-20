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

// Version 1.10

#include "cmndreader.h"

// define command objects (all are derived from CmndBase)
readCmnd reader;
awriteCmnd awriter;
dwriteCmnd dwriter;
chanCmnd chan;
ot1Cmnd ot1;
ot2Cmnd ot2;
io3Cmnd io3;
unitsCmnd units;
rf2000Cmnd rf2000;
rc2000Cmnd rc2000;
pidCmnd pid;
resetCmnd reset;


// --------------------- dwriteCmnd
// constructor
dwriteCmnd::dwriteCmnd() :
  CmndBase( DIGITAL_WRITE_CMD ) {
}

// --------------------------- specify digital output to arbitrary pin
// WARNING - this action is not really error checked.
// DWRITE;ppp;ddd\n

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
        if( strcmp( pars->paramStr(2), "HIGH" ) == 0 ) {
          pinMode( pinID, OUTPUT );
          digitalWrite( pinID, HIGH );
          #ifdef ACKS_ON
          Serial.print("# Pin A");
          Serial.print( (int) dpin );
          Serial.println(" set to HIGH");
          #endif
         }
        else if( strcmp( pars->paramStr(2), "LOW" ) == 0 ) {
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
      else {
        // not analog pin, so assume digital
        if( pars->paramStr(1)[0] == 'D' )  // permit pin ID to be D01, D13, etc
          dpin = atoi( pars->paramStr(1) + 1 );
        else
          dpin = atoi( pars->paramStr(1) ); // or if no leading character, assume digital
        pinMode( dpin, OUTPUT );
        if( strcmp( pars->paramStr(2), "HIGH" ) == 0 ) {
          digitalWrite( dpin, HIGH );
          #ifdef ACKS_ON
          Serial.print("# Pin D");
          Serial.print( (int) dpin );
          Serial.println(" set to HIGH");
          #endif
         }
        else if( strcmp( pars->paramStr(2), "LOW" ) == 0 ) {
          digitalWrite( dpin, LOW );
          #ifdef ACKS_ON
          Serial.print("# Pin D");
          Serial.print( (int) dpin );
          Serial.println(" set to LOW");
          #endif
        }
      }
    }
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
// AWRITE;ppp;ddd\n

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
#ifdef PLOT_POWER
      actv[2] = 0;
      actv[3] = 0;
#endif
    }
    return true;
  }
  else {
    return false;
  }
}

// ----------------------------- ot1Cmnd
// constructor
ot1Cmnd::ot1Cmnd() :
  CmndBase( OT1_CMD ) {
}

// execute the OT1 command
// OT1;ddd\n

boolean ot1Cmnd::doCommand( CmndParser* pars ) {
  if( strcmp( keyword, pars->cmndName() ) == 0 ) {
    uint8_t len = strlen( pars->paramStr(1) );
    if( len > 0 ) {
      levelOT1 = atoi( pars->paramStr(1) );
//      ssr.Out( levelOT1, levelOT2 );
      output_level_icc( levelOT1 );  // integral cycle control and zero cross SSR on OT1
      #ifdef ACKS_ON
      Serial.print("# OT1 level set to "); Serial.println( levelOT1 );
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
ot2Cmnd::ot2Cmnd() :
  CmndBase( OT2_CMD ) {
}

// execute the OT2 command
// OT2;ddd\n

boolean ot2Cmnd::doCommand( CmndParser* pars ) {
  if( strcmp( keyword, pars->cmndName() ) == 0 ) {
    uint8_t len = strlen( pars->paramStr(1) );
    if( len > 0 ) {
      levelOT2 = atoi( pars->paramStr(1) );
//      ssr.Out( levelOT1, levelOT2 );
      output_level_pac( levelOT2 );
      #ifdef ACKS_ON
      Serial.print("# OT2 level set to "); Serial.println( levelOT2 );
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
io3Cmnd::io3Cmnd() :
  CmndBase( IO3_CMD ) {
}

// execute the IO3 command
// IO3;ddd\n

boolean io3Cmnd::doCommand( CmndParser* pars ) {
  if( strcmp( keyword, pars->cmndName() ) == 0 ) {
    uint8_t len = strlen( pars->paramStr(1) );
    int levelIO3;
    if( len > 0 ) {
      levelIO3 = atoi( pars->paramStr(1) );
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
// UNITS;F\n or UNITS;C\n

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

// ----------------------------- pidCmnd
// constructor
pidCmnd::pidCmnd() :
  CmndBase( PID_CMD ) {
}

// execute the PID command
// PID;ON\n ;OFF\n ;TIME\n ;Pddd\n ;T;ddd;ddd;ddd\n

boolean pidCmnd::doCommand( CmndParser* pars ) {
  if( strcmp( keyword, pars->cmndName() ) == 0 ) {
    if( strcmp( pars->paramStr(1), "ON" ) == 0 ) {
      #ifdef PID_CONTROL
        myPID.SetMode(1);
        #ifdef ACKS_ON
        Serial.println("# PID turned ON");
        #endif
      #endif
      return true;
    }
    else if( strcmp( pars->paramStr(1), "OFF" ) == 0 ) {
      #ifdef PID_CONTROL
        myPID.SetMode(0);
        #ifdef ACKS_ON
        Serial.println("# PID turned OFF");
        #endif
      #endif
      return true;
    }
    else if( strcmp( pars->paramStr(1), "TIME" ) == 0 ) {
      counter = 0;
      #ifdef ACKS_ON
      Serial.println("# PID time reset");
      #endif
      return true;
    }
    else if( pars->paramStr(1)[0] == 'P' ) {
      #ifdef PID_CONTROL
      profile_number = atoi( pars->paramStr(1) + 1 );
      setProfile();
      #ifdef ACKS_ON
      Serial.print("# Profile number ");
      Serial.print( profile_number );
      Serial.println(" selected");
      #endif
      #endif
      return true;
    }
    else if( strcmp( pars->paramStr(1), "T" ) == 0 ) {
      #ifdef PID_CONTROL
      double kp, ki, kd;
      kp = atof( pars->paramStr(2) );
      ki = atof( pars->paramStr(3) );
      kd = atof( pars->paramStr(4) );
      myPID.SetTunings( kp, ki, kd );
      #ifdef ACKS_ON
      Serial.print("# PID Tunings set.  "); Serial.print("Kp = "); Serial.print(kp); Serial.print(",  Ki = "); Serial.print(ki); Serial.print(",  Kd = "); Serial.println(kd);
      #endif
      #endif
      return true;
    }
  }
  else {
    return false;
  }
}

// ----------------------------- resetCmnd
// constructor
resetCmnd::resetCmnd() :
  CmndBase( RESET_CMD ) {
}

// execute the reset command
// RESET\n

boolean resetCmnd::doCommand( CmndParser* pars ) {
  if( strcmp( keyword, pars->cmndName() ) == 0 ) {
    pBourbon = true;
    counter = 0;
    Serial.println( "# Reset" ); // respond to pBourbon reset command
    return true;
  }
  else {
    return false;
  }
}
