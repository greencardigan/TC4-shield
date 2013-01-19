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
#define LCD_4x20 // if using a 4x20 LCD instead of a 2x16

#define CELSIUS // controls only the initial conditions

#define ANALOGUE1 // if POT connected on ANLG1
#define ANALOGUE2 // if POT connected on ANLG2

#define ANALOGUE_STEP 2 // rounding for analogue input percentage. Use 1, 2, 4, 5, or 10.

#define ROR_CHAN 1 // physical input channel for RoR display on LCD

#define PID_CONTROL // if PID control is allowed to be activated
#define PID_CHAN 1 // physical channel for PID input
#define PRO 5.00 // initial proportional parameter
#define INT 0.20 // initial integral parameter
#define DER 0.00 // initial derivative parameter

#define MIN_OT1 0 // Set OT1 output % for lower limit of potentiometer range. Does not limit serial commands or PID
#define MAX_OT1 100 // Set OT1 output % for upper limit of potentiometer range. Does not limit serial commands or PID

#define MIN_OT2 20 // Set OT2 output % for lower limit of potentiometer range. Does not limit serial commands
#define MAX_OT2 100 // Set OT2 output % for upper limit of potentiometer range. Does not limit serial commands

#define OT1_CUTOFF 20 // cut power to OT1 if OT2(%) is less than OT1_CUTOFF (to protect heater in air roaster). Set to 0 for no cutoff

//#define COMMAND_ECHO // Echo all serial commands to LCD

#define BAUD 19200  // serial baud rate
#define BT_FILTER 10 // filtering level (percent) for BT
#define ET_FILTER 10 // filtering level (percent) for ET
#define AMB_FILTER 70 // 70% filtering on ambient sensor readings

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

#define TIME_BASE pwmN1Hz // cycle time for PWM output to SSR's on OT1, OT2
#define NC 4 // maximum number of physical channels on the TC4
#define PLOT_POWER // send heater and fan power levels to Artisan instead of 3rd and 4th channels

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

//#define FREQ60 // 60Hz
#define FREQ50 // 50Hz
#define TRIAC_MOTOR // inductive loads need a longer pulse width to fire at 100%
//#define TRIAC_HEATER // enable this for resistive loads, like heaters

#endif
