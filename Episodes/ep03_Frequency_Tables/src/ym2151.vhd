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
      clk_i : in  std_logic;
      rst_i : in  std_logic;
      -- Waveform output
      wav_o : out std_logic_vector(15 downto 0)
   );
end entity ym2151;

architecture synthesis of ym2151 is

   -- Internal Clock and Reset
   signal clk_int_r      : std_logic := '0';
   signal rst_int_r      : std_logic := '1';

   -- Slot Index
   signal slot_r         : std_logic_vector(4 downto 0);
   signal slot_II_s      : std_logic_vector(4 downto 0);

   signal key_code_s     : std_logic_vector(6 downto 0);
   signal key_fraction_s : std_logic_vector(5 downto 0);

   signal phase_inc_II_s : std_logic_vector(19 downto 0);
   signal phase_II_r     : std_logic_vector(19 downto 0);

   -- Output from Operator
   signal sin_V_s        : std_logic_vector(13 downto 0);

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
   -- Circulate through all slots
   -----------------------------------------------------------------------------

   p_slot : process (clk_int_r)
   begin
      if rising_edge(clk_int_r) then
         slot_r <= slot_r + 1;

         if rst_int_r = '1' then
            slot_r  <= (others => '0');
         end if;
      end if;
   end process p_slot;

   -- Adjust for latency.
   slot_II_s <= slot_r - 2;


   -----------------------------------------------------------------------------
   -- Select key code for the various slots.
   -- This selects the key A4, with frequency 440 Hz.
   -----------------------------------------------------------------------------

   key_code_s     <= "1001010"       when slot_r = 0 else (others => '0');
   key_fraction_s <= (others => '0') when slot_r = 0 else (others => '0');


   -----------------------------------------------------------------------------
   -- Calculate frequency for current key.
   -----------------------------------------------------------------------------

   i_calc_freq : entity work.calc_freq
      port map (
         clk_i          => clk_int_r,
         key_code_i     => key_code_s,
         key_fraction_i => key_fraction_s,
         phase_inc_II_o => phase_inc_II_s
      ); -- i_calc_freq


   -----------------------------------------------------------------------------
   -- Update phase.
   -----------------------------------------------------------------------------

   p_phase : process (clk_int_r)
   begin
      if rising_edge(clk_int_r) then
         -- Only update phase when in first slot
         if slot_II_s = 0 then
            phase_II_r <= phase_II_r + phase_inc_II_s;
         end if;

         if rst_int_r = '1' then
            phase_II_r <= (others => '0');
         end if;
      end if;
   end process p_phase;


   -----------------------------------------------------------------------------
   -- Calculate sin(phase).
   -----------------------------------------------------------------------------

   i_operator : entity work.operator
      port map (
         clk_i     => clk_int_r,
         phase_i   => phase_II_r(19 downto 10),
         sin_III_o => sin_V_s
      ); -- i_operator


   -----------------------------------------------------------------------------
   -- Generate output.
   -- Convert from signed to unsigned.
   -- Add register to reduce clock skew.
   -----------------------------------------------------------------------------

   p_wav : process (clk_i)
   begin
      if rising_edge(clk_i) then
         wav_o <= (sin_V_s & "00") xor C_OFFSET;
      end if;
   end process p_wav;

end architecture synthesis;

