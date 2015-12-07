README.txt for /svn/applications/Bourbon

The Bourbon application provides basic roast monitoring.  The application
is comprised of two parts:  aBourbon and pBourbon

The aBourbon application is an arduino sketch that can be compiled and
flashed to an arduino board using the arduino IDE.  To act as a
standalone application, aBourbon will communicate with an LCD panel
connected to the TC4 shield.

aBourbon, whether connected to an LCD or not, also sends a continuous
stream of data over the serial port of the arduino.

The pBourbon application is a processing language sketch that runs on a
host computer, e.g. a PC or MAC.  The pBourbon application reads the
stream of data coming from the arduino, and plots real-time graphs and creates detailed log files in CSV format.

The Bourbon application reads (by default) two type K thermocouple probes.
The first probe is generally used as a bean mass thermometer (BT).  
The second probe is generally used as a roast chamber environmental thermometer (ET).

The rate of rise (RoR) of the BT probe is computed and optionally
displayed on the LCD panel.  Digital filtering is performed by aBourbon
to provide smoothing of the data.

The output (whether on LCD or serial port) from aBourbon consists of a 
timestamp, ambient temperature (serial only), BT, BT-RoR, ET,
ET-RoR (serial only).


Jim Gallt
April 4, 2011

