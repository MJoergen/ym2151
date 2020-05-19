# YM2151 : Step-by-step implementation
# Episode 2 : "Sine Wave"

Welcome to the second episode of "YM2151 : Step-by-step implementation", where
we generate a pure sine waveform.

## Overview
The heart of the waveform generator is being able to calculate the sine of an
angle. Rather than doing this in a single ROM lookup, the calculation is split
into two different ROMs:
* logsin, which calculates y=-log2(sin(x)).
* exp, which calculates z=0.5^y.
Composing these two functions gives indeed z=sin(x).

The reason for splitting the sine calculation in two like this, is to make the
envelope generation much easier, as this can now be achieved by a simple
addition of the logarithms.  This is the same scheme used in the real chip, and
described in [this
link](https://github.com/sauraen/YM2612/blob/master/Source/operator.vhd).
However, the current implementation should be considerably more readable.

## Binary representation
The devil is in the details, as the saying goes, and so it is here too. In
particular, the binary representation of the numbers adds considerable
complexity.

In the following I'm referring to the file
[calc\_sine.vhd](src/calc\_sine.vhd). The calculation is split into a number of
stages.

### Stage 0
The input phase\_i represents an angle between 0 to 2\*pi, and has a resolution
of 10 bits.

First some symmetries of the sine function is used to reduce the angle to the
first quadrant, i.e. between 0 to pi/2, with a resolution of 8 bits. The sign
of the result is stored separately.

### Stage 1
Here we use the first ROM, logsin, to calculate y=-log2(sin(x)). The input has
resolution of 8 bits, and the output has resolution of 12 bits.

The result is in units of 1/256'th powers of 0.5.

### Stage 2
The upper four bits of logsin are the exponent part (in base 2).  They indicate
how many bits to shift (between 0 and 15).  The lower eight bits of logsin are
fed to the second ROM, exp, to calculate z=0.5^y, which is the mantissa of the
final result.  The output of this ROM has resolution of 11 bits.

### Stage 3
This last stage instantiates the block float2fixed, which combines the sign,
the exponent, and the mantissa to generate the final output value.

The output is a 14-bit signed value between -1 and +1.

## Other changes
The Makefiles in sim/ and nexys4ddr/ have been updated with the new files.  In
the file ym2151.vhd the signal wav\_r has been renamed to phase\_r, and the
calc\_sine module has been instantiated. Only the upper 10 bits of phase\_r are
fed to this module, and the output (14 bits) is padded with two zero bits.

Finally, there is a conversion from signed to unsigned, i.e. an addition of 1.
This is achieved simply by negating the MSB.

