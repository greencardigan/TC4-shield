This is release 2.10 of the Bourbon application.
------------------------------------------------

This application suite requires an Arduino board and
TC4 shield.  Most of the testing has been done on
the Arduino Duemilanove and Version 4.00 of the TC4.
But it should work on all versions of the TC4, and
most Arduino boards.

All files are copyrighted and released under the BSD 
open source license.  (See individual files).

This application suite was originally developed by Bill Welch.
It has been extensively modified by Jim Gallt, Brad Collins and
other contributors from Homeroasters.org.

To install on your machine:

1.  Unzip this file into a temporary directory, or
    download the source files from the project
    SVN repository.
2.  Copy the "aBourbon" folder into the Arduino
    sketchbook on your machine.
3.  Copy the "pBourbon" folder into the Processing
    sketchbook on your machine.  (You may also copy
    this folder to the Arduino sketchbook, and it
    will work fine from there, too).
4.  If you do not already have a "libraries" folder
    in your Arduino sketchbook, then copy the 
    "libraries" folder from this distribution into your
    sketchbook.  If you already have a "libraries"
    folder, then copy the individual library folders
    from this zip file into your sketchbook "libraries"
    folder.  (The libraries in this zip are Release 1.00).

To use:

1.  Connect a TC4/Arduino combination to your computer.
2.  In the Arduino IDE, open the aBourbon.pde sketch
3.  Upload the sketch to your TC4/Arduino.
4.  Edit the pBourbon.cfg file to fit your situation
    a. Enter the correct COM port for your TC4/Arduino
    b. Enter the baud rate.  This must agree with 
       aBourbon/user.h. The default is 57600
    c. Leave the sample size at 1 unless you know
       what you are doing ;-)
    d. Choose Celsius or Fahrenheit (default) units.
       This must also agree with aBourbon/user.h
5.  Launch the Processing IDE, and load/run pBourbon.pde
    from the Processing IDE.

To tweak:

1.  You can adjust the amount of filtering (smoothing) done
    on the raw samples in the aBourbon/user.h file.  More
    filtering gives smoother traces, but also adds some
    lag time.  You can also specify whether or not you
    wish for calibration information for your TC4 to be
    read from the TC4 EEPROM (default is "yes").
2.  In aBourbon/user.h, there are options for connecting an
    LCD panel.  You would need this for standalone operation
    of aBourbon.  It is optional when you are using pBourbon
    to log and plot your roast data.  aBourbon will support
    either the LCDapter board over I2C, or a standard 4-bit
    parallel LCD interface ala LiquidCrystal.
3.  In pBourbon.pde, there is a section of user configurable
    items.  There are options to plot a guide profile for BT
    or to plot a previously logged roast.
4.  There is also an option to use a dark grey background
    instead of pure black.


For more information, consult the TC4 project site:
http://code.google.com/p/tc4-shield/


Jim Gallt
4/15/2011


Version 2.10 Revisions
----------------------

Users of the Arduino Uno and PICAXE reported that the elapsed timer
counter was being reset inconsistently.  Code was added to fix this.

