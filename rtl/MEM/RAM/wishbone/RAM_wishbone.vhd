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

entity RAM_wishbone is
  generic (
    RAM_WIDTH     : natural; -- RAM_WIDTH = RAM data width
    RAM_DEPTH     : natural  -- RAM_DEPTH = Log2 of number of elements that the RAM has; Number of RAM elements has to be a power of two.
  );
port (
    CLK_i   : in  std_logic;                     -- Clock
    RSTN_i  : in  std_ulogic;                    -- Low-active async reset
    ADDR_i  : in  std_logic_vector(31 downto 0); -- Wishbone address input
    DAT_i   : in  std_logic_vector(31 downto 0); -- Wishbone data input
    DAT_o   : out std_logic_vector(31 downto 0); -- Wishbone data output 
    WE_i    : in  std_logic;                     -- Wishbone write enable signal 
    SEL_i   : in  std_logic_vector(3 downto 0);  -- Wishbone select input signal
    STB_i   : in  std_logic;                     -- Wishbone strobe input signal
    ACK_o   : out std_logic;                     -- Wishbone acknowledge output signal
    CYC_i   : in  std_logic;                     -- Wishbone cycle input signal
    ERR_o   : out std_logic;                     -- Wishbone error output signal
    STALL_o : out std_logic                      -- Wishbone pipeline stall output signal
    );
end RAM_wishbone;

architecture RAM_wishbone_RTL of RAM_wishbone is

-- Define RAM constants:
  constant base_addr   : std_logic_vector(31 downto 0) := x"A0000000";
  constant max_addr    : std_logic_vector(31 downto 0) := x"A" & std_logic_vector(to_unsigned(2**RAM_DEPTH-1,26)) & "00";

-- Define RAM signals:
  signal addr          : std_logic_vector(RAM_DEPTH-1 downto 0) := (others => '0');
  signal din           : std_logic_vector(RAM_WIDTH-1 downto 0) := (others => '0');
  signal dout          : std_logic_vector(RAM_WIDTH-1 downto 0) := (others => '0');
  signal stb           : std_logic                              :=            '0' ;
  signal we            : std_logic                              :=            '0' ;
  signal wb            : boolean                                :=          false ;
  signal err           : boolean                                :=          false ;
  signal output_window : boolean                                :=          false ;

begin

  RAM_0 : entity MEM.RAM
                         generic map(
                                     RAM_WIDTH     => RAM_WIDTH,
                                     RAM_DEPTH     => RAM_DEPTH
                                    )
                         port map   (
                                     CLK  => CLK_i,
                                     ADDR => addr,
                                     STB  => stb,
                                     WE   => we,
                                     DIN  => din,
                                     DOUT => dout
                                    );

-- The RAM will be memory mapped to NEORV32 at the base address defined at 0xA0000000 
-- The equivalent address increment is: One address in RAM for every 4 addresses in NEORV32 memory. 
-- Thus, if the RAM has for example 1024 (FROM 000 to 3FF) items 
-- It wil be memory mapped to NEORV32 from address 0xA0000000 to address 0xA0000FFC
-- So the RAM has 26 addressable bits in the mapped memory, the addresses: 1010_XXXX_XXXX_XXXX_XXXX_XXXX_XXXX_XX00

-- Manage wishbone signal
  -- Activated when a wishbone request is made by wishbone master
  wb <= ?? (STB_i and CYC_i);

-- Manage error signal:
  -- Error when reading/writing attempt occurs and address is misaligned or out of range.
  err <= (wb) and (ADDR_i(1 downto 0) /= "00" or ADDR_i < base_addr or ADDR_i > max_addr);

  ERR_o <= '1' when err else '0';

-- Manage strobe signal
  stb <= STB_i;

-- Manage stall signal
  STALL_o <= '0';

-- Manage addresses
  addr <= ADDR_i(2+(RAM_DEPTH-1) downto 2);

-- Manage input signal
  din <= DAT_I(RAM_WIDTH-1 downto 0) when (wb and not(err) and WE_i = '1') else (others => '0');

-- Manage write signal
  we <= '1' when (wb and not(err) and WE_i = '1') else '0';

-- Manage output signal

  RAM_OUTPUT_8:
  if   RAM_WIDTH =  8 generate
  DAT_o <= x"000000" & dout when output_window else (others => '0');
  end generate;

  RAM_OUTPUT_16:
  if   RAM_WIDTH = 16 generate
  DAT_o <= x"0000"   & dout when output_window else (others => '0');
  end generate;

  RAM_OUTPUT_32:
  if (RAM_WIDTH = 32) generate
  DAT_o <=             dout when output_window else (others => '0');
  end generate;

-- Manage output window signal

  Manage_output_window: process (CLK_i) 
  begin
    if RSTN_i        = '0'     then
      output_window <= false;
    elsif rising_edge( CLK_i)  then
      if wb and not(err) and WE_i='0' then
        output_window <=  true;
      else
        output_window <= false;
      end if;
    end if;
  end process Manage_output_window;

-- Manage ack signal

  Manage_ack_signal: process (CLK_i) 
  begin
    if RSTN_i  = '0'          then
      ACK_o   <= '0';
    elsif rising_edge( CLK_i) then
      if wb and not(err) then
        ACK_o <= '1';
      else
        ACK_o <= '0';
      end if;
    end if;
  end process   Manage_ack_signal;
                
end RAM_wishbone_RTL;
