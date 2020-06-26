-- Author:  Michael Jørgensen
-- License: Public domain; do with it what you like :-)
-- Project: YM2151 implementation
--
-- Description: This module stores the configuration for each of the 32 slots,
-- using the configuraton interface at the fast clock rate.
-- 
-- At each (slow) clock cycle it outputs the slot number and the corresponding
-- configuration for that slot.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

entity configurator is
   port (
      -- Configuration interface
      cfg_clk_i       : in  std_logic;
      cfg_rst_i       : in  std_logic;
      cfg_valid_i     : in  std_logic;
      cfg_ready_o     : out std_logic;
      cfg_addr_i      : in  std_logic_vector(7 downto 0);
      cfg_data_i      : in  std_logic_vector(7 downto 0);
      -- Configuration output
      clk_int_i       : in  std_logic;
      slot_o          : out std_logic_vector(4 downto 0);
      keyon_o         : out std_logic;
      key_code_o      : out std_logic_vector(6 downto 0);
      key_fraction_o  : out std_logic_vector(5 downto 0);
      con_o           : out std_logic_vector(2 downto 0);
      feedback_o      : out std_logic_vector(2 downto 0);
      total_level_o   : out std_logic_vector(6 downto 0);
      attack_rate_o   : out std_logic_vector(4 downto 0);
      key_scale_o     : out std_logic_vector(1 downto 0);
      decay_rate_o    : out std_logic_vector(4 downto 0);
      sustain_rate_o  : out std_logic_vector(4 downto 0);
      sustain_level_o : out std_logic_vector(3 downto 0);
      release_rate_o  : out std_logic_vector(3 downto 0)
   );
end entity configurator;

architecture synthesis of configurator is

   signal cfg_counter : std_logic_vector(5 downto 0) := (others => '0');

   type KEYON_t is array (0 to 7) of std_logic_vector(3 downto 0);
   type CONFIG_t is array (0 to 31) of std_logic_vector(7 downto 0);

   signal keyon_r    : KEYON_t := (others => (others => '0'));
   signal range_20_r : CONFIG_t := (others => (others => '0'));
   signal range_40_r : CONFIG_t := (others => (others => '0'));
   signal range_60_r : CONFIG_t := (others => (others => '1'));
   signal range_80_r : CONFIG_t := (others => (others => '0'));
   signal range_a0_r : CONFIG_t := (others => (others => '0'));
   signal range_c0_r : CONFIG_t := (others => (others => '0'));
   signal range_e0_r : CONFIG_t := (others => (others => '0'));

   -- Slot Index
   signal slot_r     : std_logic_vector(4 downto 0) := (others => '0');

begin

   -----------------------------------------------------------------------------
   -- Process input.
   -----------------------------------------------------------------------------

   cfg_ready_o <= '1' when cfg_counter = 0 else '0';

   p_config : process (cfg_clk_i)
   begin
      if rising_edge(cfg_clk_i) then
         if cfg_counter /= 0 then
            if cfg_counter > 1 or slot_r = 31 then
               cfg_counter <= cfg_counter - 1;
            end if;
         end if;

         if cfg_valid_i = '1' and cfg_ready_o = '1' then
            case cfg_addr_i(7 downto 5) is
               when "000" =>
                  if cfg_addr_i(4 downto 0) = 8 then
                     keyon_r(to_integer(cfg_data_i(2 downto 0))) <= cfg_data_i(6 downto 3);
                  end if;
               when "001" => range_20_r(to_integer(cfg_addr_i(4 downto 0))) <= cfg_data_i;
               when "010" => range_40_r(to_integer(cfg_addr_i(4 downto 0))) <= cfg_data_i;
               when "011" => range_60_r(to_integer(cfg_addr_i(4 downto 0))) <= cfg_data_i;
               when "100" => range_80_r(to_integer(cfg_addr_i(4 downto 0))) <= cfg_data_i;
               when "101" => range_a0_r(to_integer(cfg_addr_i(4 downto 0))) <= cfg_data_i;
               when "110" => range_c0_r(to_integer(cfg_addr_i(4 downto 0))) <= cfg_data_i;
               when "111" => range_e0_r(to_integer(cfg_addr_i(4 downto 0))) <= cfg_data_i;
               when others => null;
            end case;

            cfg_counter <= (others => '1');
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

   slot_o          <= slot_r;
   keyon_o         <= keyon_r(to_integer(slot_r(2 downto 0)))(to_integer(slot_r(3) & slot_r(4)));
   key_code_o      <= range_20_r(to_integer(slot_r(2 downto 0)) + 8)(6 downto 0);
   key_fraction_o  <= range_20_r(to_integer(slot_r(2 downto 0)) + 16)(7 downto 2);
   con_o           <= range_20_r(to_integer(slot_r(2 downto 0)))(2 downto 0);
   feedback_o      <= range_20_r(to_integer(slot_r(2 downto 0)))(5 downto 3);
   total_level_o   <= range_60_r(to_integer(slot_r))(6 downto 0);
   attack_rate_o   <= range_80_r(to_integer(slot_r))(4 downto 0);
   key_scale_o     <= range_80_r(to_integer(slot_r))(7 downto 6);
   decay_rate_o    <= range_a0_r(to_integer(slot_r))(4 downto 0);
   sustain_rate_o  <= range_c0_r(to_integer(slot_r))(4 downto 0);
   sustain_level_o <= range_e0_r(to_integer(slot_r))(7 downto 4);
   release_rate_o  <= range_e0_r(to_integer(slot_r))(3 downto 0);

end architecture synthesis;

