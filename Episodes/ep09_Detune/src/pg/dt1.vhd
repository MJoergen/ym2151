-- Author:  Michael Jørgensen
-- License: Public domain; do with it what you like :-)
-- Project: YM2151 implementation
--
-- Description: This module calculates the frequency adjustment due
-- to the DT1 parameter.
--
-- From the documentation we have the following table:
--   DT1 0  1  2  3
-- 0:0   0  0  1  2
-- 0:1   0  0  1  2
-- 0:2   0  0  1  2
-- 0:3   0  0  1  2
-- 1:0   0  1  2  2
-- 1:1   0  1  2  3
-- 1:2   0  1  2  3
-- 1:3   0  1  2  3
-- 2:0   0  1  2  4
-- 2:1   0  1  3  4
-- 2:2   0  1  3  4
-- 2:3   0  1  3  5
-- 3:0   0  2  4  5
-- 3:1   0  2  4  6
-- 3:2   0  2  4  6
-- 3:3   0  2  5  7
-- 4:0   0  2  5  8
-- 4:1   0  3  6  8
-- 4:2   0  3  6  9
-- 4:3   0  3  7 10
-- 5:0   0  4  8 11
-- 5:1   0  4  8 12
-- 5:2   0  4  9 13
-- 5:3   0  5 10 14
-- 6:0   0  5 11 16
-- 6:1   0  6 12 17
-- 6:2   0  6 13 19
-- 6:3   0  7 14 20
-- 7:0   0  8 16 22
-- 7:1   0  8 16 22
-- 7:2   0  8 16 22
-- 7:3   0  8 16 22


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

entity dt1 is
   port (
      key_code_i : in  std_logic_vector(6 downto 0);
      dt1_i      : in  std_logic_vector(2 downto 0);
      delta_o    : out std_logic_vector(19 downto 0)
   );
end entity dt1;

architecture synthesis of dt1 is

   type table_t is array (0 to 31+12) of integer range 0 to 31;

   constant C_DT_TABLE : table_t := (
       0,  0,  0,  0,
       1,  1,  1,  1,
       1,  1,  1,  1,
       2,  2,  2,  2,
       2,  3,  3,  3,
       4,  4,  4,  5,
       5,  6,  6,  7,
       8,  8,  9, 10,
      11, 12, 13, 14,
      16, 17, 19, 20,
      22, 22, 22, 22);

   signal delta_s        : std_logic_vector(4 downto 0);
   signal delta_max_s    : std_logic_vector(4 downto 0);
   signal delta_capped_s : std_logic_vector(4 downto 0);

begin

   p_delta : process (all)
   begin
      case to_integer(dt1_i(1 downto 0)) is
         when 1      => delta_s <= to_stdlogicvector(C_DT_TABLE(to_integer(key_code_i(6 downto 2))),5);
                        delta_max_s <= "01000";
         when 2      => delta_s <= to_stdlogicvector(C_DT_TABLE(to_integer(key_code_i(6 downto 2)) + 8),5);
                        delta_max_s <= "10000";
         when 3      => delta_s <= to_stdlogicvector(C_DT_TABLE(to_integer(key_code_i(6 downto 2)) + 12),5);
                        delta_max_s <= "10110";
         when others => delta_s <= (others => '0');
                        delta_max_s <= (others => '0');
      end case;
   end process p_delta;

   delta_capped_s <= delta_s when delta_s < delta_max_s else delta_max_s;

   delta_o <= ("000000000000000" & delta_capped_s) when dt1_i(2) = '0' else
              (("111111111111111" & not delta_capped_s) + 1);

end architecture synthesis;

