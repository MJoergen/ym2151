-- Author:  Michael Jørgensen
-- License: Public domain; do with it what you like :-)
-- Project: YM2151 implementation
--
-- Description: This module implements the phase adjustments determined by the
-- eight different connection modes.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

entity phase_mod is
   port (
      clk_i            : in  std_logic;
      val_XVI_i        : in  std_logic_vector(13 downto 0); 
      op_i             : in  std_logic_vector(1 downto 0); -- Current operator number
      con_i            : in  std_logic_vector(2 downto 0); -- Connection mode
      feedback_i       : in  std_logic_vector(2 downto 0); -- M1 feedback
      phase_mod_VIII_o : out std_logic_vector(9 downto 0)
   );
end entity phase_mod;

architecture synthesis of phase_mod is

   constant C_OP_M1      : std_logic_vector(1 downto 0) := "00";
   constant C_OP_M2      : std_logic_vector(1 downto 0) := "01";
   constant C_OP_C1      : std_logic_vector(1 downto 0) := "10";
   constant C_OP_C2      : std_logic_vector(1 downto 0) := "11";

   signal op_XVI_s       : std_logic_vector(1 downto 0);

   signal m1_s           : std_logic_vector(13 downto 0);
   signal last_m1_s      : std_logic_vector(13 downto 0);
   signal m1_prev_s      : std_logic_vector(13 downto 0);
   signal last_m1_prev_s : std_logic_vector(13 downto 0);
   signal c1_s           : std_logic_vector(13 downto 0);
   signal last_c1_s      : std_logic_vector(13 downto 0);

   signal x_s            : std_logic_vector(13 downto 0);
   signal y_s            : std_logic_vector(13 downto 0);

   signal xs_s           : std_logic_vector(14 downto 0);
   signal ys_s           : std_logic_vector(14 downto 0);

   signal sum_s          : std_logic_vector(14 downto 0);

   signal phase_mod_s    : std_logic_vector(9 downto 0);

begin

   -- 16 clock cycles is exactly two operators.
   op_XVI_s <= op_i - 2;

   m1_s <= val_XVI_i when op_XVI_s = C_OP_M1 else last_m1_s;

   i_ring_buffer_m1 : entity work.ring_buffer
      generic map (
         G_WIDTH  => 14,
         G_STAGES => 8
      )
      port map (
         clk_i  => clk_i,
         data_i => m1_s,
         data_o => last_m1_s
      ); -- i_ring_buffer_m1


   m1_prev_s <= last_m1_s when op_XVI_s = C_OP_M1 else last_m1_prev_s;

   i_ring_buffer_m1_prev : entity work.ring_buffer
      generic map (
         G_WIDTH  => 14,
         G_STAGES => 8
      )
      port map (
         clk_i  => clk_i,
         data_i => m1_prev_s,
         data_o => last_m1_prev_s
      ); -- i_ring_buffer_m1_prev


   c1_s <= val_XVI_i when op_XVI_s = C_OP_C1 else last_c1_s;

   i_ring_buffer_c1 : entity work.ring_buffer
      generic map (
         G_WIDTH  => 14,
         G_STAGES => 8
      )
      port map (
         clk_i  => clk_i,
         data_i => c1_s,
         data_o => last_c1_s
      ); -- i_ring_buffer_c1



   p_xy : process (all)
   begin
      x_s <= (others => '0');
      y_s <= (others => '0');

      case op_i is
         when C_OP_M1 => x_s <= last_m1_prev_s; y_s <= last_m1_s;

         when C_OP_M2 => 
            case to_integer(con_i) is
               when 0 => x_s <= last_c1_s;
               when 1 => x_s <= last_c1_s; y_s <= last_m1_s;
               when 2 => x_s <= last_c1_s;
               when 3 => null;
               when 4 => null;
               when 5 => x_s <= last_m1_prev_s;
               when 6 => null;
               when 7 => null;
               when others => null;
            end case;

         when C_OP_C1 =>
            case to_integer(con_i) is
               when 0 => y_s <= last_m1_s;
               when 1 => null;
               when 2 => null;
               when 3 => y_s <= last_m1_s;
               when 4 => y_s <= last_m1_s;
               when 5 => y_s <= last_m1_s;
               when 6 => y_s <= last_m1_s;
               when 7 => null;
               when others => null;
            end case;

         when C_OP_C2 =>
            case to_integer(con_i) is
               when 0 =>                   y_s <= val_XVI_i;
               when 1 =>                   y_s <= val_XVI_i;
               when 2 => x_s <= val_XVI_i; y_s <= last_m1_s;
               when 3 => x_s <= last_c1_s; y_s <= val_XVI_i;
               when 4 =>                   y_s <= val_XVI_i;
               when 5 =>                   y_s <= last_m1_s;
               when 6 => null;
               when 7 => null;
               when others => null;
            end case;

         when others => null;
      end case;
   end process p_xy;


   -- Sign extend
   xs_s <= x_s(13) & x_s;
   ys_s <= y_s(13) & y_s;


   sum_s <= xs_s + ys_s;   -- Carry is discarded

   p_phase_mod : process (all)
   begin
      -- Default value; for M2, C1, and C2.
      phase_mod_s <= sum_s(10 downto 1);

      if op_i = C_OP_M1 then
         -- Prepare for sign extension (only feedback levels 1 - 4).
         phase_mod_s <= (others => sum_s(14));
         case to_integer(feedback_i) is
            when 0 => phase_mod_s <= (others => '0');
            when 1 => phase_mod_s(5 downto 0) <= sum_s(14 downto 9);
            when 2 => phase_mod_s(6 downto 0) <= sum_s(14 downto 8);
            when 3 => phase_mod_s(7 downto 0) <= sum_s(14 downto 7);
            when 4 => phase_mod_s(8 downto 0) <= sum_s(14 downto 6);
            when 5 => phase_mod_s <= sum_s(14 downto 5);
            when 6 => phase_mod_s <= sum_s(13 downto 4);
            when 7 => phase_mod_s <= sum_s(12 downto 3);
            when others => null;
         end case;
      end if;
   end process p_phase_mod;


   i_ring_buffer : entity work.ring_buffer
      generic map (
         G_WIDTH  => 10,
         G_STAGES => 8
      )
      port map (
         clk_i  => clk_i,
         data_i => phase_mod_s,
         data_o => phase_mod_VIII_o
      ); -- i_ring_buffer

end architecture synthesis;

