aCatuai.pde
-----------

Version 1.00
------------

This program descends from Bill Welch's original a_logger file.

In addition to logging temperature information, aCatuai also allows manual control
of a roaster through dial potentiometers connected to ANLG1 and ANLG2 ports on the
TC4 shield.

The following information is output over the serial interface:

 ambient temperature
 channel 0 temperature
 channel 0 rate of rise
 channel 1 temperature
 channel 1 rate of rise
 output level 1 (power to heater, normally)
 output level 2 (power to fan, normally)

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

The 64K EEPROM on the TC4 is supported by aCatuai.  Use the "EEPROM_CAT" define
in user.h to enable/disable this option.  Calibration information can optionally
be read from the EEPROM.

Either Fahrenheit or Celsius temperatures can be selected.  F is the default.  To
implement C, use the CELSIUS define in user.h.


Jim Gallt
5/23/2011



Version 1.10
------------
More robust error checking when reading EEPROM calibration information.

Uses revised PWM16 library that supports selectable PWM frequency on IO3.  This
improves performance of DC fans.

Added support for type J and type T thermocouples.  Previous versions supported
only type K.

Redefined buttons for standalone mode.  Left button (STRT) now resets the timer.


Jim Gallt
3-Sept-2011



aCatuaiQ beta1
-----------------
Integral cycle control on OT1 for heater (typical zero cross SSR)
Phase angle control on OT2 for fan (random fire SSR)

Tested successfully on P1 motor.  Ready for beta release

Jim Gallt
22-Nov-2011


