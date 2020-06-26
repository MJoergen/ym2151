-- Author:  Michael Jørgensen
-- License: Public domain; do with it what you like :-)
-- Project: YM2151 implementation
--
-- Description: This module is the top level for the YM2151.
--
-- The input clock frequency should nominally be 3.579545 MHz.
-- The output is an unsigned value representing a fractional output between
-- logical 0 and logical 1.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

entity ym2151 is
   port (
      clk_i : in  std_logic;
      rst_i : in  std_logic;
      -- Waveform output
      wav_o : out std_logic_vector(15 downto 0)
   );
end entity ym2151;

architecture synthesis of ym2151 is

   -- This should give a frequency of 3579545*8/2^16 = 437 Hz.
   constant C_WAV_INC : integer := 8;

   signal phase_r : std_logic_vector(15 downto 0);

begin

   -----------------------------------------------------------------------------
   -- Generate a linearly increasing phase.
   -----------------------------------------------------------------------------

   p_phase : process (clk_i)
   begin
      if rising_edge(clk_i) then
         phase_r <= phase_r + C_WAV_INC;

         if rst_i = '1' then
            phase_r <= (others => '0');
         end if;
      end if;
   end process p_phase;

   -- For now just output the phase; this gives a sawtooth waveform.
   wav_o <= phase_r;

end architecture synthesis;

