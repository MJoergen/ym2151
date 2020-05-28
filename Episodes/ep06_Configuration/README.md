# YM2151 : Step-by-step implementation
# Episode 6 : "Configuration"

Welcome to the sixth episode of "YM2151 : Step-by-step implementation", where
we implement the configuration interface. The purpose is to allow an external
module to configure (in real time) the notes to be played. This will be the
first time we can actually play some music!

## Configurator
The changes are first and foremost in the configurator module, which is
basically rewritten from scratch.

The configuration state of the 32 slots are stored in the two arrays,
total\_level\_r and config\_r, which correspond to the register locations
0x60 - 0x7F and 0x20 - 0x3F, respectively.

One additional complexity is that the configuration interface to the YM2151 is
running at the fast clock, whereas the current slot configuration is running at
the slower (halved) clock. Therefore, the configurator module must have both
clocks in. Since the slow and fast clocks are synchronous to each other, and
are running at a sufficiently low speed, it is not necessary to make special
Clock Domain Crossing considerations.

With the above changes, the design now correctly reacts to register writes!
Mind you, only a few register addresses are currently supported, but that will
change as we add more features to the design.

## Testing in hardware
The above change was quite limited. But in order to test in hardware (and in
simulation), we now need to do a substantial amount of additional work. The
point being that the YM2151 now relies on receiving the configuration from an
external entity, rather than the specific tones being hardcoded in the design.

So the example design in the nexys4ddr directory will be expanded to include a
simple controller moduler, ctrl. The purpose of this module is to read
configuration information from a ROM and to generate the configuration signals
for the YM2151 module. The contents of the ROM are in turn derived from a text
file "music.txt".

## Format of the file "music.txt"
So this text file contains the register writes to the YM2151.  Each line
consists of a 2-byte hexadecimal number. The first byte denotes the register
address and the second byte the register value.  For instance, the line "2087"
means write the hexadecimal value 0x87 to the register at hexadecimal address
0x20.

The file music.txt used in this episode consists of a number of register
writes, many of which are not yet supported by the current design. However, on
the real YM2151 (or any emulator) these register writes are necessary in order
to get the YM2151 to produce a sound. For instance, some of these register
writes configure the envelope generator, a topic for a later episode.

With the current contents of the file music.txt the current design will produce
the same output as the real chip: Three musical notes, with the following
frequencies and volumes:
* A4 (with frequency 440 Hz) @ -12 dB.
* E5 (with frequency 659 Hz) @ -24 dB.
* C6 (with frequency 1047 Hz) @ -18 dB.

## The controller module "ctrl"
This module instantiates a 16-bit wide ROM and populates (at synthesis time)
the ROM with the contents from the text file music.txt. After reset, the
controller module reads the ROM and generates the corresponding register writes
to the YM2151 module.

There is a special case, when the register address is equal to zero (0x00).
The controller module will, rather than issuing a register write, instead wait
a number of clock cycles determined by the corresponding register value, in
units of approximately 2 ms. So the line 00FF will wait for the maximum amount
of time, which is approximately half a second.

Finally, the value 0000 will wait indefinetely, i.e. stops all further register
writes.

The controller module "ctrl" is instantiated in the top level file
nexys4ddr.vhd.

When running in hardware the design correctly generates the three notes above.
So now it is possible to use a text file to control the register writes to the
YM2151.

## Testing in simulation
In simulation I've decided to make use of the same text file and controller
module as in hardware. So in the testbench file ym2151\_tb.vhd I also
instantiate the same controller module "ctrl".

There is a further effect in simulation mode that when the value 0000 is
reached, it stops the simulation. So no longer do we have to hardcode a
specific timeout, the simulation stops automatically according to the text
file.

