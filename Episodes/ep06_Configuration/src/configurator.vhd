-- Author:  Michael Jørgensen
-- License: Public domain; do with it what you like :-)
-- Project: YM2151 implementation
--
-- Description: This module stores the configuration for each of the 32 slots.
-- (using the configuraton interface at the fast clock rate.
-- 
-- At each (slow) clock cycle it outputs the slot number and the corresponding
-- configuration for that slot.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

entity configurator is
   port (
      -- Configuration interface
      cfg_clk_i      : in  std_logic;
      cfg_rst_i      : in  std_logic;
      cfg_valid_i    : in  std_logic;
      cfg_ready_o    : out std_logic;
      cfg_addr_i     : in  std_logic_vector(7 downto 0);
      cfg_data_i     : in  std_logic_vector(7 downto 0);
      -- Configuration output
      clk_int_i      : in  std_logic;
      slot_o         : out std_logic_vector(4 downto 0);
      total_level_o  : out std_logic_vector(6 downto 0);
      key_code_o     : out std_logic_vector(6 downto 0);
      key_fraction_o : out std_logic_vector(5 downto 0)
   );
end entity configurator;

architecture synthesis of configurator is

   type CONFIG_t is array (0 to 31) of std_logic_vector(7 downto 0);

   signal total_level_r : CONFIG_t := (others => (others => '1'));   -- 0x60 - 0x7F
   signal config_r      : CONFIG_t := (others => (others => '0'));   -- 0x20 - 0x3F

   -- Slot Index
   signal slot_r        : std_logic_vector(4 downto 0) := (others => '0');

begin

   -----------------------------------------------------------------------------
   -- Process input.
   -----------------------------------------------------------------------------

   cfg_ready_o <= '1';

   p_config : process (cfg_clk_i)
   begin
      if rising_edge(cfg_clk_i) then
         if cfg_valid_i = '1' then
            case cfg_addr_i(7 downto 5) is
               when "000" => null;
               when "001" => config_r(to_integer(cfg_addr_i(4 downto 0))) <= cfg_data_i;
               when "010" => null;
               when "011" => total_level_r(to_integer(cfg_addr_i(4 downto 0))) <= cfg_data_i;
               when "100" => null;
               when "101" => null;
               when "110" => null;
               when "111" => null;
               when others => null;
            end case;
         end if;
      end if;
   end process p_config;


   -----------------------------------------------------------------------------
   -- Circulate through all slots. Clock at the slow clock.
   -----------------------------------------------------------------------------

   p_slot : process (clk_int_i)
   begin
      if rising_edge(clk_int_i) then
         slot_r <= slot_r + 1;
      end if;
   end process p_slot;


   -----------------------------------------------------------------------------
   -- Output configuration.
   -----------------------------------------------------------------------------

   slot_o         <= slot_r;
   total_level_o  <= total_level_r(to_integer(slot_r))(6 downto 0);
   key_code_o     <= config_r(to_integer(slot_r(2 downto 0)) + 8)(6 downto 0);
   key_fraction_o <= config_r(to_integer(slot_r(2 downto 0)) + 16)(7 downto 2);

end architecture synthesis;

