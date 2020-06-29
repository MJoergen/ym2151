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
      con_i   : in  std_logic_vector(2 downto 0);
      value_i : in  std_logic_vector(13 downto 0);

      wav_o   : out std_logic_vector(15 downto 0)
   );
end entity accumulator;

architecture synthesis of accumulator is

   constant C_OP_M1  : std_logic_vector(1 downto 0) := "00";
   constant C_OP_M2  : std_logic_vector(1 downto 0) := "01";
   constant C_OP_C1  : std_logic_vector(1 downto 0) := "10";
   constant C_OP_C2  : std_logic_vector(1 downto 0) := "11";

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
         case slot_i(4 downto 3) is
            when C_OP_M1 =>
               case to_integer(con_i) is
                  when 0 => null;
                  when 1 => null;
                  when 2 => null;
                  when 3 => null;
                  when 4 => null;
                  when 5 => null;
                  when 6 => null;
                  when 7 => sum_r <= sum_s;
                  when others => null;
               end case;

            when C_OP_M2 =>
               case to_integer(con_i) is
                  when 0 => null;
                  when 1 => null;
                  when 2 => null;
                  when 3 => null;
                  when 4 => null;
                  when 5 => sum_r <= sum_s;
                  when 6 => sum_r <= sum_s;
                  when 7 => sum_r <= sum_s;
                  when others => null;
               end case;

            when C_OP_C1 =>
               case to_integer(con_i) is
                  when 0 => null;
                  when 1 => null;
                  when 2 => null;
                  when 3 => null;
                  when 4 => sum_r <= sum_s;
                  when 5 => sum_r <= sum_s;
                  when 6 => sum_r <= sum_s;
                  when 7 => sum_r <= sum_s;
                  when others => null;
               end case;

            when C_OP_C2 =>
               case to_integer(con_i) is
                  when 0 => sum_r <= sum_s;
                  when 1 => sum_r <= sum_s;
                  when 2 => sum_r <= sum_s;
                  when 3 => sum_r <= sum_s;
                  when 4 => sum_r <= sum_s;
                  when 5 => sum_r <= sum_s;
                  when 6 => sum_r <= sum_s;
                  when 7 => sum_r <= sum_s;
                  when others => null;
               end case;

            when others => null;
         end case;

         if slot_i = 7 then -- 7 (rather than 31) matches the YM2151.
            sample_r <= sum_s;
            sum_r    <= (others => '0');
         end if;
      end if;
   end process p_sum;


   -- Connect output
   wav_o <= sample_r;

end architecture synthesis;

