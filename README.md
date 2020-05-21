# YM2151 : Step-by-step implementation

Welcome to this step-by-step guide on how to implement the YM2151 on the
Nexys4DDR board.

## Episodes
* [Episode 1 - Hello World](Episodes/ep01_Hello_World). Here we set up the
  directory structure and get a bitfile that generates a simple sawtooth
  waveform.
* [Episode 2 - Sine Wave](Episodes/ep02_Sine_Wave). Here we look into how to
  generate a pure sine wave in the FPGA.
* [Episode 3 - Frequency Table](Episodes/ep03_Frequency_Tables). This episode
  adds the logic necessary to calculate the correct frequency from the key
  and fraction values.
* [Episode 4 - Attenuator Accumulator](Episodes/ep04_Attenuator_Accumulator).
  This episode accumulates the waveform of all 32 sine wave generators
  together.

## Links
The [doc](doc) directory contains the [original
documentation](doc/yamaha_ym2151_synthesis.pdf) of the YM2151 chip from Yamaha.
However, I've also made use of the following repositories here on GitHub:
* [mamedev/mame/](https://github.com/mamedev/mame/): Emulator in C++ of the
  [YM2151](https://github.com/mamedev/mame/blob/master/src/devices/sound/ym2151.cpp).
* [sauraen/YM2612](https://github.com/sauraen/YM2612): Partial implementation
  in VHDL.
* [jotego/jt51](https://github.com/jotego/jt51): Complete implementation in
  Verilog.

