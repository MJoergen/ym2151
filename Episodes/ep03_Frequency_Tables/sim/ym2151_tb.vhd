-- Author:  Michael Jørgensen
-- License: Public domain; do with it what you like :-)
-- Project: YM2151 implementation
--
-- Description: This module is a test bench for the YM2151 module.

use std.env.finish;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

entity ym2151_tb is
   generic (
      G_OUTPUT_FILENAME : string := "output.wav"
   );
end entity ym2151_tb;

architecture simulation of ym2151_tb is

   constant C_CLOCK_HZ      : integer := 3579545;
   constant C_CLOCK_PERIOD  : time := (10.0**9)/real(C_CLOCK_HZ) * 1.0 ns;

   -- Connected to the YM2151
   signal clk_s             : std_logic;
   signal rst_s             : std_logic;
   signal wav_s             : std_logic_vector(15 downto 0);

   signal wav2file_active_s : std_logic := '1';

begin

   -----------------------------------------------------------------------------
   -- Generate clock and reset
   -----------------------------------------------------------------------------

   -- Generate clock
   p_clk : process
   begin
      clk_s <= '1', '0' after C_CLOCK_PERIOD/2;
      wait for C_CLOCK_PERIOD;
   end process p_clk;

   -- Generate reset
   p_rst : process
   begin
      rst_s <= '1', '0' after 80*C_CLOCK_PERIOD;
      wait;
   end process p_rst;


   -----------------------------------------------------------------------------
   -- The main test process, including helper procedures.
   -----------------------------------------------------------------------------

   p_test : process
   begin
      wait for 100 ms;

      -- Stop test
      wav2file_active_s <= '0';

      -- Make sure output file is saved to disk.
      wait until clk_s = '1';
      wait until clk_s = '1';
      wait until clk_s = '1';

      finish;
   end process p_test;


   -----------------------------------------------------------------------------
   -- Instantiate the YM2151.
   -----------------------------------------------------------------------------

   i_ym2151 : entity work.ym2151
      port map (
         clk_i => clk_s,
         rst_i => rst_s,
         wav_o => wav_s
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
         active_i => wav2file_active_s,
         wav_i    => wav_s
      ); -- i_wav2file

end simulation;

