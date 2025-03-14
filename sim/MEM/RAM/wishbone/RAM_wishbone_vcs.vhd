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
context ieee.ieee_std_context;

library MEM;
use MEM.MEM_package.all;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.vc_context;


entity RAM_wishbone_vcs is
  generic (
    bus_handle              : bus_master_t;
    strobe_high_probability : real range 0.0 to 1.0 := 1.0;
    RAM_WIDTH               : natural; -- RAM_WIDTH = RAM data width
    RAM_DEPTH               : natural  -- RAM_DEPTH = Log2 of number of elements that the RAM has; Number of RAM elements has to be a power of two.
  );
  port (
    CLK_i  : in  std_logic;  -- Clock
    RSTN_i : in  std_ulogic  -- Low-active async reset
  );
end entity;

architecture arch of RAM_wishbone_vcs is

  signal m_we    : std_logic                                                :=            '0' ;
  signal m_stb   : std_logic                                                :=            '0' ;
  signal m_ack   : std_logic                                                :=            '0' ;
  signal m_cyc   : std_logic                                                :=            '0' ;
  signal m_stall : std_logic                                                :=            '0' ;
  signal m_din   : std_logic_vector(data_length(bus_handle)    -1 downto 0) := (others => '0');
  signal m_dout  : std_logic_vector(data_length(bus_handle)    -1 downto 0) := (others => '0');
  signal m_adr   : std_logic_vector(address_length(bus_handle) -1 downto 0) := (others => '0');
  signal m_sel   : std_logic_vector((data_length(bus_handle)/8)-1 downto 0) := (others => '0');

begin


-- Wishbone verification component instantiation
  vunit_wishbone_master: 
  entity vunit_lib.wishbone_master
                                  generic map (
                                              bus_handle => bus_handle,
                                              strobe_high_probability => strobe_high_probability
                                              )
                                  port    map (
                                               clk   => CLK_i,
                                               adr   => m_adr,
                                               dat_i => m_din,
                                               dat_o => m_dout,
                                               sel   => m_sel,
                                               cyc   => m_cyc,
                                               stb   => m_stb,
                                               we    => m_we,
                                               stall => m_stall,
                                               ack   => m_ack
                                               );
-- RAM Wishbone instantiation
  RAM_wishbone_0 : 
  entity MEM.RAM_wishbone
                         generic map(
                                    RAM_WIDTH     => RAM_WIDTH,
                                    RAM_DEPTH     => RAM_DEPTH
                                    )
                         port    map(
                                    CLK_i         => CLK_i,
                                    RSTN_i        => RSTN_i,
                                    ADDR_i        => m_adr, 
                                    DAT_i         => m_dout, 
                                    DAT_o         => m_din, 
                                    WE_i          => m_we,   
                                    SEL_i         => m_sel,
                                    STB_i         => m_stb,
                                    ACK_o         => m_ack,
                                    CYC_i         => m_cyc,
                                    ERR_o         => open,
                                    STALL_o       => m_stall
                                    );
end architecture;
