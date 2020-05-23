library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

-- This is the top level module of the Nexys4DDR. The ports on this entity are
-- mapped directly to pins on the FPGA.

entity nexys4ddr is
   port (
      sys_clk_i  : in    std_logic;    -- 100 MHz
      sys_rstn_i : in    std_logic;
      aud_pwm_o  : inout std_logic;
      aud_sd_o   : out   std_logic
   );
end nexys4ddr;

architecture synthesis of nexys4ddr is

   signal ym2151_clk_s : std_logic;
   signal ym2151_rst_s : std_logic; 
   signal ym2151_wav_s : std_logic_vector(15 downto 0);

   signal pwm_clk_s    : std_logic;
   signal pwm_aud_s    : std_logic;

begin

   -----------------------------------------------------------------------------
   -- Instantiate Clock and Reset generation.
   -----------------------------------------------------------------------------

   i_clk_rst : entity work.clk_rst
      port map (
         sys_clk_i    => sys_clk_i,      -- 100 MHz
         sys_rstn_i   => sys_rstn_i,
         ym2151_clk_o => ym2151_clk_s,   --   3.579545 MHz
         ym2151_rst_o => ym2151_rst_s,
         pwm_clk_o    => pwm_clk_s       -- 229 MHz
      ); -- i_clk_rst


   -----------------------------------------------------------------------------
   -- Instantiate YM2151 module.
   -----------------------------------------------------------------------------

   i_ym2151 : entity work.ym2151
      port map (
         clk_i => ym2151_clk_s,
         rst_i => ym2151_rst_s,
         wav_o => ym2151_wav_s
      ); -- i_ym2151


   -----------------------------------------------------------------------------
   -- Instantiate PWM module.
   -- The implied Clock Domain Crossing can be safely ignore because the YM2151
   -- period is a multiple of the PWM period, and hence the ym2151_wav_s signal
   -- is synchronuous to pwm_clk_s too.
   -----------------------------------------------------------------------------

   i_pwm : entity work.pwm
      port map (
         clk_i => pwm_clk_s,
         wav_i => ym2151_wav_s,
         pwm_o => pwm_aud_s
      ); -- i_pwm


   -----------------------------------------------------------------------------
   -- Drive output signals
   -----------------------------------------------------------------------------

   aud_sd_o  <= '1';
   aud_pwm_o <= '0' when pwm_aud_s = '0' else 'Z';

end architecture synthesis;

