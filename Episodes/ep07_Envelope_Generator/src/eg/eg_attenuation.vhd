-- Author:  Michael Jørgensen
-- License: Public domain; do with it what you like :-)
-- Project: YM2151 implementation
--
-- Description:

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

entity eg_attenuation is
   port (
      last_atten_i : in  std_logic_vector(9 downto 0);
      rate_i       : in  std_logic_vector(5 downto 0);
      state_i      : in  std_logic_vector(1 downto 0);
      update_i     : in  std_logic;
      shifts_i     : in  integer range 0 to 2;
      atten_o      : out std_logic_vector(9 downto 0)
   );
end entity eg_attenuation;

architecture synthesis of eg_attenuation is

   constant C_ATTACK_ST  : std_logic_vector(1 downto 0) := "00";
   constant C_DECAY_ST   : std_logic_vector(1 downto 0) := "01";
   constant C_SUSTAIN_ST : std_logic_vector(1 downto 0) := "10";
   constant C_RELEASE_ST : std_logic_vector(1 downto 0) := "11";
  
begin

   -----------------------------------------------------------------------------
   -- Calculate new attenuation.
   -----------------------------------------------------------------------------

   p_atten : process (all)
   begin
      -- Set default values.
      atten_o <= last_atten_i;

      -- Is it time to update the attenuation?
      if update_i = '1' then
         if state_i = C_ATTACK_ST then
            case shifts_i is
               when 0 => atten_o <= last_atten_i + ("1111" & not (last_atten_i(9 downto 4)));
               when 1 => atten_o <= last_atten_i + ("111" & not (last_atten_i(9 downto 3)));
               when 2 => atten_o <= last_atten_i + ("11" & not (last_atten_i(9 downto 2)));
            end case;
         else
            if last_atten_i < 1024-4 then
               case shifts_i is
                  when 0 => atten_o <= last_atten_i + 1;
                  when 1 => atten_o <= last_atten_i + 2;
                  when 2 => atten_o <= last_atten_i + 4;
               end case;
            else
               atten_o <= (others => '1');
            end if;
         end if;
      end if;

      -- Maximum attack rate means transition immediately to maximum volume.
      if state_i = C_ATTACK_ST and rate_i = 63 then
         atten_o <= (others => '0');
      end if;
   end process p_atten;

end architecture synthesis;

