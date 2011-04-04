aBourbon.pde
-------------

This program descends from Bill Welch's original a_logger file, but
has been modified to output the following information on the serial interface:

 ambient temperature
 channel 0 temperature
 channel 0 rate of rise
 channel 1 temperature
 channel 1 rate of rise
 0 (dummy value used as a placeholder)

This programs outputs a series of records on the serial port:

  timestamp, ambient, temp. channel 0, rise rate channel 0, temp. 1, rise 1, 0

This is the arduino half of the application, and can be used standalone when connected
to a 16 x 2 LCD.

The Processing half of the application, which is the PC software to plot
the realtime graphs, is pBourbon.pde

This version of aBourbon.pde also provides output intended for a 16 x 2 LCD display.
The LCD can optionally be connected using a 4-bit parallel interface (see code for
pinouts), or can be used with an I2C port expander.  Use the "I2C_LCD" define in the
code to select.

EEPROM support has been added to the 20100928 version.  Use the "EEPROM_BRBN" define
in the code to enable/disable this option.


Jim Gallt
9/28/2010
