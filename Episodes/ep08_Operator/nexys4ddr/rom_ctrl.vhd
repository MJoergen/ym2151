library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;
use std.textio.all;

entity rom_ctrl is
   generic (
      G_INIT_FILE : string
   );
   port (
      clk_i  : in  std_logic;
      addr_i : in  std_logic_vector(11 downto 0);
      data_o : out std_logic_vector(15 downto 0)
   );
end rom_ctrl;

architecture synthesis of rom_ctrl is

   type mem_t is array (0 to 2**12-1) of std_logic_vector(15 downto 0);

   -- This reads the ROM contents from a text file
   impure function InitRomFromFile(RomFileName : in string) return mem_t is
      FILE RomFile : text;
      variable RomFileLine : line;
      variable ROM : mem_t := (others => (others => '0'));
   begin
      file_open(RomFile, RomFileName, read_mode);
      report RomFileName;
      for i in mem_t'range loop
         readline (RomFile, RomFileLine);
         hread (RomFileLine, ROM(i));
         if endfile(RomFile) then
            return ROM;
         end if;
      end loop;
      return ROM;
   end function;

   -- Initialize memory contents
   signal mem_r : mem_t := InitRomFromFile(G_INIT_FILE);

begin

   p_read : process (clk_i)
   begin
      if rising_edge(clk_i) then
         data_o <= mem_r(to_integer(addr_i));
      end if;
   end process p_read;

end synthesis;

