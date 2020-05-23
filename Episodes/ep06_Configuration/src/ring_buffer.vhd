-- Author:  Michael Jørgensen
-- License: Public domain; do with it what you like :-)
-- Project: YM2151 implementation
--
-- Description:
-- This is a generic implementation of a ring buffer / pipeline.  The input is
-- delayed a fixed number of clock cycles before being avaiable on the output.
--
-- If the output is fed back into the input, then we have a ring buffer.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

entity ring_buffer is
   generic (
      G_WIDTH  : integer;
      G_STAGES : integer
   );
   port (
      clk_i  : in  std_logic;
      data_i : in  std_logic_vector(G_WIDTH-1 downto 0);
      data_o : out std_logic_vector(G_WIDTH-1 downto 0)
   );
end entity ring_buffer;

architecture synthesis of ring_buffer is

   type BUFFER_t is array (0 to G_STAGES-1) of std_logic_vector(G_WIDTH-1 downto 0);
   signal buffer_r : BUFFER_t := (others => (others => '0'));

begin

   -- Main pipeline.
   gen_stage : for i in 0 to G_STAGES-2 generate
      p_buffer : process (clk_i)
      begin
         if rising_edge(clk_i) then
            buffer_r(i+1) <= buffer_r(i);
         end if;
      end process p_buffer;
   end generate gen_stage;

   -- First stage in pipeline: process input.
   p_input : process (clk_i)
   begin
      if rising_edge(clk_i) then
         buffer_r(0) <= data_i;
      end if;
   end process p_input;

   -- Copy output from final stage of pipeline.
   data_o <= buffer_r(G_STAGES-1);

end architecture synthesis;

