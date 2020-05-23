-- Author:  Michael Jørgensen
-- License: Public domain; do with it what you like :-)
-- Project: YM2151 implementation
--
-- Description: This module stores the configuration for each of the 32 slots.
-- At each clock cycle it outputs the slot number and the corresponding
-- configuration for that slot.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

entity configurator is
   port (
      clk_i          : in  std_logic;
      slot_o         : out std_logic_vector(4 downto 0);
      total_level_o  : out std_logic_vector(6 downto 0);
      key_code_o     : out std_logic_vector(6 downto 0);
      key_fraction_o : out std_logic_vector(5 downto 0)
   );
end entity configurator;

architecture synthesis of configurator is

   signal slot_r : std_logic_vector(4 downto 0) := (others => '0');

begin

   -----------------------------------------------------------------------------
   -- Circulate through all slots.
   -----------------------------------------------------------------------------

   p_slot : process (clk_i)
   begin
      if rising_edge(clk_i) then
         slot_r <= slot_r + 1;
      end if;
   end process p_slot;


   -----------------------------------------------------------------------------
   -- Select hardcoded configuration for the various slots.
   -----------------------------------------------------------------------------

   p_config : process (slot_r)
   begin
      -- Default is to disable the slot.
      total_level_o  <= (others => '1');
      key_code_o     <= (others => '0');
      key_fraction_o <= (others => '0');

      if slot_r = 0 then
         -- This selects the key A4 (with frequency 440 Hz) at -12 dB.
         total_level_o  <= (others => '0');
         key_code_o     <= "1001010";
         key_fraction_o <= (others => '0');
      end if;

      if slot_r = 31 then
         -- This selects the key E5 (with frequency 659 Hz) at -24 dB.
         total_level_o  <= "0010000";
         key_code_o     <= "1010100";
         key_fraction_o <= (others => '0');
      end if;

      if slot_r = 1 then
         -- This selects the key C6 (with frequency 1047 Hz) at -18 dB.
         total_level_o  <= "0001000";
         key_code_o     <= "1011110";
         key_fraction_o <= (others => '0');
      end if;
   end process p_config;

   slot_o <= slot_r;

end architecture synthesis;

