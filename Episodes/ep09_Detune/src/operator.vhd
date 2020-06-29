-- Author:  Michael Jørgensen
-- License: Public domain; do with it what you like :-)
-- Project: YM2151 implementation
--
-- Description:
--
-- This module calculates:
-- sin_o = sin(phase_i) * 0.5^atten_i
--
-- The input phase_i is interpreted as an unsigned value in the interval 0 to
-- 2*pi with a resolution of 10 bits,
-- The output sin_o is interpreted as a signed value between -1 and 1 with a
-- resolution of 14 bits.
--
-- The input atten_i is interpreted as an unsigned value from 0 to 16 with 4
-- integer bits and 6 fractional bits.
--
-- Latency is 8 clock cycles.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

entity operator is
   port (
      clk_i           : in  std_logic;
      op_i            : in  std_logic_vector(1 downto 0); -- Current operator number
      con_i           : in  std_logic_vector(2 downto 0); -- Connection mode
      feedback_i      : in  std_logic_vector(2 downto 0); -- M1 feedback
      phase_VIII_i    : in  std_logic_vector(9 downto 0);
      atten_VIII_i    : in  std_logic_vector(9 downto 0);
      val_XVI_o       : out std_logic_vector(13 downto 0)
   );
end entity operator;

architecture synthesis of operator is

   constant C_OP_M1         : std_logic_vector(1 downto 0) := "00";
   constant C_OP_M2         : std_logic_vector(1 downto 0) := "01";
   constant C_OP_C1         : std_logic_vector(1 downto 0) := "10";
   constant C_OP_C2         : std_logic_vector(1 downto 0) := "11";

   signal phase_mod_VIII_s  : std_logic_vector(9 downto 0);
   signal phase_VIII_s      : std_logic_vector(9 downto 0);

   -- Stage 0
   signal sign_VIII_s       : std_logic;
   signal phase_quad_VIII_s : std_logic_vector(7 downto 0);

   -- Stage 1
   signal sign_IX_r         : std_logic;
   signal atten_IX_r        : std_logic_vector(11 downto 0);
   signal logsin_IX_s       : std_logic_vector(11 downto 0);
   signal logout_IX_s       : std_logic_vector(11 downto 0);

   -- Stage 2
   signal sign_X_r          : std_logic;
   signal exponent_X_r      : std_logic_vector(3 downto 0);
   signal mantissa_X_s      : std_logic_vector(10 downto 0);

   -- Stage 3
   signal sin_XI_s          : std_logic_vector(13 downto 0);

begin

   ----------------------------------------------------
   -- Calculate phase modification based on current operator.
   ----------------------------------------------------

   i_phase_mod : entity work.phase_mod
      port map (
         clk_i            => clk_i,
         val_XVI_i        => val_XVI_o,
         op_i             => op_i,
         con_i            => con_i,
         feedback_i       => feedback_i,
         phase_mod_VIII_o => phase_mod_VIII_s
      ); -- i_phase_mod

   phase_VIII_s <= phase_VIII_i + phase_mod_VIII_s;


   ----------------------------------------------------
   -- Stage 0
   ----------------------------------------------------

   -- This maps the phase into the first quadrant, together with a sign bit.
   p_phase_quad : process (all)
   begin
      sign_VIII_s <= phase_VIII_s(9);

      if phase_VIII_s(8) = '0' then
         phase_quad_VIII_s <= phase_VIII_s(7 downto 0);
      else
         phase_quad_VIII_s <= not phase_VIII_s(7 downto 0);
      end if;
   end process p_phase_quad;


   ----------------------------------------------------
   -- Stage 1
   ----------------------------------------------------

   p_stage1 : process (clk_i) begin
      if rising_edge(clk_i) then
         sign_IX_r  <= sign_VIII_s;
         atten_IX_r <= atten_VIII_i & "00"; -- Shift atten_i to 8 fractional bits.
      end if;
   end process p_stage1;

   i_rom_logsin : entity work.rom_logsin
      port map (
         clk_i  => clk_i,
         addr_i => phase_quad_VIII_s,
         data_o => logsin_IX_s
      ); -- i_rom_logsin

   -- Perform the attenuation
   i_satured_sum_unsigned : entity work.saturated_sum_unsigned
      generic map (
         G_WIDTH => 12
      )
      port map (
         arg1_i => logsin_IX_s,
         arg2_i => atten_IX_r,
         sum_o  => logout_IX_s
      ); -- i_satured_sum


   ----------------------------------------------------
   -- Stage 2
   ----------------------------------------------------

   p_stage2 : process (clk_i)
   begin
      if rising_edge(clk_i) then
         sign_X_r     <= sign_IX_r;
         exponent_X_r <= logout_IX_s(11 downto 8);
      end if;
   end process p_stage2;

   i_rom_exp : entity work.rom_exp
      port map (
         clk_i  => clk_i,
         addr_i => logout_IX_s(7 downto 0),
         data_o => mantissa_X_s
      ); -- i_rom_exp


   ----------------------------------------------------
   -- Stage 3
   ----------------------------------------------------

   i_float2fixed : entity work.float2fixed
      port map (
         clk_i      => clk_i,
         sign_i     => sign_X_r,
         exponent_i => exponent_X_r,
         mantissa_i => mantissa_X_s,
         value_o    => sin_XI_s
      );


   ----------------------------------------------------
   -- Stages 4-8
   ----------------------------------------------------

   i_ring_buffer_out : entity work.ring_buffer
      generic map (
         G_WIDTH  => 14,
         G_STAGES => 5
      )
      port map (
         clk_i  => clk_i,
         data_i => sin_XI_s,
         data_o => val_XVI_o 
      ); -- i_ring_buffer_out

end architecture synthesis;

