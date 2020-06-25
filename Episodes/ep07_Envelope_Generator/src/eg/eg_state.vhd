-- Author:  Michael Jørgensen
-- License: Public domain; do with it what you like :-)
-- Project: YM2151 implementation
--
-- Description: This block controls the state machine of the Envelope
-- Generator.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

entity eg_state is
   port (
      last_atten_i : in  std_logic_vector(9 downto 0);
      last_state_i : in  std_logic_vector(1 downto 0);
      keyon_i      : in  std_logic;
      sustain_i    : in  std_logic_vector(4 downto 0);
      state_o      : out std_logic_vector(1 downto 0)
   );
end entity eg_state;

architecture synthesis of eg_state is

   constant C_ATTACK_ST  : std_logic_vector(1 downto 0) := "00";
   constant C_DECAY_ST   : std_logic_vector(1 downto 0) := "01";
   constant C_SUSTAIN_ST : std_logic_vector(1 downto 0) := "10";
   constant C_RELEASE_ST : std_logic_vector(1 downto 0) := "11";

begin

   -----------------------------------------------------------------------------
   -- Determine state transitions based on last value of attenuation and
   -- any external events.
   -----------------------------------------------------------------------------

   p_state : process (all)
   begin
      -- Set default values.
      state_o <= last_state_i;

      case last_state_i is
         when C_ATTACK_ST =>
            if last_atten_i = 0 then
               state_o <= C_DECAY_ST;
            end if;
            if keyon_i = '0' then
               state_o <= C_RELEASE_ST;
            end if;

         when C_DECAY_ST =>
            if last_atten_i(9 downto 5) >= sustain_i then
               state_o <= C_SUSTAIN_ST;
            end if;
            if keyon_i = '0' then
               state_o <= C_RELEASE_ST;
            end if;

         when C_SUSTAIN_ST =>
            if keyon_i = '0' then
               state_o <= C_RELEASE_ST;
            end if;

         when C_RELEASE_ST =>
            if keyon_i = '1' then
               state_o <= C_ATTACK_ST;
            end if;

         when others => null;
      end case;
   end process p_state;

end architecture synthesis;

