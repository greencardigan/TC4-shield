aBourbon.pde
-------------

This program descends from Bill Welch's original a_logger file, but
has been modified to output the following information on the serial interface:

 ambient temperature
 channel 0 temperature
 channel 0 rate of rise
 channel 1 temperature
 channel 1 rate of rise
 output power level (percent)

This programs outputs a series of records on the serial port:

  timestamp, ambient, temp. channel 0, rise rate channel 0, temp. 1, rise 1, power

This is the arduino half of the application, and can be used standalone when connected
to a 16 x 2 LCD.

The Processing half of the application, which is the PC software to plot
the realtime graphs, is pBourbon.pde

This version of aBourbon.pde also provides output intended for a 16 x 2 LCD display
as follows (LCD signal and corresponding Arduino pin):

#define RS 2 
#define ENABLE 4 
#define DB4 7 
#define DB5 8 
#define DB6 12 
#define DB7 13 

This version of aBourbon.pde also (optionally) will read an analog intput on pin AIN0.
There is a compile variable (ANALOG_IN) that controls whether or not this feature
is incorporated into the code loaded into the processor.

To use this feature, connect a 100K single turn potentiometer to +5V, GND, and AIN0 so
that the voltage varies between 0V and 5V on AIN0.  The software will scale this input
voltage and output a PWM signal with duty cycle between 0% and 100% on output 1.  This
can be used to drive an SSR to control the heater output on an electric roaster.

Jim Gallt
8/21/2010
