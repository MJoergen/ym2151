# YM2151 : Step-by-step implementation
# Episode 1 : "Hello World"

Welcome to this first episode of "YM2151 : Step-by-step implementation", where
we generate a simple sawtooth waveform.  The purpose of this episode is to set
up the necessary directory structure, simulation environment, and build scripts
to generate a working bitfile for the FPGA.

## Directory structure.
So this first checkin establishes the directory structure with the following
three sub directories:
* [src](src). This contains the actual implementation ready for synthesis.
* [sim](sim). This contains additional files used only during simulation, e.g.
  testbench files.
* [nexys4ddr](nexys4ddr). This contains a complete example design for the
  Nexys4DDR board.

In the following I'll provide some more specific notes to the files within
each directory.

## src
The src directory so far only contains the single file ym2151.vhd, which in
this first episode is very simple: It generates a single sawtooth waveform.

The YM2151 module expects a clock signal with a frequency of 3.579 MHz, and
generates as output a single 16-bit (mono) signal. This output is to be
interpreted as an unsigned fractional value between logical 0 and logical 1.
The output can be sampled at a rate of 3.579 MHz / 64 = 55.9 kHz.

The factor 64 in the above calculation is because the YM2151 internally
operates at half the frequency, i.e. at 3.579 MHz / 2 = 1.789 MHz (see note on
phi\_M in section 2.2.1 on page 24 in the
[doc](../../doc/yamaha_ym2151_synthesis.pdf)) and since there are 32 steps in
each sample (see figure 2.2 on page 16 in the
[doc](../../doc/yamaha_ym2151_synthesis.pdf)) that gives the factor 64.

The output can be fed directly into a Digital-to-Analog Converter or, as is
the case on the Nexys4DDR board, a Pulse Width Modulator.

In this first episode the design generates a sawtooth signal with a frequency
of approximately 437 Hz.

## sim
This directory is for simulating the design, and contains a testbench file and
a Makefile.

The testbench instantiates the YM2151 and connects the output to the module
wav2file, which samples the output at 55.9 kHz and writes to the file
music.wav.

### Testing the design in simulation
To run the simulation, just enter the directory sim and type "make". When the
simulation has completed, the waveform viewer will automatically be opened.
Optionally, the generated file music.wav can be viewed/analyzed using a program
like audacity.  Here the generated waveform can be verified to be a sawtooth
waveform at frequency 437 Hz. The length of the simulation is written in line
57 of ym2151\_tb.vhd.

During the development of this design we will frequently make use of audacity
to verify the correctness of the generated output.

## nexys4ddr
This directory contains a simple example design to run on the Nexys4DDR board.
The top level file nexys4ddr.vhd instantiates the YM2151 module and a PWM
(Pulse Width Modulation) module. The latter is required to interface to the
low-pass filter on the Nexys4DDR board.

The PWM module runs at a frequency of 229 MHz, which is exactly 64 times faster
than the YM2151, and therefore no special consideration is needed when passing
from the YM2151 clock domain to the PWM clock domain.

### Testing the design in hardware
To generate a bitfile and program the FPGA, just enter the directory nexys4ddr
and type "make". When the FPGA has been programmed, a sawtooth waveform is
generated on the audio port of the Nexys4DDR board.

Optionally, the audio can be connected to the microphone input of the host
machine and audacity can be used to analyze the sound generated in hardware.
