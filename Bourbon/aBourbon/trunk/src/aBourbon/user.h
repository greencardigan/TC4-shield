// user.h
// This file contains user definable compiler directives

// *************************************************************************************
// NOTE TO USERS: the following parameters should be
// be reviewed to suit your preferences and hardware setup.  
// First, load and edit this sketch in the Arduino IDE.
// Next compile the sketch and upload it to the Arduino.

// ------------------ optionally, use I2C port expander for LCD interface
#define I2C_LCD // comment this line out to use the standard parallel LCD 4-bit interface
#define EEPROM_BRBN // comment this line out if no calibration information stored in 64K EEPROM

#define BAUD 57600  // serial baud rate
#define BT_FILTER 10 // filtering level (percent) for displayed BT
#define ET_FILTER 10 // filtering level (percent) for displayed ET

// use RISE_FILTER to adjust the sensitivity of the RoR calculation
// higher values will give a smoother RoR trace, but will also create more
// lag in the RoR value.  A good starting point is 70%, but for air poppers
// or other roasters where BT might be jumpy, then a higher value of RISE_FILTER
// will be needed.  Theoretical max. is 99%, but watch out for the lag when
// you get above 85%.
#define RISE_FILTER 85 // heavy filtering on non-displayed BT for RoR calculations

// default values for systems without calibration values stored in EEPROM
#define CAL_GAIN 1.00 // you may substitute a known gain adjustment from calibration
#define UV_OFFSET 0 // you may subsitute a known value for uV offset in ADC
#define AMB_OFFSET 0.0 // you may substitute a known value for amb temp offset (Celsius)

// ambient sensor should be stable, so quick variations are probably noise -- filter heavily
#define AMB_FILTER 70 // 70% filtering on ambient sensor readings

// *************************************************************************************

