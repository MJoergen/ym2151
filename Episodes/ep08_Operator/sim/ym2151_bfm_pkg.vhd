-- Author:  Michael Jørgensen
-- License: Public domain; do with it what you like :-)
-- Project: YM2151 implementation
--
-- Description: This module is a controller for the YM2151.
-- It is used during simulation as a Bus Functional Model.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

package ym2151_bfm_pkg is

   type ym2151_if_t is record
      cfg_valid : std_logic;
      cfg_ready : std_logic;
      cfg_addr  : std_logic_vector(7 downto 0);
      cfg_data  : std_logic_vector(7 downto 0);
      wav       : std_logic_vector(15 downto 0);
      atten0    : std_logic_vector(9 downto 0);
   end record ym2151_if_t;

   constant C_YM2151_IF_DEFAULT : ym2151_if_t := (
      cfg_valid => '0',
      cfg_ready => 'Z',
      cfg_addr  => (others => 'U'),
      cfg_data  => (others => 'U'),
      wav       => (others => 'Z'),
      atten0    => (others => 'Z')
   );

   -- Write to a single register.
   procedure ym2151_write(constant addr_i    : in    std_logic_vector(7 downto 0);
                          constant data_i    : in    std_logic_vector(7 downto 0);
                          signal   clk_i     : in    std_logic;
                          signal   ym2151_io : inout ym2151_if_t);

   type oper_t is record
      mul : integer;
      tl  : integer;
      ar  : integer;
      dr  : integer;
      sr  : integer;
      rr  : integer;
      sl  : integer;
   end record oper_t;

   constant C_OPER_DEFAULT : oper_t := (
      mul => 1,
      tl  => 127,
      ar  => 31,
      dr  => 0,
      sr  => 0,
      rr  => 15,
      sl  => 15
   );

   type config_t is record
      mode         : integer;
      fb           : integer;
      kc           : integer;
      kf           : integer;
      oper_m1      : oper_t;
      oper_m2      : oper_t;
      oper_c1      : oper_t;
      oper_c2      : oper_t;
      ph_m1_prev   : integer;
      ph_m1_prev2  : integer;
      ph_m1_prev3  : integer;
      out_m1_prev  : integer;
      out_m1_prev2 : integer;
      out_m1_prev3 : integer;
   end record config_t;

   constant C_CONFIG_DEFAULT : config_t := (
      mode         => 0,
      fb           => 0,
      kc           => 0,
      kf           => 0,
      oper_m1      => C_OPER_DEFAULT,
      oper_m2      => C_OPER_DEFAULT,
      oper_c1      => C_OPER_DEFAULT,
      oper_c2      => C_OPER_DEFAULT,
      ph_m1_prev   => 0,
      ph_m1_prev2  => 0,
      ph_m1_prev3  => 0,
      out_m1_prev  => 0,
      out_m1_prev2 => 0,
      out_m1_prev3 => 0
   );


   -- Store a complete configuration.
   procedure ym2151_write_config(constant config_i  : in    config_t;
                                 signal   clk_i     : in    std_logic;
                                 signal   ym2151_io : inout ym2151_if_t);

end package ym2151_bfm_pkg;

package body ym2151_bfm_pkg is

   procedure ym2151_write(constant addr_i    : in    std_logic_vector(7 downto 0);
                          constant data_i    : in    std_logic_vector(7 downto 0);
                          signal   clk_i     : in    std_logic;
                          signal   ym2151_io : inout ym2151_if_t) is
   begin
--      report "Writing: 0x" & to_hstring(addr_i) & " <= 0x" & to_hstring(data_i);
      ym2151_io.cfg_valid <= '1';
      ym2151_io.cfg_addr  <= addr_i;
      ym2151_io.cfg_data  <= data_i;
      wait until clk_i = '0';
      wait until clk_i = '1';
      while ym2151_io.cfg_ready = '0' loop
         wait until clk_i = '1';
      end loop;
      ym2151_io.cfg_valid <= '0';
      ym2151_io.cfg_addr  <= (others => 'U');
      ym2151_io.cfg_data  <= (others => 'U');
   end procedure ym2151_write;


   procedure ym2151_write_config(constant config_i  : in    config_t;
                                 signal   clk_i     : in    std_logic;
                                 signal   ym2151_io : inout ym2151_if_t) is

      procedure write(addr : std_logic_vector(7 downto 0);
                      data : integer) is
      begin
         ym2151_write(addr, to_stdlogicvector(data,8), clk_i, ym2151_io);
      end procedure write;

      procedure config_oper(idx  : integer;
                            oper : oper_t) is
      begin
         write(X"40" + idx*8, oper.mul);
         write(X"60" + idx*8, oper.tl);
         write(X"80" + idx*8, oper.ar);
         write(X"A0" + idx*8, oper.dr);
         write(X"C0" + idx*8, oper.sr);
         write(X"E0" + idx*8, oper.sl*16 + oper.rr);
      end procedure;

      constant C_OPER_M1 : integer := 0;
      constant C_OPER_M2 : integer := 1;
      constant C_OPER_C1 : integer := 2;
      constant C_OPER_C2 : integer := 3;

   begin
      write(X"20", 16#80# + config_i.fb*8 + config_i.mode);
      write(X"28", config_i.kc);
      write(X"30", config_i.kf*4);
      config_oper(C_OPER_M1, config_i.oper_m1);
      config_oper(C_OPER_M2, config_i.oper_m2);
      config_oper(C_OPER_C1, config_i.oper_c1);
      config_oper(C_OPER_C2, config_i.oper_c2);
      write(X"08", 16#78#);

      wait until clk_i = '1' and ym2151_io.cfg_ready = '1';
   end procedure ym2151_write_config;

end package body ym2151_bfm_pkg;

