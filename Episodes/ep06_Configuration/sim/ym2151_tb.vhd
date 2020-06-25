-- Author:  Michael Jørgensen
-- License: Public domain; do with it what you like :-)
-- Project: YM2151 implementation
--
-- Description: This module is a test bench for the YM2151 module.

use std.env.finish;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;
use ieee.math_real.all;

use work.ym2151_bfm_pkg.all;

entity ym2151_tb is
   generic (
      G_OUTPUT_FILENAME : string := "output.wav"
   );
end entity ym2151_tb;

architecture simulation of ym2151_tb is

   constant C_CLOCK_HZ      : integer := 3579545;
   constant C_CLOCK_PERIOD  : time := (10.0**9)/real(C_CLOCK_HZ) * 1.0 ns;

   signal clk_s             : std_logic := '0';
   signal rst_s             : std_logic := '1';
   signal ym2151_s          : ym2151_if_t := C_YM2151_IF_DEFAULT;

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

      -- This measures the period of the output wave and compares with the expected value.
      procedure run_test_frequency(config : config_t) is

         variable last_wav         : std_logic_vector(15 downto 0) := (others => '0');
         variable last_step        : integer := 0;
         variable expected_freq    : real;
         variable observed_samples : integer;
         variable expected_samples : integer;
         variable max_diff         : integer;

         function calc_freq(config : config_t) return real is
            variable key_note : integer;
         begin
            key_note := (config.kc - config.kc/4)*64 + config.kf;
            return 440.0 * 2.0**(real(key_note-3584)/768.0);
         end function calc_freq;

      begin

         report "KC=" & integer'image(config.kc)
            & ", KF=" & integer'image(config.kf);

         ym2151_write_config(config, clk_s, ym2151_s);

         expected_freq    := calc_freq(config);
         expected_samples := integer(3579545.0/64.0/expected_freq);

         for step in 0 to 5*expected_samples loop
            if last_wav(15) = '0' and ym2151_s.wav(15) = '1' then
               if last_step /= 0 then
                  observed_samples := step - last_step;
                  max_diff := 1 + expected_samples / 1000; -- Allow error of 0.1%.
                  if observed_samples < expected_samples-max_diff or
                     observed_samples > expected_samples+max_diff then
                        report "observed_samples: " & integer'image(observed_samples)
                           & ", expected_samples: " & integer'image(expected_samples);
                  end if;
               end if;
               last_step := step;
            end if;

            last_wav := ym2151_s.wav;
            for c in 0 to 63 loop
               wait until clk_s = '1';
            end loop;
         end loop;

      end procedure run_test_frequency;

      variable config : config_t := C_CONFIG_DEFAULT;

   begin
      wait until clk_s = '1' and rst_s = '0';
      wait until clk_s = '1';

      config := C_CONFIG_DEFAULT;
      config.oper_m1.tl := 0;

      config.kc := 16#1A#;
      config.kf :=  0; run_test_frequency(config);
      config.kf := 16; run_test_frequency(config);
      config.kf := 32; run_test_frequency(config);
      config.kf := 48; run_test_frequency(config);
      config.kf := 63; run_test_frequency(config);

      config.kc := 16#30#;
      config.kf :=  0; run_test_frequency(config);
      config.kf := 16; run_test_frequency(config);
      config.kf := 32; run_test_frequency(config);
      config.kf := 48; run_test_frequency(config);
      config.kf := 63; run_test_frequency(config);

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
         clk_i        => clk_s,
         rst_i        => rst_s,
         cfg_valid_i  => ym2151_s.cfg_valid,
         cfg_ready_o  => ym2151_s.cfg_ready,
         cfg_addr_i   => ym2151_s.cfg_addr,
         cfg_data_i   => ym2151_s.cfg_data,
         wav_o        => ym2151_s.wav
      ); -- i_ym2151
   

   -----------------------------------------------------------------------------
   -- Write waveform to file
   -----------------------------------------------------------------------------

   i_wav2file : entity work.wav2file
      generic map (
         G_FILE_NAME => G_OUTPUT_FILENAME
      )
      port map (
         clk_i    => clk_s,
         rst_i    => rst_s,
         active_i => wav2file_active_s,
         wav_i    => ym2151_s.wav
      ); -- i_wav2file
      
end simulation;

