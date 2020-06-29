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
      dt1_i          : in  std_logic_vector(2 downto 0);
      dt2_i          : in  std_logic_vector(1 downto 0);
      mul_i          : in  std_logic_vector(3 downto 0);
      phase_inc_II_o : out std_logic_vector(19 downto 0)
   );
end entity calc_freq; 

architecture synthesis of calc_freq is

   -- Stage 0
   signal kf_s           : std_logic_vector(12 downto 0);
   signal kf_inc_s       : std_logic_vector(12 downto 0);
   signal kf_sum_s       : std_logic_vector(12 downto 0);
   signal octave_s       : std_logic_vector(2 downto 0);
   signal freq_addr_s    : std_logic_vector(9 downto 0);

   -- Stage 1
   signal octave_I_r     : std_logic_vector(2 downto 0);
   signal key_code_I_r   : std_logic_vector(6 downto 0);
   signal dt1_I_r        : std_logic_vector(2 downto 0);
   signal mul_I_r        : std_logic_vector(3 downto 0);
   signal freq_data_I_s  : std_logic_vector(11 downto 0);
   signal freq_I_s       : std_logic_vector(21 downto 0);
   signal delta_I_s      : std_logic_vector(19 downto 0);
   signal sum_I_s        : std_logic_vector(19 downto 0);
   signal phase_inc_I_s  : std_logic_vector(19 downto 0);

   -- Stage 2
   signal phase_inc_II_r : std_logic_vector(19 downto 0);

begin

   -----------------------------------------------------------------------------
   -- Stage 0
   -----------------------------------------------------------------------------

   kf_s        <= key_code_i & key_fraction_i;

   -- Handle DT2
   kf_inc_s    <= to_stdlogicvector(  0, 13) when dt2_i = "00" else
                  to_stdlogicvector(512, 13) when dt2_i = "01" else
                  to_stdlogicvector(628, 13) when dt2_i = "10" else
                  to_stdlogicvector(800, 13);
   kf_sum_s    <= kf_s + kf_inc_s;

   octave_s    <= kf_sum_s(12 downto 10);
   freq_addr_s <= kf_sum_s( 9 downto  0);


   -----------------------------------------------------------------------------
   -- Stage 1
   -----------------------------------------------------------------------------

   p_stage1 : process (clk_i)
   begin
      if rising_edge(clk_i) then
         octave_I_r   <= octave_s;
         key_code_I_r <= kf_sum_s(12 downto 6);
         dt1_I_r      <= dt1_i;
         mul_I_r      <= mul_i;
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

   i_dt1 : entity work.dt1
      port map (
         key_code_i => key_code_I_r,
         dt1_i      => dt1_I_r,
         delta_o    => delta_I_s
      ); -- i_dt1

   sum_I_s <= freq_I_s(21 downto 2) + delta_I_s;

   p_phase_inc : process (all)
      variable phase_inc_I_v : std_logic_vector(19 downto 0);
   begin
      if mul_I_r = 0 then
         phase_inc_I_s <= "0" & sum_I_s(19 downto 1);
      else
         phase_inc_I_v := (others => '0');
         if mul_I_r(0) = '1' then
            phase_inc_I_v := phase_inc_I_v + sum_I_s;
         end if;
         if mul_I_r(1) = '1' then
            phase_inc_I_v := phase_inc_I_v + (sum_I_s(18 downto 0) & "0");
         end if;
         if mul_I_r(2) = '1' then
            phase_inc_I_v := phase_inc_I_v + (sum_I_s(17 downto 0) & "00");
         end if;
         if mul_I_r(3) = '1' then
            phase_inc_I_v := phase_inc_I_v + (sum_I_s(16 downto 0) & "000");
         end if;
         phase_inc_I_s <= phase_inc_I_v;
      end if;
   end process p_phase_inc;


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

