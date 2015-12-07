ADCdvlp.pde
-----------

Development code to test input to the TC4 shield.  Program
expects TypeK thermocouples on the 4 input terminals.  It will
run just fine if there is no sensor connected to some or all
of the terminals; it will report a value near ambient in this
case.

Conditional compilation #defines are used to control sample
rates, number of channels, decimal places in output, etc.  Refer
to the comments in the program for specifics.

This program will support the pj_logger.pde (on the host side).
Pre-load ADCdvlp.pde into your Arduino before running the pj_logger
program on your PC.

This program may be revised frequently, depending on what needs to
be tested at any given time.

For logging support, please consider using aj_logger.pde instead.
