-- Author:  Michael Jørgensen
-- License: Public domain; do with it what you like :-)
-- Project: YM2151 implementation
--
-- Description: This module is a test bench for the YM2151 module.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

entity ym2151_tb is
   generic (
      G_INPUT_FILENAME  : string;
      G_OUTPUT_FILENAME : string := "music.wav"
   );
end entity ym2151_tb;

architecture simulation of ym2151_tb is

   constant C_CLOCK_HZ        : integer := 3579545;
   constant C_CLOCK_PERIOD    : time := (10.0**9)/real(C_CLOCK_HZ) * 1.0 ns;

   -- Connected to the YM2151
   signal clk_s               : std_logic;
   signal rst_s               : std_logic;
   signal cfg_valid_s         : std_logic;
   signal cfg_ready_s         : std_logic;
   signal cfg_addr_s          : std_logic_vector(7 downto 0);
   signal cfg_data_s          : std_logic_vector(7 downto 0);
   signal wav_s               : std_logic_vector(15 downto 0);

   signal playing_s           : std_logic;
   signal test_running_s      : std_logic := '1';
   signal test_running_r      : std_logic := '1';
   signal test_running_d      : std_logic := '1';

   signal deb_atten0_s        : std_logic_vector(9 downto 0);

   signal attack_start_r      : std_logic;
   signal attack_stop_r       : std_logic;
   signal attack_clear_r      : std_logic;
   signal attack_act_s        : std_logic;

   signal release_start_r     : std_logic;
   signal release_stop_r      : std_logic;
   signal release_clear_r     : std_logic;
   signal release_act_s       : std_logic;

begin

   -----------------------------------------------------------------------------
   -- Generate clock and reset
   -----------------------------------------------------------------------------

   -- Generate clock
   p_clk : process
   begin
      clk_s <= '1', '0' after C_CLOCK_PERIOD/2;
      wait for C_CLOCK_PERIOD;

      -- Stop clock when test is finished
      if test_running_d = '0' then
         wait;
      end if;
   end process p_clk;

   -- Generate reset
   p_rst : process
   begin
      rst_s <= '1', '0' after 80*C_CLOCK_PERIOD;
      wait;
   end process p_rst;

   p_test_running : process
   begin
      wait until playing_s = '1';
      wait until playing_s = '0' or (release_act_s = '1' and release_stop_r = '1');
      test_running_s <= '0';
      wait;
   end process p_test_running;

   -- Let clock run a few cycles at end of test.
   -- This allows the wav2file module to close the file.
   p_test_running_r : process (clk_s)
   begin
      test_running_r <= test_running_s;
      test_running_d <= test_running_r;
   end process p_test_running_r;


   ----------------------------------------------------------------
   -- Instantiate controller
   ----------------------------------------------------------------

   i_ctrl : entity work.ctrl
      generic map (
         G_INIT_FILE => G_INPUT_FILENAME
      )
      port map (
         clk_i       => clk_s,
         rst_i       => rst_s,
         playing_o   => playing_s,
         cfg_valid_o => cfg_valid_s,
         cfg_ready_i => cfg_ready_s,
         cfg_addr_o  => cfg_addr_s,
         cfg_data_o  => cfg_data_s
      ); -- i_ctrl


   -----------------------------------------------------------------------------
   -- Instantiate the YM2151.
   -----------------------------------------------------------------------------

   i_ym2151 : entity work.ym2151
      port map (
         clk_i        => clk_s,
         rst_i        => rst_s,
         cfg_valid_i  => cfg_valid_s,
         cfg_ready_o  => cfg_ready_s,
         cfg_addr_i   => cfg_addr_s,
         cfg_data_i   => cfg_data_s,
         deb_atten0_o => deb_atten0_s,
         wav_o        => wav_s
      ); -- i_ym2151
   

   -----------------------------------------------------------------------------
   -- Write waveform to file.
   -----------------------------------------------------------------------------

   i_wav2file : entity work.wav2file
      generic map (
         G_FILE_NAME => G_OUTPUT_FILENAME
      )
      port map (
         clk_i    => clk_s,
         rst_i    => rst_s,
         active_i => test_running_s,
         wav_i    => wav_s
      ); -- i_wav2file


   -----------------------------------------------------------------------------
   -- Measure attack time.
   -----------------------------------------------------------------------------

   p_attack : process (clk_s)
   begin
      if rising_edge(clk_s) then
         attack_start_r <= '0';
         attack_stop_r  <= '0';
         attack_clear_r <= '0';

         if deb_atten0_s = 0 then
            attack_stop_r <= '1';    -- Stop timer at maximum volume.
         else
            attack_start_r <= '1';   -- Start timer when volume increases.
         end if;
         if deb_atten0_s = X"3FF" then
            attack_clear_r <= '1';   -- Clear timer at maximum attenuation.
         end if;
      end if;
   end process p_attack;

   i_timer_attack : entity work.timer
      generic map (
         G_NAME => "Attack"
      )
      port map (
         clk_i   => clk_s,
         start_i => attack_start_r,
         stop_i  => attack_stop_r,
         clear_i => attack_clear_r,
         act_o   => attack_act_s
      ); -- i_timer_attack


   -----------------------------------------------------------------------------
   -- Measure release time.
   -----------------------------------------------------------------------------

   p_release : process (clk_s)
   begin
      if rising_edge(clk_s) then
         release_start_r <= '0';
         release_stop_r  <= '0';
         release_clear_r <= '0';

         if deb_atten0_s = 0 then
            release_clear_r <= '1';   -- Clear timer at maximum volume.
         else
            release_start_r <= '1';   -- Start timer when volume decreases.
         end if;
         if deb_atten0_s = X"3FF" then
            release_stop_r <= '1';    -- Stop timer at maximum attenuation.
         end if;
      end if;
   end process p_release;

   i_timer_release : entity work.timer
      generic map (
         G_NAME => "Release"
      )
      port map (
         clk_i   => clk_s,
         start_i => release_start_r,
         stop_i  => release_stop_r,
         clear_i => release_clear_r,
         act_o   => release_act_s
      ); -- i_timer

end simulation;

