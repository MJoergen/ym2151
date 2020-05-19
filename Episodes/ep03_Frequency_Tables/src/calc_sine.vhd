-- Author:  Michael Jørgensen
-- License: Public domain; do with it what you like :-)
-- Project: YM2151 implementation
--
-- Description:
--
-- This module calculates:
-- sin_o = sin(phase_i)
--
-- The input phase_i is interpreted as an unsigned value in the interval 0 to
-- 2*pi with a resolution of 10 bits,
-- The output sin_o is interpreted as a signed value between -1 and 1 with a
-- resolution of 14 bits.
--
-- Latency is 3 clock cycles.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

entity calc_sine is
   port (
      clk_i   : in  std_logic;
      phase_i : in  std_logic_vector(9 downto 0);
      sin_o   : out std_logic_vector(13 downto 0)
   );
end entity calc_sine;

architecture synthesis of calc_sine is

   -- Stage 0
   signal sign_s         : std_logic;
   signal phase_quad_s   : std_logic_vector(7 downto 0);

   -- Stage 1
   signal sign_I_r       : std_logic;
   signal logsin_I_s     : std_logic_vector(11 downto 0);

   -- Stage 2
   signal sign_II_r      : std_logic;
   signal exponent_II_r  : std_logic_vector(3 downto 0);
   signal mantissa_II_s  : std_logic_vector(10 downto 0);

   -- Stage 3
   signal sin_III_s      : std_logic_vector(13 downto 0);

begin

   ----------------------------------------------------
   -- Stage 0
   ----------------------------------------------------

   -- This maps the phase into the first quadrant, together with a sign bit.
   p_phase_quad : process (phase_i)
   begin
      sign_s <= phase_i(9);

      if phase_i(8) = '0' then
         phase_quad_s <= phase_i(7 downto 0);
      else
         phase_quad_s <= not phase_i(7 downto 0);
      end if;
   end process p_phase_quad;


   ----------------------------------------------------
   -- Stage 1
   ----------------------------------------------------

   p_stage1 : process (clk_i) begin
      if rising_edge(clk_i) then
         sign_I_r <= sign_s;
      end if;
   end process p_stage1;

   i_rom_logsin : entity work.rom_logsin
      port map (
         clk_i  => clk_i,
         addr_i => phase_quad_s,
         data_o => logsin_I_s
      ); -- i_rom_logsin


   ----------------------------------------------------
   -- Stage 2
   ----------------------------------------------------

   p_stage2 : process (clk_i)
   begin
      if rising_edge(clk_i) then
         sign_II_r     <= sign_I_r;
         exponent_II_r <= logsin_I_s(11 downto 8);
      end if;
   end process p_stage2;

   i_rom_exp : entity work.rom_exp
      port map (
         clk_i  => clk_i,
         addr_i => logsin_I_s(7 downto 0),
         data_o => mantissa_II_s
      ); -- i_rom_exp


   ----------------------------------------------------
   -- Stage 3
   ----------------------------------------------------

   i_float2fixed : entity work.float2fixed
      port map (
         clk_i      => clk_i,
         sign_i     => sign_II_r,
         exponent_i => exponent_II_r,
         mantissa_i => mantissa_II_s,
         value_o    => sin_III_s
      );

   sin_o <= sin_III_s;

end architecture synthesis;

