-- Author:  Michael Jørgensen
-- License: Public domain; do with it what you like :-)
-- Project: YM2151 Example Design
--
-- Description: This module contains the Clock and Reset generation.
-- The PWM module runs at 229.0 MHz, and the YM2151 clock is obtained
-- by dividing by 64 to give 3.578 MHz.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

library unisim;
use unisim.vcomponents.all;

entity clk_rst is
   port (
      sys_clk_i    : in  std_logic;   -- 100     MHz
      sys_rstn_i   : in  std_logic;
      ym2151_clk_o : out std_logic;   --   3.578 MHz
      ym2151_rst_o : out std_logic;
      pwm_clk_o    : out std_logic    -- 229     MHz
   );
end clk_rst;

architecture synthesis of clk_rst is
   -- Output clock buffering / unused connectors
   signal clkfbout_clk_wiz_0     : std_logic;
   signal clkfbout_buf_clk_wiz_0 : std_logic;
   signal pwm_clk_wiz_0          : std_logic;

   signal pwm_clk_s              : std_logic;
   signal pwm_cnt_r              : std_logic_vector(5 downto 0) := (others => '0');

   signal ym2151_clk_s           : std_logic;
   signal ym2151_rst_r           : std_logic_vector(35 downto 0) := (others => '1'); 

begin

   --------------------------------------
   -- Instantiation of the MMCM PRIMITIVE
   --------------------------------------

   i_mmcm_adv : MMCME2_ADV
      generic map (
         BANDWIDTH            => "OPTIMIZED",
         CLKOUT4_CASCADE      => FALSE,
         COMPENSATION         => "ZHOLD",
         STARTUP_WAIT         => FALSE,
         DIVCLK_DIVIDE        => 5,
         CLKFBOUT_MULT_F      => 57.250,
         CLKFBOUT_PHASE       => 0.000,
         CLKFBOUT_USE_FINE_PS => FALSE,
         CLKOUT0_DIVIDE_F     => 5.000,     -- @ 229 MHz
         CLKOUT0_PHASE        => 0.000,
         CLKOUT0_USE_FINE_PS  => FALSE,
         CLKIN1_PERIOD        => 10.0,
         REF_JITTER1          => 0.010
      )
      port map (
         -- Output clocks
         CLKFBOUT            => clkfbout_clk_wiz_0,
         CLKFBOUTB           => open,
         CLKOUT0             => pwm_clk_wiz_0,
         CLKOUT0B            => open,
         CLKOUT1             => open,
         CLKOUT1B            => open,
         CLKOUT2             => open,
         CLKOUT2B            => open,
         CLKOUT3             => open,
         CLKOUT3B            => open,
         CLKOUT4             => open,
         CLKOUT5             => open,
         CLKOUT6             => open,
         -- Input clock control
         CLKFBIN             => clkfbout_buf_clk_wiz_0,
         CLKIN1              => sys_clk_i,
         CLKIN2              => '0',
         -- Tied to always select the primary input clock
         CLKINSEL            => '1',
         -- Ports for dynamic reconfiguration
         DADDR               => (others => '0'),
         DCLK                => '0',
         DEN                 => '0',
         DI                  => (others => '0'),
         DO                  => open,
         DRDY                => open,
         DWE                 => '0',
         -- Ports for dynamic phase shift
         PSCLK               => '0',
         PSEN                => '0',
         PSINCDEC            => '0',
         PSDONE              => open,
         -- Other control and status signals
         LOCKED              => open,
         CLKINSTOPPED        => open,
         CLKFBSTOPPED        => open,
         PWRDWN              => '0',
         RST                 => '0'
      ); -- i_mmcm_adv


   -------------------------------------
   -- Output buffering
   -------------------------------------

   i_bufg_clkfb : BUFG
      port map (
         I => clkfbout_clk_wiz_0,
         O => clkfbout_buf_clk_wiz_0
      );

   i_bufg_pwm_clk : BUFG
      port map (
         I => pwm_clk_wiz_0,
         O => pwm_clk_s
      );

   p_pwm_cnt : process (pwm_clk_s)
   begin
      if rising_edge(pwm_clk_s) then
         pwm_cnt_r <= pwm_cnt_r + 1;
      end if;
   end process p_pwm_cnt;

   i_bufg_ym2151_clk : BUFG
      port map (
         I => pwm_cnt_r(5),
         O => ym2151_clk_s
      );


   ----------------------------------------------------------------
   -- Generate reset signal.
   ----------------------------------------------------------------

   p_ym2151_rst : process (ym2151_clk_s)
   begin
      if rising_edge(ym2151_clk_s) then
         ym2151_rst_r <= ym2151_rst_r(34 downto 0) & "0";  -- Shift left one bit
         if sys_rstn_i = '0' then
            ym2151_rst_r <= (others => '1');
         end if;
      end if;
   end process p_ym2151_rst;


   ----------------------------------------------------------------
   -- Drive output signals
   ----------------------------------------------------------------

   pwm_clk_o    <= pwm_clk_s;
   ym2151_clk_o <= ym2151_clk_s;
   ym2151_rst_o <= ym2151_rst_r(35);

end synthesis;

