-- Author:  Michael Jørgensen
-- License: Public domain; do with it what you like :-)
-- Project: YM2151 implementation
--
-- Description: This module is a test bench for the YM2151 module.
-- It tests the envelope generation.

use std.env.finish;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;
use ieee.math_real.all;

use work.ym2151_model_pkg.all;
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

      -- Measure time until attenuation reaches specific level.
      procedure verify_attenuation_time(name  : string;
                                        steps : integer;
                                        atten : integer) is
         variable observed : integer;
         variable max_diff : integer;
      begin
         -- measure time to reach desired attenuation level.
         observed := steps*2;
         for step in 0 to steps*2 loop
            if ym2151_s.atten0 = atten then
               observed := step;
               exit;
            end if;

            for c in 0 to 63 loop
               wait until clk_s = '1';
            end loop;
         end loop;

         max_diff := steps/50+5; -- 2 percent error (plus extra) is allowed
         if observed < steps - max_diff or
            observed > steps + max_diff then
            report name
               & ": observed=" & integer'image(observed)
               & ", expected=" & integer'image(steps);
         end if;
      end procedure verify_attenuation_time;

      procedure run_test_envelope(config        : config_t;
                                  release_level : integer) is
         variable envelope : ym2151_envelope_t;

      begin
         report "EG: AR=" & integer'image(config.oper_m1.ar)
                & ", DR=" & integer'image(config.oper_m1.dr)
                & ", SL=" & integer'image(config.oper_m1.sl)
                & ", SR=" & integer'image(config.oper_m1.sr)
                & ", RR=" & integer'image(config.oper_m1.rr)
                & ", KC=" & integer'image(config.kc);

         -- Make sure attenuation is max before the test starts.
         assert ym2151_s.atten0 = 16#3FF#;

         ym2151_write_config(config, clk_s, ym2151_s);
         envelope := ym2151_calcExpectedEnvelope(config, release_level);

         verify_attenuation_time("Attack",  envelope.attack_time,  0);
         verify_attenuation_time("Decay",   envelope.decay_time,   envelope.sustain_level);
         verify_attenuation_time("Sustain", envelope.sustain_time, release_level);
         -- Key OFF to all operators
         ym2151_write(X"08", X"00", clk_s, ym2151_s);
         verify_attenuation_time("Release", envelope.release_time, 16#3FF#);

      end procedure run_test_envelope;

      -- This measures the period of the output wave and compares with the expected value.
      procedure run_test_frequency(config : config_t) is

         variable last_wav         : std_logic_vector(15 downto 0) := (others => '0');
         variable last_step        : integer := 0;
         variable phase_inc        : integer;
         variable observed_samples : integer;
         variable expected_samples : integer;
         variable max_diff         : integer;

      begin

         report "KC=" & integer'image(config.kc)
            & ", KF=" & integer'image(config.kf);

         ym2151_write_config(config, clk_s, ym2151_s);

         phase_inc := calc_phase_inc(config);
         expected_samples := 1048576/phase_inc;

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

      -- Test fast envelope
      config            := C_CONFIG_DEFAULT;
      config.oper_m1.tl := 0;
      config.oper_m1.ar := 31;
      config.oper_m1.dr := 31;
      config.oper_m1.sl := 15;
      config.oper_m1.sr := 31;
      config.oper_m1.rr := 15;

      config.kc :=  0; run_test_envelope(config, 768);
      config.kc := 32; run_test_envelope(config, 768);
      config.kc := 64; run_test_envelope(config, 768);
      config.kc := 96; run_test_envelope(config, 768);

      config            := C_CONFIG_DEFAULT;
      config.oper_m1.tl := 0;
      config.oper_m1.ar := 30;
      config.oper_m1.dr := 30;
      config.oper_m1.sl := 14;
      config.oper_m1.sr := 30;
      config.oper_m1.rr := 14;

      config.kc :=  0; run_test_envelope(config, 768);
      config.kc := 32; run_test_envelope(config, 768);
      config.kc := 64; run_test_envelope(config, 768);
      config.kc := 96; run_test_envelope(config, 768);

      -- Test medium envelope
      config            := C_CONFIG_DEFAULT;
      config.oper_m1.tl := 0;
      config.oper_m1.ar := 19;
      config.oper_m1.dr := 21;
      config.oper_m1.sl := 4;
      config.oper_m1.sr := 25;
      config.oper_m1.rr := 11;

      config.kc :=  0; run_test_envelope(config, 768);
      config.kc := 32; run_test_envelope(config, 768);
      config.kc := 64; run_test_envelope(config, 768);
      config.kc := 96; run_test_envelope(config, 768);

      -- Test sine frequency
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
         wav_o        => ym2151_s.wav,
         deb_atten0_o => ym2151_s.atten0
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
         wav_i    => ym2151_s.wav
      ); -- i_wav2file
      
end simulation;

