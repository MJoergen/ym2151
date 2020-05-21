# YM2151 : Step-by-step implementation
# Episode 4 : "Attenuator and accumulator"

Welcome to the fourth episode of "YM2151 : Step-by-step implementation", where
we add an attenuator and an accumulator.  The purpose of this episode is to
generate an accumulated waveform of all 32 sine wave generators together.

Let's dive right into it!

## Attenuator
The calc\_sine module will be augmented with handling variable attenuation.  So
a new 10-bit input signal atten\_i is added to the module. This value is
interpreted as an unsigned value between 0 and 16, with 4 integer bits and 6
fractional bits. The attenuation is added to the output of the logsin function
and before the exp function.

Since this addition may overflow (and because simple wrap-around won't work),
we need to introduce capping.  For readability I've introduced a new block
satured\_sum\_unsigned that takes two unsigned values as arguments and outputs
an unsigned value, but with clipping (saturation) in case of overflow.

## Accumulator
The job of the accumulator is to add the output of all the generated waveforms
into a single waveform. It is quite possible to overflow when adding the
outputs together, and therefore we again have to perform clipping. This will
introduce distortion, but is much better than just doing normal wrap-around.

So for readability I've introduced yet another block saturated\_sum\_signed that
works with signed values rather than unsigned values.

## Changes to ym2151.vhd
The top-level file now instantiates the accumulator module. Furthermore, the
attenuation is set to maximum for all slots except the first. We have to be
careful with keeping track of the current slot, so when instantiating the
accumulator, the slot number must be shifted according to the latency in the
calc\_sine module.

