aArtisan.ino
-------------

version 3.10 01-July-2015
-------------------------
- release version (no changes)

version 3PRC3 25-November-2014
-----------------------------
- added serial output for heater duty, fan duty, and SV when PID is ON
- added code to turn off LED on pin 13 (Uno R3 and compatible)
- streams heater level, fan level, and setpoint (SV) back to Artisan
- add FILT command for runtime selection of digital filtering

Version 3PRC2 19-April-2014
---------------------------
- added adjustable cycle time for PID

Version 3PRC1 17-April-2014
---------------------------
- added basic PID functionality
- testing needed

- Correspondence between k values and Watlow-style parameters  (needs verification testing)
   kp = 100 / Pb (Pb is in degrees)
   ki = 0.0167 * rE * kp (rE is resets per minute)
   kd = 60 * ra * kp (rA is in minutes)

   Example:
   Pb = 9F ---> kp = 11.1 percent per degree
   rE = 0.60 --> ki = 0.111 percent per ( degree*second )
   rA = 0.15 --> kd = 100 percent per ( degree per second )

   Note:  Watlow only applies rA when close to setpoint??


Release 3.00 15-April-2014
--------------------------------------
- tested and ready for release
- fixes intermittent Hottop controller resets due to fan current

Release 3RC1 for testing 13-April-2014
--------------------------------------
- changes baud rate to 115,200
- increases temperature output precision to 2 decimal places on serial port
- adds DCFAN command to address inrush current issues on some Hottop roasters

Jim Gallt
MLG Properties, LLC
