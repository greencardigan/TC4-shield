// user.h
//---------
// This file contains user definable compiler directives for aArtisan

// *************************************************************************************
// NOTE TO USERS: the following parameters should be
// be reviewed to suit your preferences and hardware setup.  
// First, load and edit this sketch in the Arduino IDE.
// Next compile the sketch and upload it to the Arduino.

// --------------Version 3RC1 13-April-2014
//  changed serial baud rate to 115,200
// ------------------- 15-April-2014 Release version 3.0
// --------------17-April-2014
//          PID commands added, limited testing done.
// --------------19-April-2014
//          Added PID,CT command for adjustable sample time
// --------------22-October-2014
//          Added outputs for heater level, fan level, and SV
// -----28-October-2104
//          Add FILT command for runtime digital filtering levels
// ------01-July-2015 release version 3.10 (no changes)

#ifndef USER_H
#define USER_H

// beginning with version 2.1, TC type is selectable by input channel
// permissable options:  typeT, typeK, typeJ
#define TC_TYPE1 typeK  // thermocouple on TC1
#define TC_TYPE2 typeK  // thermocouple on TC2
#define TC_TYPE3 typeK  // thermocouple on TC3
#define TC_TYPE4 typeK  // thermocouple on TC4

#define LCD // if output on an LCD screen is desired
#define LCDAPTER // if the I2C LCDapter board is to be used
//#define CELSIUS // controls only the initial conditions (default is F)

#define PID_CHAN 1 // default logical channel for PID input, selectable by PID CHAN command
#define CT 1000 // cycle time for the PID, in ms
#define PRO 5.00 // initial proportional parameter (Pb = 100 / PRO)
#define INT 0.15 // initial integral parameter
#define DER 0.00 // initial derivative parameter
#define MIN_OT1 0 // Set OT1 output % for lower limit for OT1.  0% power will always be available
#define MAX_OT1 100 // Set OT1 output % for upper limit for OT1

// If needed adjust these to control what gets streamed back to Artisan when PID mode is active
// These have no effect on operation.  They only affect what gets displayed/logged by Artisan
#define HEATER_DUTY levelOT1 // by default, heater output is assumed levelOT1
#define FAN_DUTY levelIO3 // by default, fan output is assumed levelIO3
#define SV Setpoint

//#define MIN_OT2 10 // Set OT2 output % for lower limit for OT2.  0% power will always be available
//#define MAX_OT2 100 // Set OT2 output % for upper limit for OT2
//#define OT1_CUTOFF 10 // cut power to OT1 if OT2(%) is less than OT1_CUTOFF (to protect heater in air roaster). Set to 0 for no cutoff
//#define OT2_AUTO_COOL 15 // Set OT2 output % for auto cool when using PID;STOP command

#define BAUD 115200  // serial baud rate (version 3)
#define AMB_FILTER 70 // 70% filtering on ambient sensor readings

// initial values for BT and ET filtering (can be changed at runtime using FILT command)
#define BT_FILTER 10 // filtering level (percent) for BT
#define ET_FILTER 10 // filtering level (percent) for ET

// default values for systems without calibration values stored in EEPROM
#define CAL_GAIN 1.00 // you may substitute a known gain adjustment from calibration
#define UV_OFFSET 0 // you may subsitute a known value for uV offset in ADC
#define AMB_OFFSET 0.0 // you may substitute a known value for amb temp offset (Celsius)

// choose one of the following for the PWM time base for heater output on OT1 or OT2
//#define TIME_BASE pwmN4sec  // recommended for Hottop D which has mechanical relay
//#define TIME_BASE pwmN2sec
#define TIME_BASE pwmN1Hz  // recommended for most electric heaters controlled by standard SSR
//#define TIME_BASE pwmN2Hz
//#define TIME_BASE pwmN4Hz
//#define TIME_BASE pwmN8Hz 
//#define TIME_BASE 15 // should result in around 977 Hz (TODO these need testing)
//#define TIME_BASE 7 // approx. 1.95kHz
//#define TIME_BASE 6 // approx. 2.2kHz
//#define TIME_BASE 3 // approx. 3.9kHz

#define NC 4 // maximum number of physical channels on the TC4

// Useful for debugging only -- leave inactive otherwise
//#define MEMORY_CHK

// This turns on the "# xxxxxxx\n" acknowledgements after commands
//#define ACKS_ON

/* Correspondence between k values (gains) and Watlow conventional (needs verification testing)
-----------------------------------------------
kp = 100 / Pb (Pb is in degrees)
ki = 0.0167 * rE * kp (rE is resets per minute)
kd = 60 * rA * kp (rA is in minutes)
------------------------------------------------
Example:
Pb = 9F ---> kp = 11.1 percent per degree
rE = 0.60 --> ki = 0.111 percent per ( degree*second )
rA = 0.15 --> kd = 100 percent per ( degree per second )
*/


// *************************************************************************************

#endif
