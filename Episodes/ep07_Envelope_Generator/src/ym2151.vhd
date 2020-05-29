-- Author:  Michael Jørgensen
-- License: Public domain; do with it what you like :-)
-- Project: YM2151 implementation
--
-- Description: This module is the top level for the YM2151.
--
-- The input clock frequency should nominally be 3.579545 MHz.
-- The output is an unsigned value representing a fractional
-- output between logical 0 and logical 1.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

entity ym2151 is
   port (
      clk_i       : in  std_logic;
      rst_i       : in  std_logic;
      -- Configuration interface
      cfg_valid_i : in  std_logic;
      cfg_ready_o : out std_logic;
      cfg_addr_i  : in  std_logic_vector(7 downto 0);
      cfg_data_i  : in  std_logic_vector(7 downto 0);
      -- Waveform output
      wav_o       : out std_logic_vector(15 downto 0)
   );
end entity ym2151;

architecture synthesis of ym2151 is

   -- Internal Clock and Reset
   signal clk_int_r      : std_logic := '0';
   signal rst_int_r      : std_logic := '1';

   -- Output from Configurator
   signal slot_s         : std_logic_vector(4 downto 0);
   signal total_level_s  : std_logic_vector(6 downto 0);
   signal key_code_s     : std_logic_vector(6 downto 0);
   signal key_fraction_s : std_logic_vector(5 downto 0);

   -- Output from Phase Generator
   signal phase_III_s    : std_logic_vector(9 downto 0);

   -- Output from Envelope Generator
   signal atten_III_s    : std_logic_vector(9 downto 0);

   -- Output from Calc Sine
   signal sin_VI_s       : std_logic_vector(13 downto 0);

   signal slot_VI_s      : std_logic_vector(4 downto 0);

   signal wav_s          : std_logic_vector(15 downto 0);
   constant C_OFFSET     : std_logic_vector(15 downto 0) := X"8000";   

begin

   -----------------------------------------------------------------------------
   -- Generate internal clock
   -----------------------------------------------------------------------------

   p_clk_int : process (clk_i)
   begin
      if rising_edge(clk_i) then
         clk_int_r <= not clk_int_r;
      end if;
   end process p_clk_int;


   -----------------------------------------------------------------------------
   -- Generate internal reset
   -----------------------------------------------------------------------------

   p_rst_int : process (clk_int_r)
   begin
      if rising_edge(clk_int_r) then
         rst_int_r <= rst_i;
      end if;
   end process p_rst_int;


   -----------------------------------------------------------------------------
   -- Instantiate Configurator
   -----------------------------------------------------------------------------

   i_configurator : entity work.configurator
      port map (
         cfg_clk_i      => clk_i,
         cfg_rst_i      => rst_i,
         cfg_valid_i    => cfg_valid_i,
         cfg_ready_o    => cfg_ready_o,
         cfg_addr_i     => cfg_addr_i,
         cfg_data_i     => cfg_data_i,
         clk_int_i      => clk_int_r,
         slot_o         => slot_s,
         total_level_o  => total_level_s,
         key_code_o     => key_code_s,
         key_fraction_o => key_fraction_s
      ); -- i_configurator


   -----------------------------------------------------------------------------
   -- Instantiate Phase Generator
   -----------------------------------------------------------------------------

   i_phase_generator : entity work.phase_generator
      port map (
         clk_i          => clk_int_r,
         rst_i          => rst_int_r,
         key_code_i     => key_code_s,
         key_fraction_i => key_fraction_s,
         phase_III_o    => phase_III_s
      ); -- i_phase_generator


   -----------------------------------------------------------------------------
   -- Instantiate Envelope Generator
   -----------------------------------------------------------------------------

   i_envelope_generator : entity work.envelope_generator
      port map (
         clk_i         => clk_int_r,
         rst_i         => rst_int_r,
         total_level_i => total_level_s,
         atten_III_o   => atten_III_s
      ); -- i_envelope_generator


   -----------------------------------------------------------------------------
   -- Calculate sin(phase).
   -----------------------------------------------------------------------------

   i_calc_sine : entity work.calc_sine
      port map (
         clk_i   => clk_int_r,
         atten_i => atten_III_s,
         phase_i => phase_III_s,
         sin_o   => sin_VI_s
      ); -- i_calc_sine


   -----------------------------------------------------------------------------
   -- Accumulate results from all slots.
   -----------------------------------------------------------------------------

   slot_VI_s <= slot_s - 6;   -- Adjust for latency.

   i_accumulator : entity work.accumulator
      port map (
         clk_i   => clk_int_r,
         rst_i   => rst_int_r,
         slot_i  => slot_VI_s,
         value_i => sin_VI_s,
         wav_o   => wav_s
      ); -- i_accumulator


   -----------------------------------------------------------------------------
   -- Convert from signed to unsigned.
   -- Add register to reduce clock skew.
   -----------------------------------------------------------------------------

   p_wav : process (clk_i)
   begin
      if rising_edge(clk_i) then
         wav_o <= wav_s xor C_OFFSET;
      end if;
   end process p_wav;

end architecture synthesis;

