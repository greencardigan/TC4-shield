aBourbon.pde
-------------

This program descends from Bill Welch's original a_logger file, but
has been modified to plot traces of

 channel 0 temperature
 channel 0 rate of rise
 channel 1 temperature
 channel 1 rate of rise

This programs outputs a series of records on the serial port:

  timestamp, temp. channel 1, rise rate channel 1, temp. 1, rise 1

This is the arduino half of the application.

The Processing half of the application, which is the PC software to plot
the graphs, is pBourbon.pde


Jim Gallt
7/3/2010
