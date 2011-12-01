// user.h
// This file contains user definable compiler directives

#define MEMCHECK // flag to enable checking available RAM

// *************************************************************************************
// NOTE TO USERS: the following parameters should be
// be reviewed to suit your preferences and hardware setup.  
// First, load and edit this sketch in the Arduino IDE.
// Next compile the sketch and upload it to the Arduino.

// select one of the following thermocouple types
#define TC_TYPE typeK  // thermocouple type / library
//#define TC_TYPE typeJ
//#define TC_TYPE typeT

// ------ connect a potentiomenter to ANLG1 for manual heater control using Ot1
#define ANALOG_IN

// ------------------ optionally, use I2C port expander for LCD interface
#define LCDAPTER // comment this line out to use the standard parallel LCD 4-bit interface
#define CELSIUS // if defined, output is in Celsius units; otherwise Fahrenheit

#define BAUD 57600  // serial baud rate
#define BT_FILTER 0 // filtering level (percent) for displayed BT - default 10
#define ET_FILTER 0 // filtering level (percent) for displayed ET - default 10

// use RISE_FILTER to adjust the sensitivity of the RoR calculation
// higher values will give a smoother RoR trace, but will also create more
// lag in the RoR value.  A good starting point is 80%, but for air poppers
// or other roasters where BT might be jumpy, then a higher value of RISE_FILTER
// will be needed.  Theoretical max. is 99%, but watch out for the lag when
// you get above 95%.
#define RISE_FILTER 75 // heavy filtering on non-displayed BT for RoR calculations default 85
#define ROR_FILTER 70 // post-filtering for the computed RoR values - default 80

// default values for systems without calibration values stored in EEPROM
#define CAL_GAIN 1.00 // you may substitute a known gain adjustment from calibration
#define UV_OFFSET 0 // you may subsitute a known value for uV offset in ADC
#define AMB_OFFSET 0.0 // you may substitute a known value for amb temp offset (Celsius)

// ambient sensor should be stable, so quick variations are probably noise -- filter heavily
#define AMB_FILTER 5 // 70% filtering on ambient sensor readings - default 70

// *************************************************************************************

