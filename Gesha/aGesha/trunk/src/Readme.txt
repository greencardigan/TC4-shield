
This program is a fork of Jim Gallt's aBourbon.pde

Initially the main modification is the addition of a new field in the log --
a Variac reading. The reading is taken by one of the TC4's analog input pins.
A low-voltage, unregulated wall-wart or AC transformer is is full-wave
recified and divided down with a simple resistive divider.

In addition, the LCD display has a slightly different layout.

The readjuice() routine is closely tied to the circuit (see juice_monitor-1.jpg).
If you modify the circuit, you will almost certainly need to modify this routine.

The circuit uses a transformer with a 10:1 turns ratio, so, for example,  100 VAC 
on the variac equals 10 VAC on the transformer output.

The full-wave rectifier is heavily filtered, and so the output is roughly Vpeak,
minus the losses from the full-wave bridge -- diode voltage drop, etc.

In my system, the maximum variac output is 140 VAC, so the maximum transformer
output is 14 VAC, but note this is approximately 20 Vpeak.

The Arduino's ADC (analog input pin) is limited to 5 volts max -- we must be very
careful never to exceed this, especially at the maximum setting of the variac.

The multi-turn pot divides down the output to 1/4 of full-scale, to make sure the
ADC pin does not exceed 5 volts.

In the equation, we scale the 0-1023 reading to 0-5 volts. Then we multiply by 4
to compensate for the 1/4 setting of the trim pot.

JUICE_LOSS takes into account the losses in the full-wave bridge -- diode voltage
drop, etc.

The " * 10. " takes into account the turns ratio (FIXME: we should not hard-code this)

Finally the 1.414 converts from Vpeak to VAC (RMS)


