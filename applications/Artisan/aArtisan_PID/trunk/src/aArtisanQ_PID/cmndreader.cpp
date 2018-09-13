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
#if ( !defined( PHASE_ANGLE_CONTROL ) ) || ( INT_PIN != 3 )
io3Cmnd io3;
dcfanCmnd dcfan;
#endif
unitsCmnd units;
pidCmnd pid;
resetCmnd reset;
#ifdef ROASTLOGGER
loadCmnd load;
powerCmnd power;
fanCmnd fan;
#endif
filtCmnd filt;


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
          Serial.print(F("# Pin A"));
          Serial.print( (int) dpin );
          Serial.println(F(" set to HIGH"));
          #endif
         }
        else if( strcmp( pars->paramStr(2), "LOW" ) == 0 ) {
          pinMode( pinID, INPUT);
          digitalWrite( pinID, LOW ); // must turn off pull-up on A pins
          pinMode( pinID, OUTPUT );
          digitalWrite( dpin, LOW );
          #ifdef ACKS_ON
          Serial.print(F("# Pin A"));
          Serial.print( (int) dpin );
          Serial.println(F(" set to LOW"));
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
          Serial.println(F(" set to HIGH"));
          #endif
         }
        else if( strcmp( pars->paramStr(2), "LOW" ) == 0 ) {
          digitalWrite( dpin, LOW );
          #ifdef ACKS_ON
          Serial.print(F("# Pin D"));
          Serial.print( (int) dpin );
          Serial.println(F(" set to LOW"));
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
      Serial.print(F("# Analog (PWM) "));
      Serial.print( pars->paramStr(1) );
      Serial.print(F(" output level set to ")); Serial.println( level );
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
        if( n <= NC ) {
          actv[i] = n;
        } else {
          actv[i] = 0;
        }
      }
      // #ifdef ACKS_ON
      Serial.print(F("# Active channels set to "));
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
    if( strcmp( pars->paramStr(1), "UP" ) == 0 ) {
      levelOT1 = levelOT1 + DUTY_STEP;
      if( levelOT1 > MAX_OT1 ) levelOT1 = MAX_OT1; // don't allow OT1 to exceed maximum
      if( levelOT1 < MIN_OT1 ) levelOT1 = MIN_OT1; // don't allow OT1 to turn on less than minimum
        outOT1();
      #ifdef ACKS_ON
      Serial.print(F("# OT1 level set to ")); Serial.println( levelOT1 );
      #endif
      return true;
    }
    else if( strcmp( pars->paramStr(1), "DOWN" ) == 0 ) {
      levelOT1 = levelOT1 - DUTY_STEP;
      if( levelOT1 < MIN_OT1 & levelOT1 != 0 ) levelOT1 = 0; // turn ot1 off if trying to go below minimum. or use levelOT1 = MIN_HTR ?
        outOT1();
      #ifdef ACKS_ON
      Serial.print(F("# OT1 level set to ")); Serial.println( levelOT1 );
      #endif
      return true;
    }
    else {
      uint8_t len = strlen( pars->paramStr(1) );
      if( len > 0 ) {
        levelOT1 = atoi( pars->paramStr(1) );
        if( levelOT1 > MAX_OT1 ) levelOT1 = MAX_OT1;  // don't allow OT1 to exceed maximum
        if( levelOT1 < MIN_OT1 & levelOT1 != 0 ) levelOT1 = MIN_OT1;  // don't allow to set less than minimum unless setting to zero
          outOT1();
        #ifdef ACKS_ON
        Serial.print(F("# OT1 level set to ")); Serial.println( levelOT1 );
        #endif
      }
      return true;
    }
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
    if( strcmp( pars->paramStr(1), "UP" ) == 0 ) {
      levelOT2 = levelOT2 + DUTY_STEP;
      if( levelOT2 > MAX_OT2 ) levelOT2 = MAX_OT2; // don't allow OT2 to exceed maximum
      if( levelOT2 < MIN_OT2 ) levelOT2 = MIN_OT2; // don't allow OT2 to turn on less than minimum
        outOT2();
      #ifdef ACKS_ON
      Serial.print(F("# OT2 level set to ")); Serial.println( levelOT2 );
      #endif
      return true;
    }
    else if( strcmp( pars->paramStr(1), "DOWN" ) == 0 ) {
      levelOT2 = levelOT2 - DUTY_STEP;
      if( levelOT2 < MIN_OT2 & levelOT2 != 0 ) levelOT2 = 0;  // turn off if selecting less than minimum. or use levelOT2 = MIN_FAN ?
        outOT2();
      #ifdef ACKS_ON
      Serial.print(F("# OT2 level set to ")); Serial.println( levelOT2 );
      #endif
      return true;
    }
    else {
      uint8_t len = strlen( pars->paramStr(1) );
      if( len > 0 ) {
        levelOT2 = atoi( pars->paramStr(1) );
        if( levelOT2 > MAX_OT2 ) levelOT2 = levelOT2;  // don't allow OT2 to exceed maximum
        if( levelOT2 < MIN_OT2 & levelOT2 != 0 ) levelOT2 = MIN_OT2;  // don't allow to set less than minimum unless setting to zero
          outOT2();
        #ifdef ACKS_ON
        Serial.print(F("# OT2 level set to ")); Serial.println( levelOT2 );
        #endif
      }
      return true;
    }
  }
  else {
    return false;
  }
}

#if ( !defined( PHASE_ANGLE_CONTROL ) ) || ( INT_PIN != 3 ) // disable when PAC is active and 3 is the int pin

// ----------------------------- io3Cmnd
// constructor
io3Cmnd::io3Cmnd() :
  CmndBase( IO3_CMD ) {
}

// execute the IO3 command
// IO3;ddd\n

boolean io3Cmnd::doCommand( CmndParser* pars ) {
  
  if( strcmp( keyword, pars->cmndName() ) == 0 ) {
    if( strcmp( pars->paramStr(1), "UP" ) == 0 ) {
      levelIO3 = levelIO3 + DUTY_STEP;
      if( levelIO3 > MAX_IO3 ) levelIO3 = MAX_IO3; // don't allow IO3 to exceed maximum
      if( levelIO3 < MIN_IO3 ) levelIO3 = MIN_IO3; // don't allow IO3 to turn on less than minimum
        outIO3();
      #ifdef ACKS_ON
      Serial.print(F("# IO3 level set to ")); Serial.println( levelIO3 );
      #endif
      
      return true;
    }
    else if( strcmp( pars->paramStr(1), "DOWN" ) == 0 ) {
      levelIO3 = levelIO3 - DUTY_STEP;
      if( levelIO3 < MIN_IO3 & levelIO3 != 0 ) levelIO3 = 0; // turn IO3 off if trying to go below minimum.
        outIO3();
      #ifdef ACKS_ON
      Serial.print(F("# IO3 level set to ")); Serial.println( levelIO3 );
      #endif
      
      return true;
    }
    else {
      uint8_t len = strlen( pars->paramStr(1) );
      if( len > 0 ) {
        levelIO3 = atoi( pars->paramStr(1) );
          outIO3();
        #ifdef ACKS_ON
        Serial.print(F("# IO3 level set to ")); Serial.println( levelIO3 );
        #endif
      }
      return true;
    }
  }
  else {
    return false;
  }
}
#endif

#if ( !defined( PHASE_ANGLE_CONTROL ) ) || ( INT_PIN != 3 )

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
  if( target < current ) { // ramping down, so check rate
    uint8_t delta = current - target;
    if( delta > SLEW_STEP ) // limit the step size
      delta = SLEW_STEP;
    uint32_t delta_ms = millis() - last_fan_change; // how long since last step?
    if( delta_ms > SLEW_STEP_TIME ) { // do only if enough time has gone by
      set_fan( current - delta ); // decrease the output level
    }
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
    levelIO3 = duty;
    outIO3();
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
#endif

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
      Serial.println(F("# Changed units to F"));
      #endif
      return true;
    }
    else if( strcmp( pars->paramStr(1), "C" ) == 0 ) {
      Cscale = true;
      #ifdef ACKS_ON
      Serial.println(F("# Changed units to C"));
      #endif
      return true;
    }
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

// turn PID on, reset Output to avoid reset windup
void pidCmnd::pidON() {
     Output = 0; // turn PID output off, otherwise Iterm accumulates (this looks like a bug in Brett's code)
     myPID.SetMode( AUTOMATIC );
      #ifdef ACKS_ON
      Serial.println(F("# PID turned ON"));
      #endif
}

// turn PID off, reset the output levels (we don't care about bumpless)
void pidCmnd::pidOFF() {
      Output = 0; // to make sure Iterm is not accumulated
      myPID.SetMode( MANUAL );
      outOT1();
      #ifdef ACKS_ON
      Serial.println(F("# PID turned OFF"));
      #endif
}

// execute the PID command
// PID;ON\n ;OFF\n ;TIME\n ;Pddd\n ;T;ddd;ddd;ddd;mode\n

boolean pidCmnd::doCommand( CmndParser* pars ) {
  if( strcmp( keyword, pars->cmndName() ) == 0 ) {
    if( strcmp( pars->paramStr(1), "ON" ) == 0 ) {
      #ifdef PID_CONTROL
        pidON();
      #endif
      return true;
    }
    else if( strcmp( pars->paramStr(1), "OFF" ) == 0 ) {
      #ifdef PID_CONTROL
        pidOFF();
      #endif
      return true;
    }
    else if( strcmp( pars->paramStr(1), "TIME" ) == 0 ) {
      counter = 0; // reset TC4 timer
      #ifdef ACKS_ON
      Serial.println(F("# PID time reset"));
      #endif
      return true;
    }
    else if( strcmp( pars->paramStr(1), "GO" ) == 0 ) {
      #ifdef PID_CONTROL
        counter = 0; // reset TC4 timer
        myPID.SetMode(1); // turn PID on
        #ifdef ACKS_ON
        Serial.println(F("# PID Roast Start"));
        #endif
      #endif
      return true;
    }
    else if( strcmp( pars->paramStr(1), "STOP" ) == 0 ) {
      #ifdef PID_CONTROL
        myPID.SetMode(0); // turn PID off
        #ifdef PHASE_ANGLE_CONTROL
        #ifdef IO3_HTR_PAC
        levelIO3 = 0;
        outIO3(); // Turn heater off in IO3
        levelOT2 = FAN_AUTO_COOL;
        outOT2(); // Set fan to auto cool level on OT2
        #else
        levelOT1 = 0;
        outOT1(); // Turn heater off on OT1
        levelOT2 = FAN_AUTO_COOL;
        outOT2(); // Set fan to auto cool level on OT2
        #endif
        #else // PWM Mode
        levelOT1 = 0;
        outOT1(); // Turn heater off on OT1
        levelIO3 = FAN_AUTO_COOL;
        outIO3(); // Set fan to auto cool level on IO3
        #endif
        #ifdef ACKS_ON
        Serial.println(F("# PID Roast Stop"));
        #endif
      #endif
      return true;
    }
    else if( pars->paramStr(1)[0] == 'P' ) { // Select profile
      #ifdef PID_CONTROL
      profile_number = atoi( pars->paramStr(1) + 1 );
      setProfile();
      #ifdef ACKS_ON
      Serial.print(F("# Profile number "));
      Serial.print( profile_number );
      Serial.println(F(" selected"));
      #endif
      #endif
      return true;
    }
    else if( pars->paramStr(1)[0] == 'T' ) { // Tune PID
      #ifdef PID_CONTROL
      double kp, ki, kd;
      kp = atof( pars->paramStr(2) );
      ki = atof( pars->paramStr(3) );
      kd = atof( pars->paramStr(4) );
      if( strcmp( pars->paramStr(1), "T_POM" ) == 0 ) {
        myPID.SetTunings( kp, ki, kd, P_ON_M ); // Proportional on Measurement
      } else {
        myPID.SetTunings( kp, ki, kd, P_ON_E ); // Proportional on Error
     }
      #ifdef ACKS_ON
      Serial.print(F("# PID Tunings set.  ")); Serial.print(F("Kp = ")); Serial.print(kp); Serial.print(F(",  Ki = ")); Serial.print(ki); Serial.print(F(",  Kd = ")); Serial.println(kd);
      #endif
      #endif
      return true;
    }
    else if( strcmp( pars->paramStr(1), "SV" ) == 0 ) {
      SV = atof( pars->paramStr(2) );
      #ifdef ACKS_ON
      Serial.print(F("# PID setpoint = ")); Serial.println(Setpoint);
      #endif
      return true;
    }
    else if( strcmp( pars->paramStr(1), "CT" ) == 0 ) {
      uint16_t ct = atof( pars->paramStr(2) );
      myPID.SetSampleTime( ct );
      //looptime = ct;
      #ifdef ACKS_ON
      Serial.print(F("# PID cycle (ms) = ")); Serial.println(ct);
      #endif
      return true;
    }
    else if( strcmp( pars->paramStr(1), "CHAN" ) == 0 ) {
      pid_chan = atoi( pars->paramStr(2) );
      #ifdef ACKS_ON
      Serial.print(F("# PID channel = ")); Serial.println(pid_chan);
      #endif
      return true;
    }
    else if( strcmp( pars->paramStr(1), "LIMIT" ) == 0 ) {
      uint8_t lower_limit = atoi( pars->paramStr(2) );
      uint8_t upper_limit = atoi( pars->paramStr(3) );
      myPID.SetOutputLimits(lower_limit, upper_limit); // set output limits to user defined limits
      #ifdef ACKS_ON
      Serial.print(F("# PID Limits set. ")); Serial.print(lower_limit); Serial.print(F(" to ")); Serial.println(upper_limit);
      #endif
      return true;
    }
  }
  else {
    return false;
  }
}

// ----------------------------- filtCmnd
// constructor
filtCmnd::filtCmnd() :
  CmndBase( FILT_CMD ) {
}

// execute the FILT command
// FILT,ppp,ppp,ppp,ppp where ppp = percent filtering on logical channels 1 to 4
boolean filtCmnd::doCommand( CmndParser* pars ) {
  if( strcmp( keyword, pars->cmndName() ) == 0 ) { // has the FILT keyword been read?
    for( uint8_t jj = 0; jj < NC; ++jj ) { // read up to NC values following command keyword
      uint8_t len = strlen( pars->paramStr(jj+1) );
      if( len > 0 ) {  // is there a parameter?
        int filter = atoi( pars->paramStr(jj+1) );  // read filter value
        uint8_t k = actv[jj];  // convert from logical to physical channel
        if( k > 0 ) { // is the physical channel active?
          --k;
          fT[k].init( filter ); // reset the digital filtering level for physical channel k
          #ifdef ACKS_ON
          Serial.print(F("# Physical channel ")); Serial.print( k );
          Serial.print(F(" filter set to ")); Serial.println( filter );
          #endif
        } // end if k > 0
      } // end if len
    } // end for
    return true;
  } // end if FILT
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
    //pBourbon = true;
    counter = 0;
    Serial.println( F("# Reset" )); // respond to pBourbon reset command
    return true;
  }
  else {
    return false;
  }
}

#ifdef ROASTLOGGER
// ----------------------------- loadCmnd
// constructor
loadCmnd::loadCmnd() :
  CmndBase( LOAD_CMD ) {
}

// execute the LOAD command
// LOAD\n

boolean loadCmnd::doCommand( CmndParser* pars ) {

  if( strcmp( keyword, pars->cmndName() ) == 0 ) {
    //roastlogger = true;
    counter = 1;
    return true;
  }
  else {
    return false;
  }

}

// ----------------------------- powerCmnd
// constructor
powerCmnd::powerCmnd() :
  CmndBase( POWER_CMD ) {
}

// execute the OT1 command
// POWER=ddd\n

boolean powerCmnd::doCommand( CmndParser* pars ) {

  if( strcmp( keyword, pars->cmndName() ) == 0 ) {
    uint8_t len = strlen( pars->paramStr(1) );
    if( len > 0 ) {
#ifdef PHASE_ANGLE_CONTROL
#ifdef IO3_HTR_PAC
      levelIO3 = atoi( pars->paramStr(1) );
      if( levelIO3 > MAX_IO3 ) levelIO3 = MAX_IO3;  // don't allow OT1 to exceed maximum
      if( levelIO3 < MIN_IO3 & levelIO3 != 0 ) levelIO3 = MIN_IO3;  // don't allow to set less than minimum unless setting to zero
      outIO3();
      #ifdef ACKS_ON
      Serial.print(F("# IO3 level set to ")); Serial.println( levelIO3 );
      #endif
#else
      levelOT1 = atoi( pars->paramStr(1) );
      if( levelOT1 > MAX_OT1 ) levelOT1 = MAX_OT1;  // don't allow OT1 to exceed maximum
      if( levelOT1 < MIN_OT1 & levelOT1 != 0 ) levelOT1 = MIN_OT1;  // don't allow to set less than minimum unless setting to zero
      outOT1();
      #ifdef ACKS_ON
      Serial.print(F("# OT1 level set to ")); Serial.println( levelOT1 );
      #endif
#endif
#else // PWM Mode
      levelOT1 = atoi( pars->paramStr(1) );
      if( levelOT1 > MAX_OT1 ) levelOT1 = MAX_OT1;  // don't allow OT1 to exceed maximum
      if( levelOT1 < MIN_OT1 & levelOT1 != 0 ) levelOT1 = MIN_OT1;  // don't allow to set less than minimum unless setting to zero
      outOT1();
      #ifdef ACKS_ON
      Serial.print(F("# OT1 level set to ")); Serial.println( levelOT1 );
      #endif
#endif
    }
    return true;
  
  }
  else {
    return false;
  }

}

// ----------------------------- fanCmnd
// constructor
fanCmnd::fanCmnd() :
  CmndBase( FAN_CMD ) {
}


// execute the FAN command
// FAN=ddd\n

boolean fanCmnd::doCommand( CmndParser* pars ) {
  if( strcmp( keyword, pars->cmndName() ) == 0 ) {
    uint8_t len = strlen( pars->paramStr(1) );
    if( len > 0 ) {
#ifdef PHASE_ANGLE_CONTROL
      levelOT2 = atoi( pars->paramStr(1) );
      if( levelOT2 > MAX_OT2 ) levelOT2 = MAX_OT2;  // don't allow fan duty to exceed maximum
      if( levelOT2 < MIN_OT2 & levelOT2 != 0 ) levelOT2 = MIN_OT2;  // don't allow to set less than minimum unless setting to zero
      outOT2();
      #ifdef ACKS_ON
      Serial.print(F("# OT2 level set to ")); Serial.println( levelOT2 );
      #endif
#else
      levelIO3 = atoi( pars->paramStr(1) );
      if( levelIO3 > MAX_IO3 ) levelIO3 = MAX_IO3;  // don't allow fan duty to exceed maximum
      if( levelIO3 < MIN_IO3 & levelIO3 != 0 ) levelIO3 = MIN_IO3;  // don't allow to set less than minimum unless setting to zero
      outIO3();
      #ifdef ACKS_ON
      Serial.print(F("# IO3 level set to ")); Serial.println( levelIO3 );
      #endif
#endif
    }
    return true;
  
  }
  else {
    return false;
  }
}
#endif //ROASTLOGGER

