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

   function calc_phase_inc(config : config_t) return integer;

end package ym2151_model_pkg;

package body ym2151_model_pkg is

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

end package body ym2151_model_pkg;

