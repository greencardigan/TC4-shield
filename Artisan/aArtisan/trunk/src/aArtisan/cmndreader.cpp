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

// ------------------ Version 3RC1 13-April-2014
//  added DCFAN command that limits fan slew rate
//  abandoned support for the legacy rf2000, rc2000 commands
// ------------------- 15-April-2014 Release version 3.0
// --------------17-April-2014
//          PID commands added, limited testing done.


#include "cmndreader.h"

// define command objects (all are derived from CmndBase)
readCmnd reader;
awriteCmnd awriter;
dwriteCmnd dwriter;
chanCmnd chan;
ot1Cmnd ot1;
ot2Cmnd ot2;
io3Cmnd io3;
dcfanCmnd dcfan;
unitsCmnd units;
pidCmnd pid;
/*
rf2000Cmnd rf2000;
rc2000Cmnd rc2000;
*/

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
      ssr.Out( levelOT1, levelOT2 );
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
      ssr.Out( levelOT1, levelOT2 );
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

// ----------------------------- dcfanCmnd
// constructor
dcfanCmnd::dcfanCmnd() :
  CmndBase( DCFAN_CMD ) {
}

void dcfanCmnd::init() {  // initialize fan to zero output
  target = 0;
  current = 0;
  last_fan_change = millis();
}

void dcfanCmnd::slew_fan() { // limit fan speed increases
  if( target < current ) { // no limit if slowing down
    set_fan( target );
  }
  else if( target > current ) {  // ramping up, so check rate
    uint8_t delta = target - current;
    if( delta > SLEW_STEP ) // limit the step size
      delta = SLEW_STEP;
    uint32_t delta_ms = millis() - last_fan_change; // how long since last step?
    if( delta_ms > SLEW_STEP_TIME ) { // do only if enough time has gone by
      set_fan( current + delta ); // increase the output level
    }  
  }
}

void dcfanCmnd::set_fan( uint8_t duty ) { // sets the fan speed
  if( duty >= 0 && duty < 101 ) { // screen out bogus values
    float pow = 2.55 * duty;
    analogWrite( FAN_PORT, round( pow ) );
    current = duty;
    last_fan_change = millis();
    #ifdef ACKS_ON
    Serial.print("# DCFAN level set to "); Serial.println( duty );
    #endif
  }
}

// execute the DCFAN command
// DCFAN;ddd\n

boolean dcfanCmnd::doCommand( CmndParser* pars ) {
  if( strcmp( keyword, pars->cmndName() ) == 0 ) {
    uint8_t len = strlen( pars->paramStr(1) );
    if( len > 0 ) {
      target = atoi( pars->paramStr(1) );
      //set_fan( target );
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
// else  
  return false; // revised 26-Jan-2012 to eliminate compiler warning
}

// ----------------------------- pidCmnd
// constructor
pidCmnd::pidCmnd() :
  CmndBase( PID_CMD ) {
}

// execute the PID command
// PID;ON\n ;OFF\n ;T;ddd;ddd;ddd\n ;SV;ddd\n ;CHAN;ddd\n

boolean pidCmnd::doCommand( CmndParser* pars ) {
  if( strcmp( keyword, pars->cmndName() ) == 0 ) {
    if( strcmp( pars->paramStr(1), "ON" ) == 0 ) {
     Output = 0; // turn PID output off, otherwise Iterm accumulates (this looks like a bug)
     myPID.SetMode(1);  // set to AUTO mode
      #ifdef ACKS_ON
      Serial.print("# PID turned ON");
      //Serial.print( "  Kp = ", myPID.GetKP() );
      //Serial.print( "  Ki = ", myPID.GetKI() );
      //Serial.print( "  Kd = ", myPID.GetKD() );
      //Serial.println();
      #endif
      return true;
    }
    else if( strcmp( pars->paramStr(1), "OFF" ) == 0 ) {
      myPID.SetMode(0);  // set to MANUAL mode
      levelOT1 = 0; // turn off output
      ssr.Out( levelOT1, levelOT2 );
      #ifdef ACKS_ON
      Serial.println("# PID turned OFF");
      #endif
      return true;
    }
/*    
    else if( strcmp( pars->paramStr(1), "TIME" ) == 0 ) {
      counter = 0; // reset TC4 timer
      #ifdef ACKS_ON
      Serial.println("# PID time reset");
      #endif
      return true;
    }
*/
/*
    else if( strcmp( pars->paramStr(1), "GO" ) == 0 ) {
      #ifdef PID_CONTROL
        counter = 0; // reset TC4 timer
        myPID.SetMode(1); // turn PID on
        #ifdef ACKS_ON
        Serial.println("# PID Roast Start");
        #endif
      #endif
      return true;
    }
*/
/*
    else if( strcmp( pars->paramStr(1), "STOP" ) == 0 ) {
      #ifdef PID_CONTROL
        myPID.SetMode(0); // turn PID off
        levelOT1 = 0;
        output_level_icc( levelOT1 );  // Turn OT1 (heater) off
        levelOT2 = OT2_AUTO_COOL;
        output_level_pac( levelOT2 ); // Set fan to auto cool level
        #ifdef ACKS_ON
        Serial.println("# PID Roast Stop");
        #endif
      #endif
      return true;
    }
*/
/*
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
*/
    else if( strcmp( pars->paramStr(1), "T" ) == 0 ) {
      double kp, ki, kd;
      kp = atof( pars->paramStr(2) );
      ki = atof( pars->paramStr(3) );
      kd = atof( pars->paramStr(4) );
      myPID.SetTunings( kp, ki, kd );
      #ifdef ACKS_ON
      Serial.print("# PID Tunings set.  "); 
      Serial.print("Kp = "); 
      Serial.print(myPID.GetKp()); 
      Serial.print(",  Ki = "); 
      Serial.print(myPID.GetKi()); 
      Serial.print(",  Kd = "); 
      Serial.println(myPID.GetKd());
      #endif
      return true;
    }
    else if( strcmp( pars->paramStr(1), "SV" ) == 0 ) {
      Setpoint = atof( pars->paramStr(2) );
      #ifdef ACKS_ON
      Serial.print("# PID Setpoint = "); Serial.println(Setpoint);
      #endif
      return true;
    }
    else if( strcmp( pars->paramStr(1), "CHAN" ) == 0 ) {
      pid_chan = atoi( pars->paramStr(2) );
      #ifdef ACKS_ON
      Serial.print("# PID channel = "); Serial.println(pid_chan);
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


