-- Author:  Michael Jørgensen
-- License: Public domain; do with it what you like :-)
-- Project: YM2151 implementation
--
-- Description:

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

entity timer is
   generic (
      G_NAME : string
   );
   port (
      clk_i   : in  std_logic;
      start_i : in  std_logic;
      stop_i  : in  std_logic;
      clear_i : in  std_logic;
      act_o   : out std_logic
   );
end entity timer;

architecture synthesis of timer is

   signal timer_cnt_r : std_logic_vector(31 downto 0) := (others => '0');
   signal timer_act_r : std_logic := '0';

begin

   p_timer_act : process (clk_i)
   begin
      if rising_edge(clk_i) then
         if start_i = '1' then
            timer_act_r <= '1';
         end if;

         if stop_i = '1' then
            if timer_act_r = '1' then
               report G_NAME & ": " & integer'image(integer(real(to_integer(timer_cnt_r))/3.579545)) & " us";
            end if;
            timer_act_r <= '0';
         end if;
      end if;
   end process p_timer_act;

   p_timer_cnt : process (clk_i)
   begin
      if rising_edge(clk_i) then
         if timer_act_r = '1' then
            timer_cnt_r <= timer_cnt_r + 1;
         end if;

         if clear_i = '1' then
            timer_cnt_r <= (others => '0');
         end if;
      end if;
   end process p_timer_cnt;

   act_o <= timer_act_r;

end architecture synthesis;

