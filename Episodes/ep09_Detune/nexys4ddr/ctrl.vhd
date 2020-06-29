-- Author:  Michael Jørgensen
-- License: Public domain; do with it what you like :-)
-- Project: YM2151 Example Design
--
-- Description: This module contains the controller ROM with the predefined
-- commands for the YM2151.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

entity ctrl is
   generic (
      G_INIT_FILE : string
   );
   port (
      clk_i       : in  std_logic;
      rst_i       : in  std_logic;
      playing_o   : out std_logic;
      cfg_valid_o : out std_logic;
      cfg_ready_i : in  std_logic;
      cfg_addr_o  : out std_logic_vector(7 downto 0);
      cfg_data_o  : out std_logic_vector(7 downto 0)
   );
end ctrl;

architecture synthesis of ctrl is

   signal rom_addr_r  : std_logic_vector(11 downto 0);
   signal rom_data_s  : std_logic_vector(15 downto 0);

   type STATE_t is (WAIT_ST, ADDR_ST, DATA_ST, STOP_ST);
   signal state_r     : STATE_t;
   signal cnt_r       : std_logic_vector(24 downto 0);

   signal playing_r   : std_logic;
   signal cfg_valid_r : std_logic;
   signal cfg_addr_r  : std_logic_vector(7 downto 0);
   signal cfg_data_r  : std_logic_vector(7 downto 0);

begin

   ----------------------------------------------------------------
   -- Instantiate ROM
   ----------------------------------------------------------------

   i_rom_ctrl : entity work.rom_ctrl
      generic map (
         G_INIT_FILE => G_INIT_FILE
      )
      port map (
         clk_i  => clk_i,
         addr_i => rom_addr_r,
         data_o => rom_data_s
      ); -- i_rom_ctrl


   p_ctrl : process (clk_i)
   begin
      if rising_edge(clk_i) then
         case state_r is
            when WAIT_ST =>
               if cnt_r = 0 then
                  state_r <= ADDR_ST;
               else
                  cnt_r <= cnt_r - 1;
               end if;

            when ADDR_ST =>
               playing_r <= '1';
               rom_addr_r <= rom_addr_r + 1;
               if rom_data_s(15 downto 8) /= 0 then
                  cfg_addr_r  <= rom_data_s(15 downto 8);
                  cfg_data_r  <= rom_data_s( 7 downto 0);
                  cfg_valid_r <= '1';
                  state_r    <= DATA_ST;
               elsif rom_data_s /= 0 then
                  cnt_r(24 downto 17) <= rom_data_s(7 downto 0);
                  state_r <= WAIT_ST;
               else
                  state_r <= STOP_ST;
               end if;

            when DATA_ST =>
               if cfg_valid_r = '1' and cfg_ready_i = '1' then
                  cfg_valid_r <= '0';
                  state_r     <= WAIT_ST;
               end if;

            when STOP_ST =>
               playing_r <= '0';
               null;
         end case;

         if rst_i = '1' then
            playing_r   <= '0';
            cfg_valid_r <= '0';
            cfg_addr_r  <= (others => '0');
            cfg_data_r  <= (others => '0');
            rom_addr_r  <= (others => '0');
            -- Wait 200 clock cycles before issuing writes to the YM2151.
            cnt_r       <= to_stdlogicvector(200, 25);
            state_r     <= WAIT_ST;
         end if;
      end if;
   end process p_ctrl;

   playing_o   <= playing_r;
   cfg_valid_o <= cfg_valid_r;
   cfg_addr_o  <= cfg_addr_r;
   cfg_data_o  <= cfg_data_r;

end synthesis;

