// user.h

#ifndef _user_h_
#define _user_h_

// This file contains user definable compiler directives for aCatuaiQ

// NOTE TO USERS: the following parameters should be
// be reviewed to suit your preferences and hardware setup.  
// First, load and edit this sketch in the Arduino IDE.
// Next compile the sketch and upload it to the Arduino.

// select one of the following thermocouple types
#define TC_TYPE typeK  // thermocouple type / library
//#define TC_TYPE typeJ
//#define TC_TYPE typeT

// define this if you connect a potentiomenter to ANLG1 for manual heater, fan control
#define ANALOG_IN

// optionally, use I2C port expander for LCD interface
#define LCDAPTER // comment this line out to use the standard parallel LCD 4-bit interface
//#define CELSIUS // if defined, output is in Celsius units; otherwise Fahrenheit

#define BAUD 57600  // serial baud rate
#define BT_FILTER 10 // filtering level (percent) for displayed BT
#define ET_FILTER 10 // filtering level (percent) for displayed ET

// use RISE_FILTER to adjust the sensitivity of the RoR calculation
// higher values will give a smoother RoR trace, but will also create more
// lag in the RoR value.  A good starting point is 80%, but for air poppers
// or other roasters where BT might be jumpy, then a higher value of RISE_FILTER
// will be needed.  Theoretical max. is 99%, but watch out for the lag when
// you get above 95%.
#define RISE_FILTER 85 // heavy filtering on non-displayed BT for RoR calculations
#define ROR_FILTER 80 // post-filtering for the computed RoR values

// default values for systems without calibration values stored in EEPROM
#define CAL_GAIN 1.00 // you may substitute a known gain adjustment from calibration
#define UV_OFFSET 0 // you may subsitute a known value for uV offset in ADC
#define AMB_OFFSET 0.0 // you may substitute a known value for amb temp offset (Celsius)

// ambient sensor should be stable, so quick variations are probably noise -- filter heavily
#define AMB_FILTER 70 // 70% filtering on ambient sensor readings

// phase angle control and integral cycle control outputs
#define OT1 9 // OT1 is on pin D9
#define OT2 10 // OT2 is on pin D10
#define OT_PAC OT2 // phase angle control on OT2 (AC fan, usually)
#define OT_ICC OT1 // integral cycle control on OT1 (AC heater, usually)

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

#endif // _user_h_
