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

   function ym2151_calcExpectedEnvelope(config        : config_t;
                                        release_level : integer) return ym2151_envelope_t;

end package ym2151_model_pkg;

package body ym2151_model_pkg is

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

