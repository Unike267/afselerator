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

library neorv32;
use neorv32.neorv32_package.all;

entity neorv32_MEM_wishbone is
  generic (
    --          Generic defaults: |-----------------------|
    CLOCK_FREQUENCY   : natural := 100000000;               -- clock frequency of clk_i in Hz
    IMEM_SIZE         : natural := 8192;                    -- size of processor-internal instruction memory in bytes
    DMEM_SIZE         : natural := 8192;                    -- size of processor-internal data memory in bytes
    ROM_WIDTH         : natural := 8;                       -- ROM_WIDTH = ROM data width
    ROM_DEPTH         : natural := 10;                      -- ROM_DEPTH = Log2 of number of elements that the ROM has; Number of ROM elements has to be a power of two.
    ROM_LOAD_FILE     : string  := "../../data/ROM-sim/";   -- ROM_LOAD_FILE = PATH of the LOAD FILE
    RAM_WIDTH         : natural := 8;                       -- RAM_WIDTH = RAM data width
    RAM_DEPTH         : natural := 10                       -- RAM_DEPTH = Log2 of number of elements that the RAM has; Number of RAM elements has to be a power of two.
  );
  port (
    -- Global control --
    CLK_i       : in  std_ulogic; -- global clock, rising edge
    RSTN_i      : in  std_ulogic; -- global reset, low-active, async
    -- UART0 --
    UART0_txd_o : out std_ulogic; -- UART0 send data
    UART0_rxd_i : in  std_ulogic  -- UART0 receive data
  );
end entity;

architecture neorv32_MEM_wishbone_rtl of neorv32_MEM_wishbone is

--Declaration of constants
  constant s1_base_addr   : std_logic_vector(31 downto 0) := x"90000000";
  constant s1_max_addr    : std_logic_vector(31 downto 0) := x"9" & std_logic_vector(to_unsigned(2**ROM_DEPTH-1,26)) & "00";
  constant s2_base_addr   : std_logic_vector(31 downto 0) := x"A0000000";
  constant s2_max_addr    : std_logic_vector(31 downto 0) := x"A" & std_logic_vector(to_unsigned(2**RAM_DEPTH-1,26)) & "00";

-- Declaration of wishbone signals
  signal wb_m_we_o    : std_logic                      :=            '0' ;
  signal wb_m_stb_o   : std_logic                      :=            '0' ;
  signal wb_m_ack_i   : std_logic                      :=            '0' ;
  signal wb_m_cyc_o   : std_logic                      :=            '0' ;
  signal wb_m_err_i   : std_logic                      :=            '0' ;

  signal wb_s1_stb_i  : std_logic                      :=            '0' ;
  signal wb_s2_stb_i  : std_logic                      :=            '0' ;
  signal wb_s1_ack_o  : std_logic                      :=            '0' ;
  signal wb_s2_ack_o  : std_logic                      :=            '0' ;
  signal wb_s1_err_o  : std_logic                      :=            '0' ;
  signal wb_s2_err_o  : std_logic                      :=            '0' ;

  signal wb_m_adr_o   : std_logic_vector(31 downto 0)  := (others => '0');
  signal wb_m_dat_i   : std_logic_vector(31 downto 0)  := (others => '0');
  signal wb_m_dat_o   : std_logic_vector(31 downto 0)  := (others => '0');
  signal wb_m_sel_o   : std_logic_vector( 3 downto 0)  := (others => '0');

  signal wb_s1_dat_o  : std_logic_vector(31 downto 0)  := (others => '0');
  signal wb_s2_dat_o  : std_logic_vector(31 downto 0)  := (others => '0');

  signal wb_m_adr_o_u : std_ulogic_vector(31 downto 0) := (others => '0');
  signal wb_m_dat_i_u : std_ulogic_vector(31 downto 0) := (others => '0');
  signal wb_m_dat_o_u : std_ulogic_vector(31 downto 0) := (others => '0');
  signal wb_m_sel_o_u : std_ulogic_vector( 3 downto 0) := (others => '0');

-- Declaration of intermediate signals 
  -- ACMP = ADDRESS COMPARATOR 
  signal ACMP         : std_logic_vector(1 downto 0)   := (others => '0');

begin

-- ROM Wishbone instantiation
  ROM_wishbone_0 : 
  entity MEM.ROM_wishbone
                         generic map(
                                    ROM_WIDTH     => ROM_WIDTH,
                                    ROM_DEPTH     => ROM_DEPTH,
                                    ROM_LOAD_FILE => ROM_LOAD_FILE
                                    )
                         port    map(
                                    CLK_i         => CLK_i,
                                    RSTN_i        => RSTN_i,
                                    ADDR_i        => wb_m_adr_o, 
                                    DAT_o         => wb_s1_dat_o, 
                                    WE_i          => wb_m_we_o,   
                                    SEL_i         => wb_m_sel_o,
                                    STB_i         => wb_s1_stb_i,
                                    ACK_o         => wb_s1_ack_o,
                                    CYC_i         => wb_m_cyc_o,
                                    ERR_o         => wb_s1_err_o,
                                    STALL_o       => open
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
                                    ADDR_i        => wb_m_adr_o, 
                                    DAT_i         => wb_m_dat_o, 
                                    DAT_o         => wb_s2_dat_o, 
                                    WE_i          => wb_m_we_o,   
                                    SEL_i         => wb_m_sel_o,
                                    STB_i         => wb_s2_stb_i,
                                    ACK_o         => wb_s2_ack_o,
                                    CYC_i         => wb_m_cyc_o,
                                    ERR_o         => wb_s2_err_o,
                                    STALL_o       => open
                                    );

  -- The Core Of The Problem ----------------------------------------------------------------
  -- ----------------------------------------------------------------------------------------
  neorv32_top_inst:  
  entity neorv32.neorv32_top
                         generic map(
                                     -- General --
                                     CLOCK_FREQUENCY   => CLOCK_FREQUENCY, -- clock frequency of clk_i in Hz
                                     BOOT_MODE_SELECT  => 2,               -- boot configuration select (Implement IMEM as pre-initialized ROM)
                                     -- RISC-V CPU Extensions --
                                     RISCV_ISA_C       => true,            -- implement compressed extension?
                                     RISCV_ISA_M       => true,            -- implement mul/div extension?
                                     RISCV_ISA_Zicntr  => true,            -- implement base counters?
                                     -- Internal Instruction memory --
                                     IMEM_EN   => true,              -- implement processor-internal instruction memory
                                     IMEM_SIZE => IMEM_SIZE, -- size of processor-internal instruction memory in bytes
                                    -- Internal Data memory --
                                    DMEM_EN    => true,              -- implement processor-internal data memory
                                    DMEM_SIZE  => DMEM_SIZE, -- size of processor-internal data memory in bytes
                                    -- Processor peripherals --
                                    IO_CLINT_EN        => true,              -- implement machine system timer (MTIME)?
                                    IO_UART0_EN        => true,               -- implement primary universal asynchronous receiver/transmitter (UART0)?
                                    -- XBUS (WISHBONE) --
                                    XBUS_EN            => true,              -- implement XBUS interface?
                                    XBUS_TIMEOUT       => 4096,              -- cycles after a pending bus access auto-terminates (0 = disabled)
                                    XBUS_REGSTAGE_EN   => false              -- add XBUS register stage
                                    )
                         port    map(
                                    -- Global control --
                                    CLK_i       => CLK_i,       -- global clock, rising edge
                                    RSTN_i      => RSTN_i,      -- global reset, low-active, async
                                    -- primary UART0 (available if IO_UART0_EN = true) --
                                    uart0_txd_o => uart0_txd_o, -- UART0 send data
                                    uart0_rxd_i => uart0_rxd_i, -- UART0 receive data
                                    -- External bus interface (available if XBUS_EN = true) --
                                    xbus_adr_o  => wb_m_adr_o_u,  -- address
                                    xbus_dat_o  => wb_m_dat_o_u,  -- write data
                                    xbus_tag_o  => open,          -- access tag
                                    xbus_we_o   => wb_m_we_o,     -- read/write
                                    xbus_sel_o  => wb_m_sel_o_u,  -- byte enable
                                    xbus_stb_o  => wb_m_stb_o,    -- strobe
                                    xbus_cyc_o  => wb_m_cyc_o,    -- valid cycle
                                    xbus_dat_i  => wb_m_dat_i_u,  -- read data
                                    xbus_ack_i  => wb_m_ack_i,    -- transfer acknowledge
                                    xbus_err_i  => wb_m_err_i     -- transfer error
                                    );

-- Adjust with ulogic:
  wb_m_adr_o   <= To_StdLogicVector(wb_m_adr_o_u);
  wb_m_dat_o   <= To_StdLogicVector(wb_m_dat_o_u);
  wb_m_sel_o   <= To_StdLogicVector(wb_m_sel_o_u);

  wb_m_dat_i_u <=  To_StdULogicVector(wb_m_dat_i);

-- Mange acknowledge signal
  wb_m_ack_i  <= wb_s1_ack_o or wb_s2_ack_o;

-- Mange error signal
  wb_m_err_i  <= wb_s1_err_o or wb_s2_err_o;

-- Manage ADDRESS COMPARATOR signal
  ACMP(0) <= '1' when (wb_m_adr_o >= s1_base_addr) and (wb_m_adr_o <= s1_max_addr) else '0';
  ACMP(1) <= '1' when (wb_m_adr_o >= s2_base_addr) and (wb_m_adr_o <= s2_max_addr) else '0';
  
-- Manage stb signal
  wb_s1_stb_i <= wb_m_cyc_o and wb_m_stb_o and ACMP(0);
  wb_s2_stb_i <= wb_m_cyc_o and wb_m_stb_o and ACMP(1);

-- Manage wb master input data signal
  with ACMP select
  wb_m_dat_i <= wb_s1_dat_o     when   "01",
                wb_s2_dat_o     when   "10",
                (others => '0') when others;

end architecture;
