PWM16 Library
-------------

Copyright (C) 2010 MLG Properties, LLC
Released under BSD license (see files).

Provides support for hardware-based pulse width modulation
on Arduino/ATMEGA328P.  This library offers higher resolution
and longer cycle periods than the standard Arduino pwm functions
that use 8-bit timer0.

This library uses 16-bit timer1.  When using this library,
both pins, DIO9 and DIO10 are dedicated for PWM use.

July 22, 2011
-------------
Added support for selection of PWM mode and frequency on
IO3.


See PWM16.h for details.
