-- Author:  Michael Jørgensen
-- License: Public domain; do with it what you like :-)
-- Project: YM2151 implementation
--
-- Description: This module controls the generation of the ADSR envelope. The
-- state transitions are driven by the keyon_i signal, and the time spent in
-- each state is controlled by the remaining input signals.  The output is the
-- attenuation level in units of 1/64'th powers of 0.5, i.e. a unit of
-- 6/64 dB = 93.75 mdB.
--
-- Latency: 3 clock cycles.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

entity envelope_generator is
   port (
      clk_i           : in  std_logic;
      rst_i           : in  std_logic;
      keyon_i         : in  std_logic;
      key_code_i      : in  std_logic_vector(6 downto 0);
      key_scale_i     : in  std_logic_vector(1 downto 0);
      total_level_i   : in  std_logic_vector(6 downto 0);   -- Units of 0.75 dB.
      attack_rate_i   : in  std_logic_vector(4 downto 0);
      decay_rate_i    : in  std_logic_vector(4 downto 0);
      sustain_rate_i  : in  std_logic_vector(4 downto 0);
      sustain_level_i : in  std_logic_vector(3 downto 0);   -- Units of 3 dB.
      release_rate_i  : in  std_logic_vector(3 downto 0);
      atten_III_o     : out std_logic_vector(9 downto 0)
   );
end entity envelope_generator;

architecture synthesis of envelope_generator is

   signal last_state_s             : std_logic_vector(1 downto 0);
   signal last_atten_s             : std_logic_vector(9 downto 0);

   signal sustain_level_adjusted_s : std_logic_vector(4 downto 0);
   signal rate_s                   : std_logic_vector(5 downto 0);
   signal lsb_s                    : std_logic;
   signal bit_s                    : std_logic;
   signal last_lsb_s               : std_logic;
   signal shifts_s                 : integer range 0 to 2;
   signal update_s                 : std_logic;

   signal state_s                  : std_logic_vector(1 downto 0);
   signal atten_s                  : std_logic_vector(9 downto 0);
   signal atten_tl_s               : std_logic_vector(9 downto 0);
   signal atten_final_s            : std_logic_vector(9 downto 0);

   constant C_ATTACK_ST            : std_logic_vector(1 downto 0) := "00";
   constant C_DECAY_ST             : std_logic_vector(1 downto 0) := "01";
   constant C_SUSTAIN_ST           : std_logic_vector(1 downto 0) := "10";
   constant C_RELEASE_ST           : std_logic_vector(1 downto 0) := "11";

begin

   -----------------------------------------------------------------------------
   -- Remember last state.
   -----------------------------------------------------------------------------

   i_ring_buffer_state : entity work.ring_buffer
      generic map (
         G_WIDTH    => 2,
         G_STAGES   => 32,
         G_INIT_VAL => to_integer(C_RELEASE_ST)
      )
      port map (
         clk_i  => clk_i,
         data_i => state_s,
         data_o => last_state_s
      ); -- i_ring_buffer_state


   -----------------------------------------------------------------------------
   -- Remember last attenuation.
   -----------------------------------------------------------------------------

   i_ring_buffer_atten : entity work.ring_buffer
      generic map (
         G_WIDTH    => 10,
         G_STAGES   => 32,
         G_INIT_VAL => 1023   -- Maximum attenuation
      )
      port map (
         clk_i  => clk_i,
         data_i => atten_s,
         data_o => last_atten_s
      ); -- i_ring_buffer_atten


   -----------------------------------------------------------------------------
   -- Remember last LSB of counter slice.
   -----------------------------------------------------------------------------

   i_ring_buffer_lsb : entity work.ring_buffer
      generic map (
         G_WIDTH  => 1,
         G_STAGES => 32
      )
      port map (
         clk_i     => clk_i,
         data_i(0) => lsb_s,
         data_o(0) => last_lsb_s
      ); -- i_ring_buffer_lsb


   -----------------------------------------------------------------------------
   -- Adjust sustain level (convert 45 dB to 48 dB).
   -----------------------------------------------------------------------------

   sustain_level_adjusted_s <= "10000" when sustain_level_i = "1111" else
                               '0' & sustain_level_i;


   -----------------------------------------------------------------------------
   -- Determine state transitions based on last value of attenuation and
   -- any external events.
   -----------------------------------------------------------------------------

   i_eg_state : entity work.eg_state
      port map (
         last_atten_i => last_atten_s,
         last_state_i => last_state_s,
         keyon_i      => keyon_i,
         sustain_i    => sustain_level_adjusted_s,
         state_o      => state_s
      ); -- i_eg_state


   -----------------------------------------------------------------------------
   -- Calculate internal attenuation rate.
   -----------------------------------------------------------------------------

   i_eg_rate : entity work.eg_rate
      port map (
         key_scale_i    => key_scale_i,
         key_code_i     => key_code_i,
         attack_rate_i  => attack_rate_i,
         decay_rate_i   => decay_rate_i,
         sustain_rate_i => sustain_rate_i,
         release_rate_i => release_rate_i,
         state_i        => state_s,
         rate_o         => rate_s
      ); -- i_eg_rate


   -----------------------------------------------------------------------------
   -- Calculate attenuation timing information.
   -----------------------------------------------------------------------------

   i_eg_timing : entity work.eg_timing
      port map (
         clk_i    => clk_i,
         rst_i    => rst_i,
         rate_i   => rate_s,
         lsb_o    => lsb_s,
         bit_o    => bit_s,
         shifts_o => shifts_s
      ); -- i_eg_timing


   -----------------------------------------------------------------------------
   -- Calculate new envelope attenuation.
   -----------------------------------------------------------------------------

   update_s <= (last_lsb_s xor lsb_s) and bit_s;

   i_eg_attenuation : entity work.eg_attenuation
      port map (
         last_atten_i => last_atten_s,
         rate_i       => rate_s,
         state_i      => state_s,
         update_i     => update_s,
         shifts_i     => shifts_s,
         atten_o      => atten_s
      ); -- i_eg_attenuation


   -----------------------------------------------------------------------------
   -- Calculate final attenuation.
   -----------------------------------------------------------------------------

   atten_tl_s <= total_level_i & "000";

   i_saturated_sum_unsigned : entity work.saturated_sum_unsigned
      generic map (
         G_WIDTH => 10
      )
      port map (
         arg1_i => atten_s,
         arg2_i => atten_tl_s,
         sum_o  => atten_final_s
      ); -- i_saturated_sum_unsigned


   -----------------------------------------------------------------------------
   -- 3 clock cycle delay
   -----------------------------------------------------------------------------

   i_ring_buffer_output : entity work.ring_buffer
      generic map (
         G_WIDTH    => 10,
         G_STAGES   => 3
      )
      port map (
         clk_i  => clk_i,
         data_i => atten_final_s,
         data_o => atten_III_o 
      ); -- i_ring_buffer_output

end architecture synthesis;

