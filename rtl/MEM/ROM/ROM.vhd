-- Author:
--   Unai Sainz-Estebanez
-- Email:
--  <unai.sainze@ehu.eus>
--
-- Licensed under the GNU General Public License v3.0;
-- You may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     https://www.gnu.org/licenses/gpl-3.0.html

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library MEM;
use MEM.MEM_package.all;

entity ROM is
  generic (
    ROM_WIDTH     : natural; -- ROM_WIDTH = ROM data width
    ROM_DEPTH     : natural; -- ROM_DEPTH = Log2 of number of elements that the ROM has; Number of ROM elements has to be a power of two.
    ROM_LOAD_FILE : string   -- ROM_LOAD_FILE = PATH of the LOAD FILE
  );
  port (
    CLK   : in  std_logic;                              -- Clock
    ADDR  : in  std_logic_vector(ROM_DEPTH-1 downto 0); -- ROM address
    STB   : in  std_logic;                              -- ROM strobe signal
    DOUT  : out std_logic_vector(ROM_WIDTH-1 downto 0)  -- ROM output data
  );
end ROM;

architecture ROM_RTL of ROM is

  constant ROM_LOAD_FILE_8  : string := ROM_LOAD_FILE &  "string_8.hex"; 
  constant ROM_LOAD_FILE_16 : string := ROM_LOAD_FILE & "string_16.hex"; 
  constant ROM_LOAD_FILE_32 : string := ROM_LOAD_FILE & "string_32.hex"; 

  constant ROM_8  : t_MEM8 (0 to ( 2**ROM_DEPTH)-1) := MEM8_INIT_HEX (ROM_LOAD_FILE_8,  2**ROM_DEPTH);
  constant ROM_16 : t_MEM16(0 to ( 2**ROM_DEPTH)-1) := MEM16_INIT_HEX(ROM_LOAD_FILE_16, 2**ROM_DEPTH);
  constant ROM_32 : t_MEM32(0 to ( 2**ROM_DEPTH)-1) := MEM32_INIT_HEX(ROM_LOAD_FILE_32, 2**ROM_DEPTH);

begin

  ROM_WIDTH_8:
  if (ROM_WIDTH = 8) generate
  ROM_8_ACCESS:
    process(CLK)
    begin
      if rising_edge(CLK) then 
        if(STB='1') then
          DOUT <= ROM_8(to_integer(unsigned(ADDR(ROM_DEPTH-1 downto 0))));
        end if;
      end if;
    end process ROM_8_ACCESS;
  end generate;

  ROM_WIDTH_16:
  if (ROM_WIDTH = 16) generate
  ROM_16_ACCESS:
    process(CLK)
    begin
      if rising_edge(CLK) then 
        if(STB='1') then
          DOUT <= ROM_16(to_integer(unsigned(ADDR(ROM_DEPTH-1 downto 0))));
        end if;
      end if;
    end process ROM_16_ACCESS;
  end generate;

  ROM_WIDTH_32:
  if (ROM_WIDTH = 32) generate
  ROM_32_ACCESS:
    process(CLK)
    begin
      if rising_edge(CLK) then 
        if(STB='1') then
          DOUT <= ROM_32(to_integer(unsigned(ADDR(ROM_DEPTH-1 downto 0))));
        end if;
      end if;
    end process ROM_32_ACCESS;
  end generate;

end ROM_RTL;
