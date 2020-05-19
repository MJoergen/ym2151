# YM2151 : Step-by-step implementation
# Episode 3 : "Frequency Tables"

Welcome to the third episode of "YM2151 : Step-by-step implementation", where
we develop the block to generate the frequencies of the musical notes.

In the YM2151 a note consists of two parts:
* A key code, stored in 7 bits.
* A key fraction, stored in 6 bits.

These two numbers are fed into the calc\_freq module, which returns a 20-bit
number representing the frequency of this note.

## Changes to ym2151.vhd
The current phase is now increased to 20 bits for better precision. The upper
10 bits are fed to the sine table calculation. The phase is updated once every
32 internal clock cycles, so we introduce a global clock enable signal cen\_r
that toggles between 0 and 1, and we introduce a running index that increases
from 0 to 31.

Whenever the index wraps to 0, the phase is updated. This happens at a rate of
3.579 MHz / 2 / 32 = 55.9 kHz.  These changes are implemented in the process
p\_phase in ym2151.vhd.

## calc\_freq
Within the calc\_freq module. the key code is split into an octave number (3
bits) and a note number (4 bits).

The note number and key fraction together form a 10-bit number that is used as
address in the frequency ROM. The output is a 12-bit value representing the
frequency of the note corresponding to the octave value of 2.

For instance, the key A2 (with frequency 110 Hz) corresponds to index 0x280
(640) and has the value 0x80E (2062). This comes from the calculation
110/55930\*2^20 = 2062.

Finally, the frequency is shifted according to the actual chosen octave value.

## Verifying the design
Currently, the key code is hardwired to 0x4A, which corresponds to the note A4,
i.e.  440 Hz. When running in simulation or on hardware, the design should
generate a perfect sine wave with a frequency of exactly 440 Hz.

