pBourbon.pde
-------------

This program descends from Bill Welch's original p_logger file, but
has been modified to plot traces of

 channel 0 temperature
 channel 0 rate of rise
 channel 1 temperature


The rate of rise values are exaggerated by 10X.  So a plotted value of 200
corresponds to a rise rate of 20.0 degrees F per minute.

This is the Processing half of the application that runs on the PC.

The arduino half of the application, which must be flashed to the arduino
board, is aBourbon.pde.

A mouseclick will capture a JPG version of the screen to a file.

All user-configurable items are contained in "pBourbon.cfg".  This file
must be present.

The program will also look for files with these names, and 
if found, open them:

"profile.csv":  A guide profile in default F units
"logfile.csv":  A saved log file in default F units

If the config file has put the program in C units, then it will
look for, and open if found, these files:

"profile_c.csv"
"logfile_c.csv"

The guide profile and saved log files are optional.


Jim Gallt
4/16/2011