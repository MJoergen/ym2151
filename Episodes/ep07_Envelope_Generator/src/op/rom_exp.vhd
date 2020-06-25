-- Author:  Michael Jørgensen
-- License: Public domain; do with it what you like :-)
-- Project: YM2151 implementation
--
-- Description: This module performs a table lookup to calculate the
-- exp function.
--
-- The input (8 bits) is interpreted as a value between 0 and 1.
-- The output (11 bits) is a value between 0 and 1.
--
-- The actual function calculated is y = 0.5^x.
-- The MSB of exp_o will always be 1.
--
-- Example: The input 0x68=104 corresponds to x=105/256 = 0.4102.
-- The corresponding output is 0.5^0.4102 = 0.7525, which
-- is encoded as 0.7525*2048 = 1541 = 0x605.
--
-- Latency is 1 clock cycle.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;
use ieee.math_real.all;

entity rom_exp is
   port (
      clk_i  : in  std_logic;
      addr_i : in  std_logic_vector(7 downto 0);
      data_o : out std_logic_vector(10 downto 0)
   );
end entity rom_exp;

architecture synthesis of rom_exp is

   type mem_t is array (0 to 255) of std_logic_vector(10 downto 0);
   
   impure function InitRom return mem_t is
      constant scale_x : real := 256.0;
      constant scale_y : real := 2048.0;
      variable x_v     : real;
      variable y_v     : real;
      variable int_v   : integer;
      variable ROM_v   : mem_t := (others => (others => '0'));
   begin
      for i in 0 to 255 loop
         x_v      := real(i+1) / scale_x;    -- Adding one ensures the exp is never one.
         y_v      := exp(x_v*log(0.5));
         int_v    := integer(y_v*scale_y);   -- Rounding is automatic.
         ROM_v(i) := to_stdlogicvector(int_v, 11);
      end loop;

      return ROM_v;
   end function;

   signal mem_r : mem_t := InitRom;

begin

   -- Read from ROM
   p_read : process (clk_i)
   begin
      if rising_edge(clk_i) then
         data_o <= mem_r(to_integer(addr_i));
      end if;
   end process p_read;

end architecture synthesis;

