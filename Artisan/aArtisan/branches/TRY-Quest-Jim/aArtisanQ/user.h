// user.h
//---------
// This file contains user definable compiler directives for aArtisan

// *************************************************************************************
// NOTE TO USERS: the following parameters should be
// be reviewed to suit your preferences and hardware setup.  
// First, load and edit this sketch in the Arduino IDE.
// Next compile the sketch and upload it to the Arduino.

// Version 1.10

#ifndef USER_H
#define USER_H

#define TC_TYPE typeK  // use one of these 3 options; comment out the other 2
//#define TC_TYPE typeJ
//#define TC_TYPE typeT

#define LCD // if output on an LCD screen is desired
#define LCDAPTER // if the I2C LCDapter board is to be used
//#define CELSIUS // controls only the initial conditions

#define BAUD 19200  // serial baud rate
#define BT_FILTER 10 // filtering level (percent) for BT
#define ET_FILTER 10 // filtering level (percent) for ET
#define AMB_FILTER 70 // 70% filtering on ambient sensor readings

// default values for systems without calibration values stored in EEPROM
#define CAL_GAIN 1.00 // you may substitute a known gain adjustment from calibration
#define UV_OFFSET 0 // you may subsitute a known value for uV offset in ADC
#define AMB_OFFSET 0.0 // you may substitute a known value for amb temp offset (Celsius)

#define TIME_BASE pwmN1Hz // cycle time for PWM output to SSR's on OT1, OT2
#define NC 4 // maximum number of physical channels on the TC4

// Useful for debugging only -- leave inactive otherwise
//#define MEMORY_CHK

// This turns on the "# xxxxxxx\n" acknowledgements after commands
//#define ACKS_ON

// phase angle control and integral cycle control outputs
#define OT1 9 // OT1 is on pin D9
#define OT2 10 // OT2 is on pin D10
#define OT_PAC OT2 // phase angle control on OT2 (AC fan, usually)
#define OT_ICC OT1 // integral cycle control on OT1 (AC heater, usually)
#define LED_PIN 13

// use these if zero cross detector connected to I/O2
//#define EXT_INT 0 // interrupt 0
//#define INT_PIN 2 // pin 2

// use these for I/O3
#define EXT_INT 1 // interrupt 1
#define INT_PIN 3

#define FREQ60 // 60Hz
//#define FREQ50 // 50Hz
#define TRIAC_MOTOR // inductive loads need a longer pulse width to fire at 100%
//#define TRIAC_HEATER // enable this for resistive loads, like heaters

#endif
