-- Author:  Michael Jørgensen
-- License: Public domain; do with it what you like :-)
-- Project: YM2151 implementation
--
-- Description: This is the main Phase Generator in the design.  It takes as
-- input the configuration data, and (with a constant latency) outputs the
-- current phase. In other words, this module maintains 32 different phases as
-- internal state.  This corresponds to the 32 different output slots.
--
-- The design works as a pipeline, so at each clock cycle a new input is
-- received and some fixed number of clock cycles later the correct phase is
-- output.
--
-- Latency: 2 clock cycles.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

entity phase_generator is
   port (
      clk_i          : in  std_logic;
      rst_i          : in  std_logic;
      -- Configuration input
      key_code_i     : in  std_logic_vector(6 downto 0);
      key_fraction_i : in  std_logic_vector(5 downto 0);
      -- Phase output
      phase_II_o     : out std_logic_vector(9 downto 0)
   );
end entity phase_generator;

architecture synthesis of phase_generator is

   -- Output from calc_freq.
   signal phase_inc_II_s  : std_logic_vector(19 downto 0);

   -- Output from ring_buffer.
   signal last_phase_II_s : std_logic_vector(19 downto 0);

   -- Input to ring_buffer.
   signal phase_II_s      : std_logic_vector(19 downto 0);

begin

   -----------------------------------------------------------------------------
   -- Calculate frequency for current key.
   -----------------------------------------------------------------------------

   i_calc_freq : entity work.calc_freq
      port map (
         clk_i          => clk_i,
         key_code_i     => key_code_i,
         key_fraction_i => key_fraction_i,
         phase_inc_II_o => phase_inc_II_s
      ); -- i_calc_freq


   -----------------------------------------------------------------------------
   -- Calculate new phase.
   -----------------------------------------------------------------------------

   phase_II_s <= (others => '0') when rst_i = '1' else
                 last_phase_II_s + phase_inc_II_s;


   -----------------------------------------------------------------------------
   -- Store 32 states of phase, one for each slot.
   -----------------------------------------------------------------------------

   i_ring_buffer_phase : entity work.ring_buffer
      generic map (
         G_WIDTH  => 20,
         G_STAGES => 32
      )
      port map (
         clk_i  => clk_i,
         data_i => phase_II_s,
         data_o => last_phase_II_s
      ); -- i_ring_buffer_phase


   phase_II_o <= phase_II_s(19 downto 10);

end architecture synthesis;

