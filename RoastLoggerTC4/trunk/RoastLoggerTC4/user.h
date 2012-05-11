// user.h
// This file contains user definable compiler directives

// *************************************************************************************
// NOTE TO USERS: the following parameters should be
// be reviewed to suit your preferences and hardware setup.  
// First, load and edit this sketch in the Arduino IDE.
// Next compile the sketch and upload it to the Arduino.

//RoastLogger default is Celsius - To output data in Fahrenheit use jumper on ANLG2 
//#define CELSIUS no longer used

// thermocouple type / library : choose one for each input (typeJ, typeK, or typeT)
#define TC_TYPE1 typeK  // input 1
#define TC_TYPE2 typeK  // input 2

#define BAUD 115200 //RoastLogger modified from original 57600  // serial baud rate
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

// *************************************************************************************//

// choose one of the following for the PWM time base for heater output
#define TIME_BASE pwmN4sec  // recommended for Hottop D which has mechanical relay
//#define TIME_BASE pwmN2sec
//#define TIME_BASE pwmN1Hz
//#define TIME_BASE pwmN2Hz
//#define TIME_BASE pwmN4Hz
//#define TIME_BASE pwmN8Hz 

#define PWM_MODE IO3_FASTPWM

// choose one of the following for the PWM time base for fan output
#define PWM_PRESCALE IO3_PRESCALE_1024 // 61 Hz (tested to work well on Hottop roasters)
//#define PWM_PRESCALE IO3_PRESCALE_256  // 244 Hz
//#define PWM_PRESCALE IO3_PRESCALE_128  // 488 Hz
//#define PWM_PRESCALE IO3_PRESCALE_64   // 977 Hz
//#define PWM_PRESCALE IO3_PRESCALE_32   // 1953 Hz

// mapping of logical channels to physical ADC channels -- choose one
#define LOGCHAN1 0 // LOGCHAN1 mapped to physical channel 0 on ADC (default)
//#define LOGCHAN1 1 // LOGCHAN1 mapped to physical channel 1 on ADC
//#define LOGCHAN1 2 // LOGCHAN1 mapped to physical channel 2 on ADC
//#define LOGCHAN1 3 // LOGCHAN1 mapped to physical channel 3 on ADC

// choose one different than above
//#define LOGCHAN2 0
#define LOGCHAN2 1  // default
//#define LOGCHAN2 2
//#define LOGCHAN2 3

