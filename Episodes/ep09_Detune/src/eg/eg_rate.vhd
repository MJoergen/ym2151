-- Author:  Michael Jørgensen
-- License: Public domain; do with it what you like :-)
-- Project: YM2151 implementation
--
-- Description: This block generates an internal rate value (0 to 63) based on
-- the current state and the configuration settings.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

entity eg_rate is
   port (
      key_scale_i    : in  std_logic_vector(1 downto 0);
      key_code_i     : in  std_logic_vector(6 downto 0);
      attack_rate_i  : in  std_logic_vector(4 downto 0);
      decay_rate_i   : in  std_logic_vector(4 downto 0);
      sustain_rate_i : in  std_logic_vector(4 downto 0);
      release_rate_i : in  std_logic_vector(3 downto 0);
      state_i        : in  std_logic_vector(1 downto 0);
      rate_o         : out std_logic_vector(5 downto 0)
   );
end entity eg_rate;

architecture synthesis of eg_rate is

   signal rate_state_s   : std_logic_vector(5 downto 0);
   signal rate_delta_s   : std_logic_vector(5 downto 0);

   constant C_ATTACK_ST  : std_logic_vector(1 downto 0) := "00";
   constant C_DECAY_ST   : std_logic_vector(1 downto 0) := "01";
   constant C_SUSTAIN_ST : std_logic_vector(1 downto 0) := "10";
   constant C_RELEASE_ST : std_logic_vector(1 downto 0) := "11";

begin

   rate_state_s <= attack_rate_i  &  "0" when state_i = C_ATTACK_ST  else
                   decay_rate_i   &  "0" when state_i = C_DECAY_ST   else
                   sustain_rate_i &  "0" when state_i = C_SUSTAIN_ST else
                   release_rate_i & "10";


   -----------------------------------------------------------------------------
   -- Calculate rate adjustment according to key being played.
   -----------------------------------------------------------------------------

   p_rate_delta : process (all)
   begin
      -- Set default value
      rate_delta_s <= (others => '0');

      -- Only adjust nonzero rates.
      if rate_state_s /= 0 then
         case key_scale_i is
            when "00" => rate_delta_s <= "0000" & key_code_i(6 downto 5);
            when "01" => rate_delta_s <= "000" & key_code_i(6 downto 4);
            when "10" => rate_delta_s <= "00" & key_code_i(6 downto 3);
            when "11" => rate_delta_s <= "0" & key_code_i(6 downto 2);
            when others => null;
         end case;
      end if;
   end process p_rate_delta;


   -----------------------------------------------------------------------------
   -- Calculate combined rate, saturating at the maximum value of 63.
   -----------------------------------------------------------------------------

   i_saturated_sum_unsigned : entity work.saturated_sum_unsigned
      generic map (
         G_WIDTH => 6
      )
      port map (
         arg1_i => rate_state_s,
         arg2_i => rate_delta_s,
         sum_o  => rate_o
      ); -- i_saturated_sum_unsigned

end architecture synthesis;

