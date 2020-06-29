-- Author:  Michael Jørgensen
-- License: Public domain; do with it what you like :-)
-- Project: YM2151 implementation
--
-- Description: This module calculates the phase increment,
-- based on the note being played.
--
-- Latency is 2 clock cycles.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

entity calc_freq is
   port (
      clk_i          : in  std_logic;
      key_code_i     : in  std_logic_vector(6 downto 0);
      key_fraction_i : in  std_logic_vector(5 downto 0);
      phase_inc_II_o : out std_logic_vector(19 downto 0)
   );
end entity calc_freq; 

architecture synthesis of calc_freq is

   -- Stage 0
   signal kf_s           : std_logic_vector(12 downto 0);
   signal octave_s       : std_logic_vector(2 downto 0);
   signal freq_addr_s    : std_logic_vector(9 downto 0);

   -- Stage 1
   signal octave_I_r     : std_logic_vector(2 downto 0);
   signal freq_data_I_s  : std_logic_vector(11 downto 0);
   signal freq_I_s       : std_logic_vector(21 downto 0);
   signal phase_inc_I_s  : std_logic_vector(19 downto 0);

   -- Stage 2
   signal phase_inc_II_r : std_logic_vector(19 downto 0);

begin

   -----------------------------------------------------------------------------
   -- Stage 0
   -----------------------------------------------------------------------------

   kf_s        <= key_code_i & key_fraction_i;
   octave_s    <= kf_s(12 downto 10);
   freq_addr_s <= kf_s(9 downto 0);


   -----------------------------------------------------------------------------
   -- Stage 1
   -----------------------------------------------------------------------------

   p_stage1 : process (clk_i)
   begin
      if rising_edge(clk_i) then
         octave_I_r <= octave_s;
      end if;
   end process p_stage1;

   i_rom_freq : entity work.rom_freq
      port map (
         clk_i  => clk_i,
         addr_i => freq_addr_s,
         data_o => freq_data_I_s
      ); -- i_rom_freq

   -- Shift frequency based on octave number
   p_freq : process (all)
   begin
      freq_I_s <= (others => '0');
      freq_I_s(11+to_integer(octave_I_r)
           downto to_integer(octave_I_r)) <= freq_data_I_s;
   end process p_freq;

   phase_inc_I_s <= freq_I_s(21 downto 2);


   -----------------------------------------------------------------------------
   -- Stage 2
   -----------------------------------------------------------------------------

   p_stage2 : process (clk_i)
   begin
      if rising_edge(clk_i) then
         phase_inc_II_r <= phase_inc_I_s;
      end if;
   end process p_stage2;

   phase_inc_II_o <= phase_inc_II_r;

end architecture synthesis;

