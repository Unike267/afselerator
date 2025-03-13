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

entity RAM is
  generic (
    RAM_WIDTH      : natural; -- RAM_WIDTH = RAM data width
    RAM_DEPTH      : natural  -- RAM_DEPTH = Log2 of number of elements that the RAM has; Number of RAM elements has to be a power of two.
  );
  port (
    CLK   : in  std_logic;                              -- Clock
    ADDR  : in  std_logic_vector(RAM_DEPTH-1 downto 0); -- RAM address
    STB   : in  std_logic;                              -- RAM strobe signal
    WE    : in  std_logic;                              -- RAM write  signal
    DIN   : in  std_logic_vector(RAM_WIDTH-1 downto 0); -- RAM input  data
    DOUT  : out std_logic_vector(RAM_WIDTH-1 downto 0)  -- RAM output data
  );
end RAM;

architecture RAM_RTL of RAM is

  signal RAM_8  : t_MEM8 (0 to ( 2**RAM_DEPTH)-1);
  signal RAM_16 : t_MEM16(0 to ( 2**RAM_DEPTH)-1);
  signal RAM_32 : t_MEM32(0 to ( 2**RAM_DEPTH)-1);

begin

  RAM_WIDTH_8:
  if (RAM_WIDTH = 8) generate
  RAM_8_ACCESS:
    process(CLK)
    begin
      if rising_edge(CLK) then 
        if(STB='1') then
          if(WE='1') then
            RAM_8(to_integer(unsigned(ADDR(RAM_DEPTH-1 downto 0)))) <=  DIN;
          end if;
          DOUT <=   RAM_8(to_integer(unsigned(ADDR(RAM_DEPTH-1 downto 0))));
        end if;
      end if;
    end process RAM_8_ACCESS;
  end generate;

  RAM_WIDTH_16:
  if (RAM_WIDTH = 16) generate
  RAM_16_ACCESS:
    process(CLK)
    begin
      if rising_edge(CLK) then 
        if(STB='1') then
          if(WE='1') then
            RAM_16(to_integer(unsigned(ADDR(RAM_DEPTH-1 downto 0)))) <= DIN;
          end if;
          DOUT <=  RAM_16(to_integer(unsigned(ADDR(RAM_DEPTH-1 downto 0))));
        end if;
      end if;
    end process RAM_16_ACCESS;
  end generate;

  RAM_WIDTH_32:
  if (RAM_WIDTH = 32) generate
  RAM_32_ACCESS:
    process(CLK)
    begin
      if rising_edge(CLK) then 
        if(STB='1') then
          if(WE='1') then
            RAM_32(to_integer(unsigned(ADDR(RAM_DEPTH-1 downto 0)))) <= DIN;
          end if;
          DOUT <=  RAM_32(to_integer(unsigned(ADDR(RAM_DEPTH-1 downto 0))));
        end if;
      end if;
    end process RAM_32_ACCESS;
  end generate;

end RAM_RTL;
