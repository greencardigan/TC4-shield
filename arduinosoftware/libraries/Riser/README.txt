Riser library
-------------

Create a folder and put these files in C:/Program Files/arduino-0018/libraries/Riser
on your computer.

This library provides support for calculating the rate of rise of a stream of
temperature data.

It is based on an N-sample moving average of the temperature values.  The moving
average is numerically differentiated to give a value for rise per minute.

The number of samples, N, must be at least 2, and (currently) not more than 16.

See Riser.h for further info.

Jim Gallt
7/1/2010
