-- Author:  Michael Jørgensen
-- License: Public domain; do with it what you like :-)
-- Project: YM2151 implementation
--
-- Description: This block determines when to update the attenuation, and by
-- how much.
-- * lsb_o    : Toggles eight times within an update period.
-- * bit_o    : Is high if the attenuation should be updated.
-- * shifts_o : Determines how much the attenuation should be updated with.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

entity eg_timing is
   port (
      clk_i    : in  std_logic;
      rst_i    : in  std_logic;
      rate_i   : in  std_logic_vector(5 downto 0);
      lsb_o    : out std_logic;
      bit_o    : out std_logic;
      shifts_o : out integer range 0 to 2
   );
end entity eg_timing;

architecture synthesis of eg_timing is

   -- Global free-running counter.
   signal counter_low_r   : std_logic_vector(6 downto 0); -- Counts 0-95
   signal counter_r       : std_logic_vector(14 downto 0);

   signal counter_slice_s : std_logic_vector(2 downto 0);
   signal pattern_s       : std_logic_vector(7 downto 0);
   signal rate_s          : std_logic_vector(5 downto 0);

   constant C_PATTERN_0   : std_logic_vector(7 downto 0) := "00000000";
   constant C_PATTERN_1   : std_logic_vector(7 downto 0) := "10000000";
   constant C_PATTERN_2   : std_logic_vector(7 downto 0) := "10001000";
   constant C_PATTERN_3   : std_logic_vector(7 downto 0) := "10101000";
   constant C_PATTERN_4   : std_logic_vector(7 downto 0) := "10101010";
   constant C_PATTERN_5   : std_logic_vector(7 downto 0) := "11101010";
   constant C_PATTERN_6   : std_logic_vector(7 downto 0) := "11101110";
   constant C_PATTERN_7   : std_logic_vector(7 downto 0) := "11111110";
   constant C_PATTERN_8   : std_logic_vector(7 downto 0) := "11111111";

begin

   -----------------------------------------------------------------------------
   -- Free-running global counter.
   -----------------------------------------------------------------------------

   p_counter : process (clk_i)
   begin
      if rising_edge(clk_i) then
         if counter_low_r = 47 then
            counter_low_r <= (others => '0');
            counter_r <= counter_r + 1;
         else
            counter_low_r <= counter_low_r + 1;
         end if;

         if rst_i = '1' then
            counter_low_r <= (others => '0');
            counter_r <= (others => '0');
         end if;
      end if;
   end process p_counter;


   -----------------------------------------------------------------------------
   -- Get slice from counter.
   -----------------------------------------------------------------------------

   p_counter_slice : process (all)
   begin
      -- Get 3-bit slice from global counter and pattern.
      if rate_i(5 downto 2) < 12 then
         counter_slice_s <= counter_r(14-to_integer(rate_i(5 downto 2)) downto
                                      12-to_integer(rate_i(5 downto 2)));
      else
         counter_slice_s <= counter_r(2 downto 0);
      end if;
   end process p_counter_slice;


   lsb_o <= counter_slice_s(0);


   -----------------------------------------------------------------------------
   -- Get increment pattern.
   -----------------------------------------------------------------------------

   p_pattern : process (all)
   begin
      case rate_i(1 downto 0) is
         when "00" => pattern_s <= C_PATTERN_4;
         when "01" => pattern_s <= C_PATTERN_5;
         when "10" => pattern_s <= C_PATTERN_6;
         when "11" => pattern_s <= C_PATTERN_7;
         when others => null;
      end case;
   end process p_pattern;


   bit_o <= '1' when rate_i(5 downto 2) = "1111" else
            '0' when rate_i(5 downto 1) = "00000" else
            pattern_s(to_integer(counter_slice_s));


   -----------------------------------------------------------------------------
   -- Get size of update.
   -----------------------------------------------------------------------------

   p_delta : process (all)
   begin
      case rate_i(5 downto 2) is
         when "1111" => shifts_o <= 2;
         when "1110" => shifts_o <= 2;
         when "1101" => shifts_o <= 1;
         when "1100" => shifts_o <= 0;
         when others => shifts_o <= 0;
      end case;
   end process p_delta;


end architecture synthesis;

