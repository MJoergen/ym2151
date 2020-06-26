-- Author:  Michael Jørgensen
-- License: Public domain; do with it what you like :-)
-- Project: YM2151 implementation
--
-- Description: This module is the top level for the YM2151.
--
-- The input clock frequency should nominally be 3.579545 MHz.
-- The output is an unsigned value representing a fractional output between
-- logical 0 and logical 1 and is updated at a rate of 55.9 kHz.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

entity ym2151 is
   port (
      clk_i        : in  std_logic;
      rst_i        : in  std_logic;
      -- Configuration interface
      cfg_valid_i  : in  std_logic;
      cfg_ready_o  : out std_logic;
      cfg_addr_i   : in  std_logic_vector(7 downto 0);
      cfg_data_i   : in  std_logic_vector(7 downto 0);
      -- Debug output
      deb_atten0_o : out std_logic_vector(9 downto 0);
      -- Waveform output
      wav_o        : out std_logic_vector(15 downto 0)
   );
end entity ym2151;

architecture synthesis of ym2151 is

   -- Internal Clock and Reset
   signal clk_int_r       : std_logic := '0';
   signal rst_int_r       : std_logic := '1';

   -- Output from Configurator
   signal slot_s          : std_logic_vector(4 downto 0);
   signal keyon_s         : std_logic;
   signal key_code_s      : std_logic_vector(6 downto 0);
   signal key_fraction_s  : std_logic_vector(5 downto 0);
   signal total_level_s   : std_logic_vector(6 downto 0);
   signal attack_rate_s   : std_logic_vector(4 downto 0);
   signal key_scale_s     : std_logic_vector(1 downto 0);
   signal decay_rate_s    : std_logic_vector(4 downto 0);
   signal sustain_rate_s  : std_logic_vector(4 downto 0);
   signal sustain_level_s : std_logic_vector(3 downto 0);
   signal release_rate_s  : std_logic_vector(3 downto 0);

   -- Output from Envelope Generator
   signal atten_II_s      : std_logic_vector(9 downto 0);

   -- Output from Phase Generator
   signal phase_II_s      : std_logic_vector(9 downto 0);

   -- Output from Operator
   signal sin_V_s         : std_logic_vector(13 downto 0);

   signal slot_V_s        : std_logic_vector(4 downto 0);

   signal wav_s           : std_logic_vector(15 downto 0);
   constant C_OFFSET      : std_logic_vector(15 downto 0) := X"8000";

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
         cfg_clk_i       => clk_i,
         cfg_rst_i       => rst_i,
         cfg_valid_i     => cfg_valid_i,
         cfg_ready_o     => cfg_ready_o,
         cfg_addr_i      => cfg_addr_i,
         cfg_data_i      => cfg_data_i,
         clk_int_i       => clk_int_r,
         slot_o          => slot_s,
         keyon_o         => keyon_s,
         key_code_o      => key_code_s,
         key_fraction_o  => key_fraction_s,
         total_level_o   => total_level_s,
         attack_rate_o   => attack_rate_s,
         key_scale_o     => key_scale_s,
         decay_rate_o    => decay_rate_s,
         sustain_rate_o  => sustain_rate_s,
         sustain_level_o => sustain_level_s,
         release_rate_o  => release_rate_s
      ); -- i_configurator


   -----------------------------------------------------------------------------
   -- Instantiate Envelope Generator
   -----------------------------------------------------------------------------

   i_envelope_generator : entity work.envelope_generator
      port map (
         clk_i           => clk_int_r,
         rst_i           => rst_int_r,
         key_code_i      => key_code_s,
         key_scale_i     => key_scale_s,
         keyon_i         => keyon_s,
         total_level_i   => total_level_s,
         attack_rate_i   => attack_rate_s,
         decay_rate_i    => decay_rate_s,
         sustain_rate_i  => sustain_rate_s,
         sustain_level_i => sustain_level_s,
         release_rate_i  => release_rate_s,
         atten_II_o      => atten_II_s
      ); -- i_envelope_generator


   -----------------------------------------------------------------------------
   -- Instantiate Phase Generator
   -----------------------------------------------------------------------------

   i_phase_generator : entity work.phase_generator
      port map (
         clk_i          => clk_int_r,
         rst_i          => rst_int_r,
         key_code_i     => key_code_s,
         key_fraction_i => key_fraction_s,
         phase_II_o     => phase_II_s
      ); -- i_phase_generator


   -----------------------------------------------------------------------------
   -- Calculate sin(phase).
   -----------------------------------------------------------------------------

   i_operator : entity work.operator
      port map (
         clk_i     => clk_int_r,
         atten_i   => atten_II_s,
         phase_i   => phase_II_s,
         sin_III_o => sin_V_s
      ); -- i_operator


   -----------------------------------------------------------------------------
   -- Accumulate results from all slots.
   -----------------------------------------------------------------------------

   slot_V_s <= slot_s - 5;   -- Adjust for latency.

   i_accumulator : entity work.accumulator
      port map (
         clk_i   => clk_int_r,
         rst_i   => rst_int_r,
         slot_i  => slot_V_s,
         value_i => sin_V_s,
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

   -- Debug
   p_debug : process (clk_i)
   begin
      if rising_edge(clk_i) then
         if slot_s = 2 then
            deb_atten0_o <= atten_II_s;
         end if;
         if rst_i = '1' then
            deb_atten0_o <= (others => '1');
         end if;
      end if;
   end process p_debug;

end architecture synthesis;

