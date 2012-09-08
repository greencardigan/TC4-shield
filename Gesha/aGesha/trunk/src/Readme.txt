
This program is a fork of Jim Gallt's aBourbon.pde

Initially the main modification is the addition of a new field in the log --
a Variac reading. The reading is taken by one of the TC4's analog input pins.
A low-voltage, unregulated wall-wart or AC transformer is is full-wave
recified and divided down with a simple resistive divider.

In addition, the LCD display has a slightly different layout.

----------------------

Hardware:

1. a simple transformer -- (for the USA: 120 VAC primary, 12 VAC secondary). Do
   not try to use a wall-wart or other 'regulated' supply.

2. the filter cap needs to be a large value, like 2200 uF shown on the schematic.
   Otherwise, the circuit will not develop the proper peak voltage (Vpeak).

3. A multi-turn pot would be handy but is not essential (see details below). Note
   that you can use a cheap plastic type multi-turn trim pot like those on
   printed circuit boards.

4. A full-wave bridge rectifier.

5. The circuit is only intended to operate near the top-end of the variac range.
   For the USA: perhaps 80 volts and higher.  Due to the diode-drops of the
   full-wave bridge, the readings will be incorrect once the transformer's
   secondary reaches a value below the minimum required by the full-wave bridge.

----------------------

Notes about the juice circuit and the readjuice() routine:

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

----------------------

some calibration tips if your circuit is somewhat different from mine:


1. you can unhook the Arduino if you like, all we need is your multi-meter for these tests. 

2. put your multi-meter on AC volts. Use it to measure the input side of the transformer -- 
   adjust variac for exactly 120 VAC

3. measure the output side of the transformer -- *before* the full-wave rectifier. measure 
   again with your meter set for AC

4. divide the input (120) by the output AC voltage -- that is your turns ratio (10 in my case). 
   I had 12 VAC output.

5. Just to simplify the next few steps, do this: If your turns ratio is something other than 10, 
   adjust your variac until the output of the transformer reads 12 VAC. Note: the input side of 
   the full-wave bridge. measuring AC voltage again.

6. Set your meter to DC volts, and measure the output of the full-wave rectifier. On the schematic 
   I called this Vunreg.

7. In theory, for an input of 12 VAC to the full-wave rectifier, and with a big capacitor (low ripple), 
   the DC voltage output should be 17 volts DC. But it will be less due to losses. Subtract your 
   actual reading from 17, and that is your JUICE_LOSS lumped constant.

8. Again, with meter on DC, measure your output from the divider -- the output of the multi-turn 
   pot in my case -- but a fixed resistor is fine. On the schematic, this point says "to TC4 ANLG0". 
   Be certain that this voltage is less than 5 volts DC when your variac is at its maximum setting.

8. Divide the two DC output voltages. In my case, I adjusted the pot until the answer was exactly 4. 
   But it is not critical, so long as you modify the formula accordingly -- change the " * 4 " to 
   whatever your ratio is.

9. that is it -- if you modify my '10' for turns ratio, and my '4' for 1/4 full scale, and adjust 
   your JUICE_LOSS, you should be good to go.

10. By the way, Don't try to use the power-supply circuit unless you are certain that you keep Vunreg 
    at least 12 volts or so, otherwise the 7808 regulator won't work properly. Better to just use a 
    separate supply for the Arduino.

11. Our multi-meters, when set to AC volts, measure 'VAC', also called 'RMS'. Our household voltage
    here is 120 VAC, or 120 RMS. But it is actually a sine wave, with a peak-to-peak voltage of
    2 * sqrt(2) * RMS, or 339 volts peak-to-peak, or 170 volts peak (Vpeak).

12. The output of the full-wave bridge, when filtered, is roughly equal to Vpeak, less some losses
    due to diode voltage drops inside the full-wave bridge itself.

References:

http://en.wikipedia.org/wiki/Transformer
http://en.wikipedia.org/wiki/Amplitude  

