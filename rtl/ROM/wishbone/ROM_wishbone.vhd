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

entity ROM_wishbone is
  generic (
    ROM_WIDTH     : natural; -- ROM_WIDTH = ROM data width
    ROM_DEPTH     : natural; -- ROM_DEPTH = Log2 of number of elements that the ROM has; Number of ROM elements has to be a power of two.
    ROM_LOAD_FILE : string   -- ROM_LOAD_FILE = PATH of the LOAD FILE
  );
port (
    CLK_i   : in  std_logic;                     -- Clock
    RSTN_i  : in  std_ulogic;                    -- Low-active async reset
    ADDR_i  : in  std_logic_vector(31 downto 0); -- Wishbone address input
    --DAT_i   : in  std_logic_vector(31 downto 0); -- In the context of a ROM wishbone input data is not used
    DAT_o   : out std_logic_vector(31 downto 0); -- Wishbone data output 
    WE_i    : in  std_logic;                     -- Wishbone write enable signal is not used
    SEL_i   : in  std_logic_vector(3 downto 0);  -- Wishbone select input signal
    STB_i   : in  std_logic;                     -- Wishbone strobe input signal
    ACK_o   : out std_logic;                     -- Wishbone acknowledge output signal
    CYC_i   : in  std_logic;                     -- Wishbone cycle input signal
    ERR_o   : out std_logic;                     -- Wishbone error output signal
    STALL_o : out std_logic                      -- Wishbone pipeline stall output signal
    );
end ROM_wishbone;

architecture ROM_wishbone_RTL of ROM_wishbone is

-- Define ROM constants:
  constant base_addr   : std_logic_vector(31 downto 0) := x"90000000";
  constant max_addr    : std_logic_vector(31 downto 0) := x"9" & std_logic_vector(to_unsigned(2**ROM_DEPTH-1,26)) & "00";

-- Define ROM signals:
  signal addr          : std_logic_vector(ROM_DEPTH-1 downto 0) := (others => '0');
  signal dout          : std_logic_vector(ROM_WIDTH-1 downto 0) := (others => '0');
  signal stb           : std_logic                              :=            '0' ;
  signal wb_read       : boolean                                :=          false ;
  signal err           : boolean                                :=          false ;
  signal output_window : boolean                                :=          false ;

begin

  ROM_0 : entity MEM.ROM
                         generic map(
                                     ROM_WIDTH     => ROM_WIDTH,
                                     ROM_DEPTH     => ROM_DEPTH,
                                     ROM_LOAD_FILE => ROM_LOAD_FILE
                                    )
                         port map   (
                                     CLK  => CLK_i,
                                     ADDR => addr,
                                     STB  => stb,
                                     DOUT => dout
                                    );

-- The ROM will be memory mapped to NEORV32 at the base address defined at 0x90000000 
-- The equivalent address increment is: One address in ROM for every 4 addresses in NEORV32 memory. 
-- Thus, if the ROM has for example 1024 (FROM 000 to 3FF) items 
-- It wil be memory mapped to NEORV32 from address 0x90000000 to address 0x90000FFC
-- So the ROM has 26 addressable bits in the mapped memory, the addresses: 1001_XXXX_XXXX_XXXX_XXXX_XXXX_XXXX_XX00

-- Manage read signal
  -- Activated when a read request is made by wishbone master
  wb_read <= ?? (STB_i and CYC_i and not(WE_i));

-- Manage error signal:
  -- Error when reading attempt occurs and address is misaligned or out of range.
  err <= (wb_read) and (ADDR_i(1 downto 0) /= "00" or ADDR_i < base_addr or ADDR_i > max_addr);

  with err           select
  ERR_o <= '1' when   true,
           '0' when others;

-- Manage strobe signal
  stb <= STB_i;

-- Manage stall signal
  STALL_o <= '0';

-- Manage addresses
  addr <= ADDR_i(2+(ROM_DEPTH-1) downto 2);

-- Manage output signal

  ROM_OUTPUT_8:
  if   ROM_WIDTH = 8             generate
  with output_window             select
       DAT_o <= x"000000" & dout when   true,
       (others => '0')           when others;
  end generate;

  ROM_OUTPUT_16:
  if   ROM_WIDTH = 16            generate
  with output_window             select
       DAT_o <= x"0000"   & dout when   true,
       (others => '0')           when others;
  end generate;

  ROM_OUTPUT_32:
  if (ROM_WIDTH = 32)  generate
  with output_window   select
       DAT_o <= dout   when   true,
       (others => '0') when others;
  end generate;

-- Manage output window signal

  Manage_output_window: process (CLK_i) 
  begin
    if RSTN_i        = '0'     then
      output_window <= false;
    elsif rising_edge( CLK_i)  then
      if wb_read and not(err)  then
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
      if wb_read and not(err) then
        ACK_o <= '1';
      else
        ACK_o <= '0';
      end if;
    end if;
  end process   Manage_ack_signal;
                
end ROM_wishbone_RTL;
