// user.h
// This file contains user definable compiler directives

// *************************************************************************************
// NOTE TO USERS: the following parameters should be
// be reviewed to suit your preferences and hardware setup.  
// First, load and edit this sketch in the Arduino IDE.
// Next compile the sketch and upload it to the Arduino.

// ------------------ optionally, use I2C port expander for LCD interface
#define LCDAPTER // comment this line out to use the standard parallel LCD 4-bit interface
//#define CELSIUS // if defined, output is in Celsius units; otherwise Fahrenheit

#define BAUD 57600  // serial baud rate
//#define BAUD 115200
#define BT_FILTER 10 // filtering level (percent) for displayed BT
#define ET_FILTER 10 // filtering level (percent) for displayed ET

// use RISE_FILTER to adjust the sensitivity of the RoR calculation
// higher values will give a smoother RoR trace, but will also create more
// lag in the RoR value.  A good starting point is 80%, but for air poppers
// or other roasters where BT might be jumpy, then a higher value of RISE_FILTER
// will be needed.  Theoretical max. is 99%, but watch out for the lag when
// you get above 95%.
#define RISE_FILTER 85 // heavy filtering on non-displayed BT for RoR calculations
#define ROR_FILTER 80 // post-filtering on the computed RoR values for smooth display

// ambient sensor should be stable, so quick variations are probably noise -- filter heavily
#define AMB_FILTER 70 // 70% filtering on ambient sensor readings

// *************************************************************************************

