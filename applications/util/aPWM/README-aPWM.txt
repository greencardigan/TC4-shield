aPWM.pde
---------

Demonstration sketch for using analog inputs ANLG1 and
ANLG2 to control pulse width modulation (PWM) outputs.

Output showing the current output levels
(0 to 100%) will be displayed on an I2C LCD, if connected
(e.g. LCDapter or similar).  In addition, the output
will be streamed over the Arduino's serial interface
at 57600 baud.

The power output is stepped in increments of 5% as the
potentiometer position is changed.

To use, connect 10K (or larger) potentiometers to ANLG1
and ANLG2 headers on the TC4.  The middle pin should be
the wipe.  Connect the pots so that the voltage between
pins 2 and 3 (o to 5V) increases with clockwise rotation
of the stems.

Do not short pin 1 with either pin 2 or pin 3.  You
may short pins 2 and 3 together to tie pin 2 to a
zero analog value if you are only using one ANLG input
port.

ANLG1 will control the output to OT1, which is normally
set up to be a 1Hz time base SSR drive for an electric
heater, etc.  The duty cycle will vary from 0% to 100%.

ANGL2 will control the output to IO3, which is a 490Hz
PWM output.  Anticipated use is to control a universal
DC motor (e.g. a fan).  

Do not use IO3 to try and directly power the motor/fan!  

Instead, connect IO3 to the inputs of
an optotransistor (2N36, for example), and use the
optotransistor to switch the base current to a Darlington 
transistor (TIP120, for example), to drive the motor/fan.

Jim Gallt
4/24/2011
 