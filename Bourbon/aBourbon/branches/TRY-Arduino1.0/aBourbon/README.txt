aBourbon.pde
-------------

This program descends from Bill Welch's original a_logger file, but
has been modified to output the following information on the serial interface:

 ambient temperature
 channel 0 temperature
 channel 0 rate of rise
 channel 1 temperature
 channel 1 rate of rise

This program outputs a series of records on the serial port:

  timestamp, ambient, temp. channel 0, rise rate channel 0, temp. 1, rise 1

This is the arduino half of the application, and can be used standalone when connected
to a 16 x 2 LCD.

The Processing half of the application, which is the PC software to plot
the realtime graphs, is pBourbon.pde

A standard parallel LCD may be used.  Or, the LCDapter board may be used.  If the
LCDapter board is used, then the four buttons on the LCDapter can be pushed with these
results:

Button 1 pressed:  "# STRT,xxx.x" string (without quotes) is written to serial
                   port, and LED 1 turns on and remains on (xxx.x = timestamp)

Button 2 pressed:  "# FC,xxx.x" string is written, and LED 2 turns on and remains on

Button 3 pressed:  "# SC,xxx.x" string is written, and LED 3 turns on and remains on

Button 4 pressed:  "# EJCT,xxx.x" string is written, and all LED's are turned off.

To implement these special features, the TC4 must be connected using a 4-wire
I2C interface to an LCDapter board.  Use the LCDAPTER define in user.h.

The 64K EEPROM on the TC4 is supported by aBourbon.  Use the "EEPROM_BRBN" define
in user.h to enable/disable this option.  Calibration information can optionally
be read from the EEPROM.

Either Fahrenheit or Celsius temperatures can be selected.  F is the default.  To
implement C, use the CELSIUS define in user.h.


Jim Gallt
4/5/2011


Version 2.20
------------
Modified so that a dummy value for "power" output is no longer printed after the
temperature data.

Jim Gallt
5/23/2011


Version 2.30
------------
Added stronger error checking for reading calibration data from EEPROM.  Added
support for type J and type T thermocouples.

Jim Gallt
9/3/2011

version 3.00
------------
Arduino 1.0 compatibility

Jim Gallt
1/26/2012




