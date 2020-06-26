-- Author:  Michael Jørgensen
-- License: Public domain; do with it what you like :-)
-- Project: YM2151 implementation
--
-- Description: This module takes two signed values as arguments and outputs a
-- signed value, but with clipping (saturation) in case of overflow.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

entity saturated_sum_signed is
   generic (
      G_WIDTH : integer
   );
   port (
      arg1_i : in  std_logic_vector(G_WIDTH-1 downto 0);
      arg2_i : in  std_logic_vector(G_WIDTH-1 downto 0);
      sum_o  : out std_logic_vector(G_WIDTH-1 downto 0)
   );
end entity saturated_sum_signed;

architecture synthesis of saturated_sum_signed is

   signal sum_s       : std_logic_vector(G_WIDTH downto 0);
   signal saturated_s : std_logic_vector(G_WIDTH-1 downto 0);

begin

   -- Calculate the signed sum (with sign extension)
   sum_s <= (arg1_i(G_WIDTH-1) & arg1_i) + (arg2_i(G_WIDTH-1) & arg2_i);

   -- Calculate the saturated value
   saturated_s(G_WIDTH-1)          <= sum_s(G_WIDTH);
   saturated_s(G_WIDTH-2 downto 0) <= (others => not sum_s(G_WIDTH));

   -- Generate output depending on overflow or not
   sum_o <= sum_s(G_WIDTH-1 downto 0) when sum_s(G_WIDTH) = sum_s(G_WIDTH-1) else
            saturated_s;

end architecture synthesis;

