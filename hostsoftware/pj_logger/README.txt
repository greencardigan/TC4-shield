pj_logger.pde
-------------

Test program that logs 4-channels of type K thermocouple
input, and plots on screen.

This program is based on p_logger program by Bill Welch.  Modifications
have been made to
 - disable plotting of reference profile (myprofile.csv)
 - make compatible with Jim's COM ports
 - read and plot all 4 input channels as type K TC's

Results from initial testing of the TC-4, v1.05R shield are contained
in the testlog001 files.  Logged readings agreed with thermocouple calibrator
output throughout the range 32F to 450F during this test, with only a handful
of variations of 1F from the input value.


