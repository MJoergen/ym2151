# YM2151 : Step-by-step implementation
# Episode 8 : "Operator"

Welcome to the eighth episode of "YM2151 : Step-by-step implementation", where
we implement the different Operator modes.

Each of the eight channels consist of four operators, called M1, M2, C1, and
C2. They are evaluated in that order.

The four operators can be connected in the following eight variations:

0. C2(M2(C1(M1)))
1. C2(M2(C1+M1))
2. C2(M2(C1)+M1)
3. C2(M2+C1(M1))
4. C2(M2)+C1(M1)
5. C2(M1)+M2(M1)+C1(M1)
6. C2+M2+C1(M1)
7. C2+M2+C1+M1

On top of that, the M1 contains a feedback mechanism involving the delayed
value M1'.  All in all we can compile the following table that shows - for
each of the 8 connection modes - how an operator depends on up to two
previously evaluated operators.


| con |  0  |  1  |  2  |  3  |  4  |  5  |  6  |  7  |
|-----|-----|-----|-----|-----|-----|-----|-----|-----|
| M1  | M1' | M1' | M1' | M1' | M1' | M1' | M1' | M1' |
|     | M1  | M1  | M1  | M1  | M1  | M1  | M1  | M1  |
|     |     |     |     |     |     |     |     |     |
| M2  | C1  | C1  | C1  |  0  |  0  | M1' |  0  |  0  |
|     |  0  | M1  |  0  |  0  |  0  |  0  |  0  |  0  |
|     |     |     |     |     |     |     |     |     |
| C1  |  0  |  0  |  0  |  0  |  0  |  0  |  0  |  0  |
|     | M1  |  0  |  0  | M1  | M1  | M1  | M1  |  0  |
|     |     |     |     |     |     |     |     |     |
| C2  |  0  |  0  | M2  | C1  |  0  |  0  |  0  |  0  |
|     | M2  | M2  | M1  | M2  | M2  | M1  |  0  |  0  |
|     |     |     |     |     |     |     |     |     |
| OUT |  0  |  0  |  0  |  0  |  0  |  0  |  0  | M1  |
|     |  0  |  0  |  0  |  0  |  0  | M2  | M2  | M2  |
|     |  0  |  0  |  0  |  0  | C1  | C1  | C1  | C1  |
|     | C2  | C2  | C2  | C2  | C2  | C2  | C2  | C2  |


## Testing in simulation
In the simulation model in ym2151\_model\_pkg.vhd I've added the function
ym2151\_calcExpectedWaveform. It takes two arguments: The current configuration
and the current sample number. It then returns the expected output value of the
YM2151.

This function is very complex, because it has to take into consideration the
latency delays of the various pipelines as well as the non-exact sine function
calculation.

### Expected output

Sample\Mode |   0  |   1  |   2  |   3  |   4  |   5  |   6  |   7  |
------ | ---- | ---- | ---- | ---- | ---- | ---- | ---- | ---- |
   0   | 0012 | 0012 | 005e | 0012 | 002b | 006d | 0022 | 000c |
   1   | 024a | 032b | 03b2 | 0119 | 0221 | 0359 | 01d8 | 0060 |
   2   | 0083 | 07c9 | 07fa | 07e4 | 07cc | 0a0a | 0739 | 011b |
   3   | f9ea | 02c2 | 0400 | fad0 | 0d3d | 10ee | 0c6b | 01d7 |
   4   | 002b | ffaf | fdd9 | fea9 | 1255 | 175a | 1147 | 0293 |
   5   | 07cf | 020e | fa44 | 0599 | 16fa | 1d21 | 15b0 | 0350 |
   6   | f96f | 0760 | f94b | f920 | 1b16 | 221d | 1986 | 040a |
   7   | 07d4 | 04d9 | f9c4 | 05f5 | 1e7e | 2630 | 1cb3 | 04c6 |

