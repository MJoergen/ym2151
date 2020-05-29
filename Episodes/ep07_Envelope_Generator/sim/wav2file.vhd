-- Author:  Michael Jørgensen
-- License: Public domain; do with it what you like :-)
-- Project: YM2151 implementation
--
-- Description: This module writes the generated output to a WAV file.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;
use std.textio.all;

entity wav2file is
   generic (
      G_FILE_NAME : string
   );
   port (
      clk_i    : in  std_logic;
      rst_i    : in  std_logic;
      active_i : in  std_logic;
      wav_i    : in  std_logic_vector(15 downto 0)
   );
end entity wav2file;

architecture simulation of wav2file is

   -- 6-bit counter wraps every 64 clock cycles.
   signal cnt : std_logic_vector(5 downto 0) := (others => '0');

begin

   p_output : process

      type CHAR_FILE_TYPE is file of character;
      file output_file : CHAR_FILE_TYPE;

      -- Helper function:
      -- Write a 2-byte value to the file in little-endian format.
      procedure write_16_bits
      (
         file data_file : CHAR_FILE_TYPE;
         data : std_logic_vector(15 downto 0)
      ) is
      begin
         write(data_file, character'val(to_integer(data(7 downto 0))));
         write(data_file, character'val(to_integer(data(15 downto 8))));
      end procedure write_16_bits;

   begin

      -- Copy output to file
      report "Opening output file";
      file_open(output_file, G_FILE_NAME, WRITE_MODE);

      -- Write WAV header
      -- See this link for a description of the file header:
      -- http://soundfile.sapp.org/doc/WaveFormat/
      write_16_bits(output_file, X"4952");   -- "RIFF"
      write_16_bits(output_file, X"4646");
      write_16_bits(output_file, X"0024");   -- 0x7FFF0024
      write_16_bits(output_file, X"7FFF");
      write_16_bits(output_file, X"4157");   -- "WAVE"
      write_16_bits(output_file, X"4556");

      write_16_bits(output_file, X"6d66");   -- "fmt "
      write_16_bits(output_file, X"2074");
      write_16_bits(output_file, X"0010");   -- 16
      write_16_bits(output_file, X"0000");
      write_16_bits(output_file, X"0001");   -- 1 = linear quantization
      write_16_bits(output_file, X"0001");   -- 1 = mono
      write_16_bits(output_file, X"DA7A");   -- sample rate = 55930
      write_16_bits(output_file, X"0000");
      write_16_bits(output_file, X"B4F4");   -- byte rate = 111860
      write_16_bits(output_file, X"0001");
      write_16_bits(output_file, X"0002");   -- 2 bytes per sample
      write_16_bits(output_file, X"0010");   -- 16 bits

      write_16_bits(output_file, X"6164");   -- "data"
      write_16_bits(output_file, X"6174");
      write_16_bits(output_file, X"0000");   -- 0x7FFF0000
      write_16_bits(output_file, X"7FFF");

      out_loop : while active_i loop
         cnt <= cnt + 1;
         wait until clk_i = '1';

         -- Only write every 64 clock cycles.
         if cnt = 0 then
            -- Subtract 0.5 to convert from the range 0-1 to +/- 0.5.
            -- This converts from unsigned to signed.
            write_16_bits(output_file, wav_i xor X"8000");
            flush(output_file);
         end if;
      end loop out_loop;

      report "Closing output file";
      file_close(output_file);

      wait;
   end process p_output;

end simulation;

