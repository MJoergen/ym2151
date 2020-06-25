-- Author:  Michael Jørgensen
-- License: Public domain; do with it what you like :-)
-- Project: YM2151 implementation
--
-- Description: This module contains the ROM with the phase increments
-- (frequency) of each note.
--
-- The input (10 bits) is concatenation of note (4 bits) and fraction (6 bits).
-- The output (12 bits) is the scaled frequency at the second octave.
-- The update frequency is 3579545/32/2 = 55930 Hz.
-- The output value is scaled by a factor 2^20.
--
-- Example:
-- The note A has the bit pattern 1010_000000.
-- At the second octave the note A2 has the frequency 110 Hz, and the scaled
-- output is 110/55930*2^20 = 2062.
-- So the input 0x280 gives the output 0x80E.
--
-- Latency is 1 clock cycle.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;
use ieee.math_real.all;

entity rom_freq is
   port (
      clk_i  : in  std_logic;
      addr_i : in  std_logic_vector(9 downto 0);
      data_o : out std_logic_vector(11 downto 0)
   );
end entity rom_freq;

architecture synthesis of rom_freq is

   -- This defines a type containing an array of bytes
   type mem_t is array (0 to 1023) of std_logic_vector(11 downto 0);

   -- This reads the ROM contents from a text file
   impure function InitRom return mem_t is
      -- This is the increase in frequency for each step.
      -- There are 64 fractions per semitone, and 12 semitone per octave.
      constant C_FACTOR       : real := 2.0 ** (1.0/768.0);

      -- Frequency in Hz of the A4 tone.
      constant C_FREQ_A4_HZ   : real := 440.0;

      -- Index 0 corresponds to C#2, which is 4 semitones above A4, but 3 octaves lower.
      constant C_FREQ_INDEX_0 : real := C_FREQ_A4_HZ * (C_FACTOR**(4.0*64.0)) / 8.0;

      -- Frequency of input clock.
      constant C_CLOCK_HZ     : integer := 3579545;

      -- This is how often the phase increment is applied.
      constant C_UPDATE_HZ    : integer := C_CLOCK_HZ / 32 / 2;

      -- Scaling factor of output value.
      constant C_SCALE        : real := 2.0**20.0;

      variable ROM_v          : mem_t := (others => (others => '0'));
      variable note_v         : integer;
      variable freq_v         : real;
      variable phaseinc_v     : integer;

   begin
      for i in 0 to 1023 loop
         note_v     := i - (i/64/4)*64;
         freq_v     := C_FREQ_INDEX_0 * (C_FACTOR ** real(note_v));
         phaseinc_v := integer(freq_v/real(C_UPDATE_HZ) * C_SCALE); -- Rounding is automatic.
         ROM_v(i)   := to_stdlogicvector(phaseinc_v, 12);
      end loop;
      return ROM_v;
   end function;

   -- Initialize memory contents
   signal mem_r : mem_t := InitRom;

begin

   p_read : process (clk_i)
   begin
      if rising_edge(clk_i) then
         data_o <= mem_r(to_integer(addr_i));
      end if;
   end process p_read;

end architecture synthesis;

