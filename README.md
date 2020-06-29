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
* [Episode 5 - Phase and Envelope Generator](Episodes/ep05_Phase_Envelope_Generator).
  This episode allows the design to play 32 difference sine waves
  simultaneously.
* [Episode 6 - Configuration](Episodes/ep06_Configuration).
  This episode allows the design to replay register writes from a text file.
* [Episode 7 - Envelope Generator](Episodes/ep07_Envelope_Generator).
  This episode allows the design to play a complete tune!
* [Episode 8 - Operator](Episodes/ep08_Operator).
  This episode adds more complex waveforms.
* [Episode 9 - Detone](Episodes/ep09_Detune).
  This episode adds support for detune modes and phase multiplication.

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

## Utilization report

| Episode | LUT | Regs | Slice | Logic | Memory |  BRAM |
| ------- | --- | ---- | ----- | ----- | ------ | ----- |
|      1  |   1 |   13 |   10  |    1  |     0  |   0   |
|      2  |  52 |   33 |   25  |   52  |     0  |   1   |
|      3  |  76 |   76 |   34  |   76  |     0  |   1.5 |
|      4  | 119 |  111 |   48  |  119  |     0  |   1.5 |
|      5  | 156 |  121 |   59  |  136  |    20  |   1.5 |
|      6  | 188 |  141 |   79  |  144  |    44  |   1.5 |
|      7  | 351 |  211 |  130  |  266  |    85  |   1.5 |
|      8  | 529 |  279 |  173  |  390  |   139  |   1.5 |
|      9  | 655 |  291 |  209  |  504  |   151  |   1.5 |


### LUT usage
| Episode | Accumulator | Configurator | Envelope | Operator | Phase |
| ------- | ----------- | ------------ | -------- | -------- | ----- |
|      1  |     0       |       0      |     0    |      1   |    0  |
|      2  |     0       |       0      |     0    |     50   |    0  |
|      3  |     0       |       0      |     0    |     50   |    6  |
|      4  |    25       |       0      |     0    |     66   |    6  |
|      5  |    25       |       6      |     0    |     63   |   58  |
|      6  |    25       |      28      |     0    |     63   |   69  |
|      7  |    25       |      68      |   120    |     66   |   69  |
|      8  |    26       |      73      |   127    |    227   |   75  |
|      9  |    26       |      87      |   127    |    227   |  187  |

