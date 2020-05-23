-- Author:  Michael Jørgensen
-- License: Public domain; do with it what you like :-)
-- Project: YM2151 implementation
--
-- Description: The Envelope Generator is currently just a stub, in that it
-- just calculates the attenuation level (to be input to the calc_sine module)
-- from the total_level values (received from the configurator module). This
-- calculation is a simple shift by three bits.
--
-- Latency: 3 clock cycles.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

entity envelope_generator is
   port (
      clk_i         : in  std_logic;
      rst_i         : in  std_logic;
      total_level_i : in  std_logic_vector(6 downto 0);
      atten_III_o   : out std_logic_vector(9 downto 0)
   );
end entity envelope_generator;

architecture synthesis of envelope_generator is

   -- Attenuation
   signal atten_s : std_logic_vector(9 downto 0);

begin

   -- Calculate attenuation level.
   atten_s <= total_level_i & "000";


   -----------------------------------------------------------------------------
   -- Insert a delay of three clock cycles.
   -- This is necessary to have the same latency as the phase_generator module.
   -----------------------------------------------------------------------------

   i_ring_buffer : entity work.ring_buffer
      generic map (
         G_WIDTH  => 10,
         G_STAGES => 3
      )
      port map (
         clk_i  => clk_i,
         data_i => atten_s,
         data_o => atten_III_o
      ); -- i_ring_buffer

end architecture synthesis;

