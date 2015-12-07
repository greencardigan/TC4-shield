March 7, 2011

Version 4.00 of the TC4 circuit boards are now available.  This
folder contains schematic, board layout, and photos of the V4.00
design.

Major changes since version 3.00:

1.)  Added a reset button (RST) to the shield.  Since the Arduino's reset
button becomes inaccessible when a shield is installed, this is nice
to have.

2.)  Corrected pin 4 of the JeePort header.  This pin now provides
3.3VDC, per current JeeLabs specifications.

3.)  Removed the jumpers (J10, J20, J30, J40) that were provided to
optionally ground the (-) side of the input signals.  These were taking up
a lot of room, and did not seem to be very useful.


Jim
