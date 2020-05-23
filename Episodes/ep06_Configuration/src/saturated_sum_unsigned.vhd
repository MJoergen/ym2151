-- Author:  Michael Jørgensen
-- License: Public domain; do with it what you like :-)
-- Project: YM2151 implementation
--
-- Description: This module takes two unsigned values as arguments and outputs
-- an unsigned value, but with clipping (saturation) in case of overflow.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

entity saturated_sum_unsigned is
   generic (
      G_WIDTH : integer
   );
   port (
      arg1_i : in  std_logic_vector(G_WIDTH-1 downto 0);
      arg2_i : in  std_logic_vector(G_WIDTH-1 downto 0);
      sum_o  : out std_logic_vector(G_WIDTH-1 downto 0)
   );
end entity saturated_sum_unsigned;

architecture synthesis of saturated_sum_unsigned is

   signal sum_s : std_logic_vector(G_WIDTH downto 0);

begin

   sum_s <= ("0" & arg1_i) + ("0" & arg2_i);

   sum_o <= sum_s(G_WIDTH-1 downto 0) when sum_s(G_WIDTH) = '0' else
            (others => '1');

end architecture synthesis;

