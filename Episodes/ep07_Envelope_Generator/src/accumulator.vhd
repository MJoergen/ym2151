-- Author:  Michael Jørgensen
-- License: Public domain; do with it what you like :-)
-- Project: YM2151 implementation
--
-- Description:

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

entity accumulator is
   port (
      clk_i   : in  std_logic;
      rst_i   : in  std_logic;
 
      slot_i  : in  std_logic_vector(4 downto 0);
      value_i : in  std_logic_vector(13 downto 0);

      wav_o   : out std_logic_vector(15 downto 0)
   );
end entity accumulator;

architecture synthesis of accumulator is

   constant C_OFFSET : std_logic_vector(15 downto 0) := X"8000";

   signal value_s    : std_logic_vector(15 downto 0);
   signal sum_s      : std_logic_vector(15 downto 0);
   signal sum_r      : std_logic_vector(15 downto 0);
   signal sample_r   : std_logic_vector(15 downto 0);

begin

   -- Sign extending to 16 bit value in total.
   value_s <= value_i(13) & value_i(13) & value_i;

   i_saturated_sum_signed : entity work.saturated_sum_signed
      generic map (
         G_WIDTH => 16
      )
      port map (
         arg1_i => sum_r,
         arg2_i => value_s,
         sum_o  => sum_s
      ); -- i_saturated_sum_signed


   -----------------------------------------------------------------------------
   -- Update the running sum, and reset after the last slot.
   -----------------------------------------------------------------------------

   p_sum : process (clk_i)
   begin
      if rising_edge(clk_i) then
         sum_r <= sum_s;

         if slot_i = 31 then
            sample_r <= sum_s;
            sum_r    <= (others => '0');
         end if;
      end if;
   end process p_sum;


   -- Connect output
   wav_o <= sample_r;

end architecture synthesis;

