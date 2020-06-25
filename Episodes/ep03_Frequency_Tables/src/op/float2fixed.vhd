-- Author:  Michael Jørgensen
-- License: Public domain; do with it what you like :-)
-- Project: YM2151 implementation
--
-- Description:
-- This converts a number in floating point format to fixed point format.
--
-- Latency is 1 clock cycle.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

entity float2fixed is
   port (
      clk_i      : in  std_logic;
      sign_i     : in  std_logic;
      exponent_i : in  std_logic_vector(3 downto 0);
      mantissa_i : in  std_logic_vector(10 downto 0);
      value_o    : out std_logic_vector(13 downto 0)
   );
end entity float2fixed;

architecture synthesis of float2fixed is

   signal mantissa_s  : std_logic_vector(12+15 downto 0) := (others => '0');
   signal magnitude_s : std_logic_vector(12 downto 0);
   signal value_r     : std_logic_vector(13 downto 0);

begin

   mantissa_s(12 downto 2) <= mantissa_i;

   magnitude_s <= mantissa_s(12+to_integer(exponent_i)
                         downto to_integer(exponent_i));

   p_value : process (clk_i)
   begin
      if rising_edge(clk_i) then
         if sign_i = '0' then
            value_r <= "0" & magnitude_s;
         else
            value_r <= ("1" & not magnitude_s) + 1;
         end if;
      end if;
   end process p_value;

   value_o <= value_r;

end architecture synthesis;

