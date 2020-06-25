-- Author:  Michael Jørgensen
-- License: Public domain; do with it what you like :-)
-- Project: YM2151 implementation
--
-- Description: This module performs a table lookup to calculate the
-- the logsin function.
--
-- The input (8 bits) is interpreted as an angle between 0 and pi/2.
-- The output (12 bits) is in units of 1/256th powers of 2.
--
-- The actual funtion calculated is:
-- -log2(sin((x+0.5)/256*pi/2))*256
--
-- Example. The angle pi/6 corresponds to 256/3 = 85 = 0x55.
-- The corresponding output is 256 = 0x100.
--
-- Latency is 1 clock cycle.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;
use ieee.math_real.all;

entity rom_logsin is
   port (
      clk_i  : in  std_logic;
      addr_i : in  std_logic_vector(7 downto 0);
      data_o : out std_logic_vector(11 downto 0)
   );
end entity rom_logsin;

architecture synthesis of rom_logsin is

   type mem_t is array (0 to 255) of std_logic_vector(11 downto 0);
   
   impure function InitRom return mem_t is
      constant scale_x : real := 256.0;
      constant scale_y : real := 256.0;
      variable x_v     : real;
      variable y_v     : real;
      variable int_v   : integer;
      variable ROM_v   : mem_t := (others => (others => '0'));
   begin
      for i in 0 to 255 loop
         -- Adding 0.5 ensures the sine is never zero.
         x_v      := (real(i)+0.5) * 0.5 * MATH_PI / scale_x;
         y_v      := -log(sin(x_v))/log(2.0);
         int_v    := integer(y_v*scale_y);   -- Rounding is automatic.
         ROM_v(i) := to_stdlogicvector(int_v, 12);
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

