-- Author:  Michael Jørgensen
-- License: Public domain; do with it what you like :-)
-- Project: YM2151 implementation
--
-- Description: This module is a simulation model of the YM2151 module.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;
use ieee.math_real.all;

use work.ym2151_bfm_pkg.all;  -- config_t

package ym2151_model_pkg is

   type ym2151_envelope_t is record
      attack_time   : integer; -- Number of samples
      decay_time    : integer; -- Number of samples
      sustain_level : integer; -- Attenuation level (units of 3/4 dB).
      sustain_time  : integer; -- Number of samples
      release_time  : integer; -- Number of samples
   end record ym2151_envelope_t;

   -- Calculate the expected output 'step' number of steps after Key ON, based on the supplied configuration.
   -- This procedure maintains state in the config variable.
   procedure ym2151_calcExpectedWaveform(step     : integer;
                                         config   : inout config_t;
                                         expected : out integer);

   function calc_phase_inc(config : config_t) return integer;

   function ym2151_calcExpectedEnvelope(config        : config_t;
                                        release_level : integer) return ym2151_envelope_t;

   function string_ph(ph   : integer) return string;
   function string_out(val : integer) return string;

end package ym2151_model_pkg;

package body ym2151_model_pkg is

   function string_ph(ph : integer) return string is
   begin
      return to_hstring(to_stdlogicvector(ph mod 1024, 10));
   end function;

   function string_out(val : integer) return string is
   begin
      return to_hstring(to_stdlogicvector(val, 16));
   end function;

   function calc_phase_inc(config : config_t) return integer is
      variable kc_kf      : integer;
      variable key_note   : integer;
      variable key_octave : integer;
      variable freq_note  : real;
      variable phinc_note : integer;
      variable phase_inc  : integer;
   begin
      kc_kf := config.kc * 64 + config.kf;

      key_note   := kc_kf mod 1024;
      key_octave := kc_kf / 1024;

      -- Calculate frequency corresponding to octave number 2.
      -- Key code 0x2A has frequency 110.0 Hz;
      freq_note  := 2.0**(real(key_note - (key_note/4/64)*64 - 8*64)/12.0/64.0)*110.0;
      phinc_note := integer(1048576.0*64.0/3579545.0*freq_note);

      case key_octave is
         when 0 => phase_inc := phinc_note / 4;
         when 1 => phase_inc := phinc_note / 2;
         when 2 => phase_inc := phinc_note;
         when 3 => phase_inc := phinc_note *  2;
         when 4 => phase_inc := phinc_note *  4;
         when 5 => phase_inc := phinc_note *  8;
         when 6 => phase_inc := phinc_note * 16;
         when 7 => phase_inc := phinc_note * 32;
         when others => phase_inc := 0;
      end case;

      return phase_inc;
   end function calc_phase_inc;

   procedure ym2151_calcExpectedWaveform(step : integer; config : inout config_t; expected : out integer) is

      -- This is the main funtion that (approximately) calculates
      -- 0.5^(tl/8) * sin(2*pi*ph/1024).
      -- This function gives results identical to the YM2151.
      function operator(ph : integer; tl : integer) return integer is
         constant C_TWO_PI : real := 2.0 * 3.1415926535897932384626433832795;
         variable tmp      : real;
         variable sgn      : real;
         variable logsin   : integer;
         variable res      : real;
         variable exp      : real;
      begin
         tmp    := sin((real(ph)+0.5)/1024.0*C_TWO_PI);
         sgn    := tmp;
         tmp    := log(abs(tmp))/log(0.5);
         logsin := integer(round(tmp*256.0));

         tmp := real(logsin+1)/256.0 + real(tl)/8.0;
         exp := floor(tmp);
         tmp := tmp - exp;

         tmp := 0.5**tmp;
         tmp := round(tmp*2048.0)/2048.0;
         tmp := tmp * 0.5**exp;
         if sgn < 0.0 then
            tmp := -tmp;
         end if;

         res := tmp / 8.0;

         if res > 0.0 then
            return integer(floor(res*65536.0));
         else
            return (65536+integer(ceil(res*65536.0))) mod 65536;
         end if;
         return 0;
      end function operator;

      variable phase_inc_v   : integer;
      variable phase_v       : integer;
      variable phase_prev_v  : integer;
      variable phase_prev2_v : integer;
      variable phase_prev3_v : integer;
      variable ph_m1_v       : integer;
      variable ph_m2_v       : integer;
      variable ph_c1_v       : integer;
      variable ph_c2_v       : integer;
      variable out_m1_v      : integer;
      variable out_m2_v      : integer;
      variable out_c1_v      : integer;
      variable out_c2_v      : integer;
      variable out_v         : integer;
      variable sum_v         : integer;

   begin
      phase_inc_v   := calc_phase_inc(config);
      out_v         := 0;
      phase_v       := (phase_inc_v * step) / 1024;
      phase_prev_v  := (phase_inc_v * (step-1)) / 1024;
      phase_prev2_v := (phase_inc_v * (step-2)) / 1024;
      phase_prev3_v := (phase_inc_v * (step-3)) / 1024;

      -- Handle feedback (M1 only).
      sum_v := 0;
      if step>0 then
         sum_v := config.out_m1_prev;
      end if;
      if step>1 then
         sum_v := config.out_m1_prev + config.out_m1_prev2;
      end if;
      if sum_v >= 32768 then
         sum_v := sum_v - 65536;
      end if;
      if sum_v >= 32768 then
         sum_v := sum_v - 65536;
      end if;
      case config.fb is
         when 0 => ph_m1_v := phase_v;
         when 1 => ph_m1_v := phase_v + sum_v/512;
                   if sum_v < 0 and sum_v mod 512 /= 0 then ph_m1_v := ph_m1_v - 1; end if;
         when 2 => ph_m1_v := phase_v + sum_v/256;
                   if sum_v < 0 and sum_v mod 256 /= 0 then ph_m1_v := ph_m1_v - 1; end if;
         when 3 => ph_m1_v := phase_v + sum_v/128;
                   if sum_v < 0 and sum_v mod 128 /= 0 then ph_m1_v := ph_m1_v - 1; end if;
         when 4 => ph_m1_v := phase_v + sum_v/64;
                   if sum_v < 0 and sum_v mod  64 /= 0 then ph_m1_v := ph_m1_v - 1; end if;
         when 5 => ph_m1_v := phase_v + sum_v/32;
                   if sum_v < 0 and sum_v mod  32 /= 0 then ph_m1_v := ph_m1_v - 1; end if;
         when 6 => ph_m1_v := phase_v + sum_v/16;
                   if sum_v < 0 and sum_v mod  16 /= 0 then ph_m1_v := ph_m1_v - 1; end if;
         when 7 => ph_m1_v := phase_v + sum_v/8;
                   if sum_v < 0 and sum_v mod   8 /= 0 then ph_m1_v := ph_m1_v - 1; end if;
         when others => ph_m1_v := phase_v;
      end case;
      out_m1_v := operator(ph_m1_v, config.oper_m1.tl);

      case config.mode is
         when 0 => -- C2(M2(C1(M1)))
            ph_c1_v     := phase_prev2_v;
            if step > 2 then
               ph_c1_v  := ph_c1_v + config.out_m1_prev3/2;
            end if;
            out_c1_v    := operator(ph_c1_v, config.oper_c1.tl);

            ph_m2_v     := phase_prev_v;
            if step > 1 then
               ph_m2_v  := ph_m2_v + out_c1_v/2;
            end if;
            out_m2_v    := operator(ph_m2_v, config.oper_m2.tl);

            ph_c2_v     := phase_prev_v;
            if step > 0 then
               ph_c2_v  := ph_c2_v + out_m2_v/2;
            end if;
            out_c2_v    := operator(ph_c2_v, config.oper_c2.tl);

            out_v := out_c2_v;
            if step = 0 then
               out_v := 0;
            end if;

         when 1 => -- C2(M2(C1+M1))
            ph_c1_v     := phase_prev2_v;
            out_c1_v    := operator(ph_c1_v, config.oper_c1.tl);

            ph_m2_v     := phase_prev_v;
            if step > 1 then
               ph_m2_v  := ph_m2_v + (config.out_m1_prev2 + out_c1_v)/2;
            end if;
            out_m2_v    := operator(ph_m2_v, config.oper_m2.tl);

            ph_c2_v     := phase_prev_v;
            if step > 0 then
               ph_c2_v  := ph_c2_v + out_m2_v/2;
            end if;
            out_c2_v    := operator(ph_c2_v, config.oper_c2.tl);

            out_v := out_c2_v;
            if step = 0 then
               out_v := 0;
            end if;

         when 2 => -- C2(M2(C1)+M1)
            ph_c1_v     := phase_prev2_v;
            out_c1_v    := operator(ph_c1_v, config.oper_c1.tl);

            ph_m2_v     := phase_prev_v;
            if step > 1 then
               ph_m2_v  := ph_m2_v + out_c1_v/2;
            end if;
            out_m2_v    := operator(ph_m2_v, config.oper_m2.tl);

            ph_c2_v     := phase_prev_v;
            if step > 0 then
               ph_c2_v  := phase_prev_v + config.out_m1_prev/2;
            end if;
            if step > 0 then
               ph_c2_v  := phase_prev_v + (out_m2_v + config.out_m1_prev)/2;
            end if;
            out_c2_v    := operator(ph_c2_v, config.oper_c2.tl);

            out_v := out_c2_v;
            if step = 0 then
               out_v := 0;
            end if;

         when 3 => -- C2(M2+C1(M1))
            ph_m2_v     := phase_prev_v;
            out_m2_v    := operator(ph_m2_v, config.oper_m2.tl);

            ph_c1_v     := phase_prev2_v;
            if step > 2 then
               ph_c1_v  := ph_c1_v + config.out_m1_prev3/2;
            end if;
            out_c1_v    := operator(ph_c1_v, config.oper_c1.tl);

            ph_c2_v     := phase_prev_v;
            if step > 0 then
               ph_c2_v  := phase_prev_v + out_m2_v/2;
            end if;
            if step > 1 then
               ph_c2_v  := phase_prev_v + (out_m2_v + out_c1_v)/2;
            end if;
            out_c2_v    := operator(ph_c2_v, config.oper_c2.tl);

            out_v := out_c2_v;
            if step = 0 then
               out_v := 0;
            end if;

         when 4 => -- C2(M2)+C1(M1)
            ph_m2_v     := phase_prev_v;
            out_m2_v    := operator(ph_m2_v, config.oper_m2.tl);

            ph_c1_v     := phase_prev_v;
            if step > 1 then
               ph_c1_v  := ph_c1_v + config.out_m1_prev2 / 2;
            end if;
            out_c1_v    := operator(ph_c1_v, config.oper_c1.tl);

            ph_c2_v     := phase_prev_v;
            if step > 0 then
               ph_c2_v  := ph_c2_v + out_m2_v / 2;
            end if;
            out_c2_v    := operator(ph_c2_v, config.oper_c2.tl);

            out_v := (out_c1_v + out_c2_v) mod 65536;
            if step = 0 then
               out_v := 0;
            end if;

         when 5 => -- C2(M1)+M2(M1)+C1(M1)
            ph_m2_v     := phase_prev_v;
            if step > 2 then
               ph_m2_v  := ph_m2_v + config.out_m1_prev3 / 2;
            end if;
            out_m2_v    := operator(ph_m2_v, config.oper_m2.tl);

            ph_c1_v     := phase_prev_v;
            if step > 1 then
               ph_c1_v  := ph_c1_v + config.out_m1_prev2 / 2;
            end if;
            out_c1_v    := operator(ph_c1_v, config.oper_c1.tl);

            ph_c2_v     := phase_prev_v;
            if step > 0 then
               ph_c2_v  := ph_c2_v + config.out_m1_prev / 2;
            end if;
            out_c2_v    := operator(ph_c2_v, config.oper_c2.tl);

            out_v := (out_m2_v + out_c1_v + out_c2_v) mod 65536;
            if step = 0 then
               out_v := 0;
            end if;

         when 6 => -- C2+M2+C1(M1)
            ph_m2_v    := phase_prev_v;
            out_m2_v   := operator(ph_m2_v, config.oper_m2.tl);

            ph_c1_v    := phase_prev_v;
            if step>1 then
               ph_c1_v := ph_c1_v + config.out_m1_prev2/2;
            end if;
            out_c1_v   := operator(ph_c1_v, config.oper_c1.tl);

            ph_c2_v    := phase_prev_v;
            out_c2_v   := operator(ph_c2_v, config.oper_c2.tl);

            out_v := (out_m2_v + out_c1_v + out_c2_v) mod 65536;
            if step = 0 then
               out_v := 0;
            end if;

         when 7 => -- C2+M2+C1+M1
            ph_m2_v  := phase_prev_v;
            out_m2_v := operator(ph_m2_v, config.oper_m2.tl);

            ph_c1_v  := phase_prev_v;
            out_c1_v := operator(ph_c1_v, config.oper_c1.tl);

            ph_c2_v  := phase_prev_v;
            out_c2_v := operator(ph_c2_v, config.oper_c2.tl);

            out_v := (out_m1_v + out_m2_v + out_c1_v + out_c2_v) mod 65536;
            if step = 0 then
               out_v := out_m1_v;
            end if;

         when others => null;
      end case;

--      report "phase_v="      & string_ph(phase_v)
--         & ", out_m1_prev="  & string_out(config.out_m1_prev)
--         & ", out_m1_prev2=" & string_out(config.out_m1_prev2)
--         & ", ph_m1_v="      & string_ph(ph_m1_v)
--         & ", out_m1_v="     & string_out(out_m1_v)
--         & ", ph_m2_v="      & string_ph(ph_m2_v)
--         & ", out_m2_v="     & string_out(out_m2_v)
--         & ", ph_c1_v="      & string_ph(ph_c1_v)
--         & ", out_c1_v="     & string_out(out_c1_v)
--         & ", ph_c2_v="      & string_ph(ph_c2_v)
--         & ", out_c2_v="     & string_out(out_c2_v)
--         & ", out_v="        & string_out(out_v);

      -- Update state information.
      config.ph_m1_prev3  := config.ph_m1_prev2;
      config.ph_m1_prev2  := config.ph_m1_prev;
      config.ph_m1_prev   := ph_m1_v;
      config.out_m1_prev3 := config.out_m1_prev2;
      config.out_m1_prev2 := config.out_m1_prev;
      config.out_m1_prev  := out_m1_v;

      expected := (out_v + 16#8000#) mod 65536;
   end procedure ym2151_calcExpectedWaveform;

   -- This function approximately models the peculiar way the YM2151 implements
   -- the envelope generation.
   function ym2151_calcSteps(rate : integer; base : integer) return integer is
      variable rate_cap : integer;
      variable steps : integer;
   begin
      rate_cap := rate;
      if rate_cap >= 56 then
         rate_cap := 56;
      end if;
      steps := integer(real(base)*0.5**real(rate_cap/4));
      case (rate_cap mod 4) is
         when 0 => null;
         when 1 => steps := (steps*4)/5;
         when 2 => steps := (steps*4)/6;
         when 3 => steps := (steps*4)/7;
      end case;
      return steps;
   end function ym2151_calcSteps;

   function ym2151_calcExpectedEnvelope(config        : config_t;
                                        release_level : integer) return ym2151_envelope_t is

      -- These constants are read from the documentation.
      constant C_CLOCK_HZ              : integer := 3579545;
      constant C_ATTACK_TIME_MS_RATE_4 : real :=   7973.43;
      constant C_DECAY_TIME_MS_RATE_4  : real := 110209.71;

      constant C_ATTACK_STEPS_RATE_4 : integer :=
         integer(real(C_CLOCK_HZ)/64.0*C_ATTACK_TIME_MS_RATE_4/1000.0);
      constant C_DECAY_STEPS_RATE_4  : integer := 
         integer(real(C_CLOCK_HZ)/64.0*C_DECAY_TIME_MS_RATE_4/1000.0);

      variable rate : integer;
      variable res  : ym2151_envelope_t;

   begin
      rate := config.oper_m1.ar*2+config.kc/32; -- attenuation level from 1023 to 0. 
      res.attack_time := ym2151_calcSteps(rate-4, C_ATTACK_STEPS_RATE_4);
      if rate >= 63 then
         res.attack_time := 0;
      end if;

      res.sustain_level := config.oper_m1.sl*32;

      rate := config.oper_m1.dr*2+config.kc/32; -- attenuation level from 0 to sustain.
      res.decay_time := (ym2151_calcSteps(rate-4, C_DECAY_STEPS_RATE_4)*res.sustain_level)/1024;

      rate := config.oper_m1.sr*2+config.kc/32; -- attenuation level from sustain to release.
      res.sustain_time := (ym2151_calcSteps(rate-4, C_DECAY_STEPS_RATE_4)*(release_level-res.sustain_level))/1024;

      rate := config.oper_m1.rr*4+2+config.kc/32; -- attenuation level from release to 1023.
      res.release_time := (ym2151_calcSteps(rate-4, C_DECAY_STEPS_RATE_4)*(1023-release_level))/1024;

--      report "attack_time="   & integer'image(res.attack_time)
--         & ", decay_time="    & integer'image(res.decay_time)
--         & ", sustain_level=" & integer'image(res.sustain_level)
--         & ", sustain_time="  & integer'image(res.sustain_time)
--         & ", release_level=" & integer'image(release_level)
--         & ", release_time="  & integer'image(res.release_time);
      return res;
   end function ym2151_calcExpectedEnvelope;

end package body ym2151_model_pkg;

