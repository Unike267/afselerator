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
    ROM_WIDTH     : natural; -- ROM_WIDTH= ROM data width
    ROM_DEPTH     : natural; -- ROM_DEPTH = Log2 of number of elements that the ROM has; Number of ROM elements has to be a power of two.
    ROM_LOAD_FILE : string
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

-- Define ROM signals:
  signal addr          : std_logic_vector(ROM_DEPTH-1 downto 0) := (others => '0');
  signal dout          : std_logic_vector(ROM_WIDTH-1 downto 0) := (others => '0');
  signal stb           : std_logic                              :=            '0' ;
  signal stall         : std_logic                              :=            '0' ; 
  signal transfer_out  : std_logic                              :=            '0' ; 
  signal output_window : std_logic                              :=            '0' ; 

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

-- Manage error signal:
  ERR_o <= '0'; -- Tie to zero if not explicitly used

-- Manage strobe signal
  stb   <= STB_i;

-- If the ROM has for example 1024 items (FROM 000 to 3FF) it will be
-- memory mapped to NEORV32 from address 0x90000000 to address 0x900003FF 

-- Manage stall signal, when the memory is out of range it stalls
  stall   <= '0'  when ADDR_i >= x"90000000" and ADDR_i < x"90000400" else '1';
  STALL_o <= stall;

-- Manage addresses
  addr    <= ADDR_i(ROM_DEPTH-1 downto 0);

-- Manage the output transfer signal according to the criteria for the memory mapping 
  transfer_out <= (STB_i and CYC_i and not(WE_i)) when not(stall) else '0';

-- Manage output signal

  ROM_OUTPUT_8:
  if   ROM_WIDTH = 8             generate
  with output_window             select
       DAT_o <= x"000000" & dout when    '1',
       (others => '0')           when others;
  end generate;

  ROM_OUTPUT_16:
  if   ROM_WIDTH = 16            generate
  with output_window             select
       DAT_o <= x"0000"   & dout when    '1',
       (others => '0')           when others;
  end generate;

  ROM_OUTPUT_32:
  if (ROM_WIDTH = 32)  generate
  with output_window   select
       DAT_o <= dout   when    '1',
       (others => '0') when others;
  end generate;

-- Manage output window signal

  Manage_output_window: process (clk_i) 
  begin
    if RSTN_i = '0' then
      output_window   <= '0';
    elsif rising_edge(clk_i) then
      if transfer_out  = '1' then
        output_window <= '1';
      else
        output_window <= '0';
      end if;
    end if;
  end process;

-- Manage ack signal

  Manage_ack_signal: process (clk_i) 
  begin
    if RSTN_i  = '0' then
      ACK_o   <= '0';
    elsif rising_edge(clk_i) then
      if transfer_out then
        ACK_o <= '1';
      else
        ACK_o <= '0';
      end if;
    end if;
  end process;
                
end ROM_wishbone_RTL;
