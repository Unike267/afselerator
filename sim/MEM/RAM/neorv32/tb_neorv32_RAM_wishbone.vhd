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

library neorv32;
use neorv32.neorv32_package.all;

library vunit_lib;
context vunit_lib.vunit_context;

entity tb_neorv32_RAM_wishbone is
  generic (
    RAM_WIDTH      : natural; -- RAM_WIDTH = RAM data width; FROM run.py
    RAM_STORE_FILE :  string; -- RAM_STORE_FILE = PATH of the FILE where RAM could be stored; FROM run.py
    runner_cfg     :  string
  );
end entity;

architecture tb of tb_neorv32_RAM_wishbone is

-- Define UUT constants:
  -- RAM_DEPTH = Log2 of number of elements that the RAM has; Number of RAM elements has to be a power of two.
  constant RAM_DEPTH          : natural :=             10; -- RAM SIZE = 2^RAM_DEPTH= 2^10 = 1024 elements  
  constant baud0_rate_c       : natural :=          19200;
  constant CLOCK_FREQUENCY    : natural :=      100000000;

-- Define tb constants:
  constant clk_period        : time                          :=                            10 ns;
  constant RAM_STORE_FILE_8  : string                        := RAM_STORE_FILE &  "8_string.hex"; 
  constant RAM_STORE_FILE_16 : string                        := RAM_STORE_FILE & "16_string.hex"; 
  constant RAM_STORE_FILE_32 : string                        := RAM_STORE_FILE & "32_string.hex"; 
  constant base_addr         : std_logic_vector(31 downto 0) :=                      x"A0000000";

-- Define UART constant
  constant uart0_baud_val_c   : real    := real(CLOCK_FREQUENCY) / real(baud0_rate_c);

-- Define UUT Signals:
  signal clk       : std_logic                     :=            '0' ;
  signal rstn      : std_logic                     :=            '0' ;
  signal uart0_txd : std_logic;

-- Define tb signals:
  signal start     : boolean                        :=           false;
  signal done      : boolean                        :=           false;
  signal store     : boolean                        :=           false;
  signal m_we      : std_logic                      :=            '0' ;
  signal m_stb     : std_logic                      :=            '0' ;
  signal m_ack     : std_logic                      :=            '0' ;
  signal m_cyc     : std_logic                      :=            '0' ;
  signal m_err     : std_logic                      :=            '0' ;
  signal m_din     : std_ulogic_vector(31 downto 0) := (others => '0');
  signal m_dout    : std_ulogic_vector(31 downto 0) := (others => '0');
  signal m_adr     : std_ulogic_vector(31 downto 0) := (others => '0');
  signal ctrl      : ctrl_bus_t;
  signal csr_we    : std_logic                      :=            '0' ;
  signal csr_addr  : std_ulogic_vector(11 downto 0) := (others => '0');
  signal csr_rdata : std_ulogic_vector(31 downto 0) := (others => '0');


-- Logging:
  constant logger : logger_t := get_logger("tb_neorv32_RAM_wishbone_" & to_string(RAM_WIDTH));
  constant file_handler : log_handler_t := new_log_handler(
    output_path(runner_cfg) & "log.csv",
    format    => csv,
    use_color => false
  );

begin

  uut : 
  entity MEM.neorv32_RAM_wishbone
                                 generic map(
                                            CLOCK_FREQUENCY   => CLOCK_FREQUENCY,
                                            IMEM_SIZE         => 8192,
                                            DMEM_SIZE         => 8192,
                                            RAM_WIDTH         => RAM_WIDTH,
                                            RAM_DEPTH         => RAM_DEPTH
                                            )
                                 port    map(
                                            CLK_i       => clk,
                                            RSTN_i      => rstn,
                                            UART0_txd_o => uart0_txd,
                                            UART0_rxd_i => uart0_txd
                                            );

  uart0_checker :
  entity MEM.uart_rx_simple
                           generic map(
                                      name => "uart0",
                                      uart_baud_val_c => uart0_baud_val_c
                                      )
                           port    map(
                                      clk => clk,
                                      uart_txd => uart0_txd
                                      );

  clk <= not clk after clk_period/2;

  -- Capture wishbone signals through external names
  m_we   <= << signal .tb_neorv32_RAM_wishbone.uut.neorv32_top_inst.xbus_we_o  : std_logic >>;
  m_stb  <= << signal .tb_neorv32_RAM_wishbone.uut.neorv32_top_inst.xbus_stb_o : std_logic >>;
  m_ack  <= << signal .tb_neorv32_RAM_wishbone.uut.neorv32_top_inst.xbus_ack_i : std_logic >>;
  m_cyc  <= << signal .tb_neorv32_RAM_wishbone.uut.neorv32_top_inst.xbus_cyc_o : std_logic >>;
  m_err  <= << signal .tb_neorv32_RAM_wishbone.uut.neorv32_top_inst.xbus_err_i : std_logic >>;
  m_din  <= << signal .tb_neorv32_RAM_wishbone.uut.neorv32_top_inst.xbus_dat_i : std_ulogic_vector >>;
  m_dout <= << signal .tb_neorv32_RAM_wishbone.uut.neorv32_top_inst.xbus_dat_o : std_ulogic_vector >>;
  m_adr  <= << signal .tb_neorv32_RAM_wishbone.uut.neorv32_top_inst.xbus_adr_o : std_ulogic_vector >>;

  -- Capture CSR signals through external names
  ctrl      <= << signal .tb_neorv32_RAM_wishbone.uut.neorv32_top_inst.core_complex_gen(0).neorv32_cpu_inst.neorv32_cpu_control_inst.ctrl_o : ctrl_bus_t >>;
  csr_we    <= ctrl.csr_we;
  csr_addr  <= ctrl.csr_addr;
  csr_rdata <= << signal .tb_neorv32_RAM_wishbone.uut.neorv32_top_inst.core_complex_gen(0).neorv32_cpu_inst.neorv32_cpu_control_inst.csr_rdata_o : std_ulogic_vector(31 downto 0) >>;

  main: process
  begin
    test_runner_setup(runner, runner_cfg);
    while test_suite loop
    -- If you wish, you can choose a test when launching the simulation (Different widths: 8,16,32)
      if run("test_ram") then
        set_log_handlers(logger, (display_handler, file_handler));
        show_all(logger, file_handler);
        show_all(logger, display_handler);

        rstn <= '0';
        wait for 15*clk_period;
        rstn <= '1';
        info(logger, "Init <NEORV32 RAM wishbone write/read all check>");
        info(logger, "---------------------------------------------------");
        info(logger, "Config:");
        info(logger, "PATH of STORED-RAM FILE: <" & RAM_STORE_FILE & ">");
        info(logger, "RAM WIDTH: <" & to_string(RAM_WIDTH) & ">");
        wait until rising_edge(clk);
        start <= true;
        wait until rising_edge(clk);
        start <= false;
        wait until (done and rising_edge(clk));
        info(logger, "Test done");
      end if;
    end loop;
    test_runner_cleanup(runner);
    wait;
  end process;

  test: process
    variable wb_addr    : std_logic_vector(31 downto 0) :=       base_addr;
    variable RAM_dout   : std_logic_vector(31 downto 0) := (others => '0');
    variable tmp_RAM_8  : t_MEM8  (0 to ( 2**RAM_DEPTH)-1);
    variable tmp_RAM_16 : t_MEM16 (0 to ( 2**RAM_DEPTH)-1);
    variable tmp_RAM_32 : t_MEM32 (0 to ( 2**RAM_DEPTH)-1);
  begin
    done <= false;
    wait until start and rising_edge(clk);
    for x in 0 to (2**RAM_DEPTH)-1 loop
      wait until m_adr = wb_addr and m_cyc = '1' and m_stb = '1' and m_we = '1' and rising_edge(clk);
      info(logger, "---------------------------------------------------");
      info(logger, "For RAM address <0x" & to_hstring(wb_addr(2+(RAM_DEPTH-1) downto 2))  & "> | MEMORY MAPPED <0x" & to_hstring(m_adr) & ">"); 
      info(logger, "Write in RAM the value <0x" & to_hstring(m_dout(RAM_WIDTH-1 downto 0)) & ">" );
      wait until m_ack = '1' and rising_edge(clk);  
      wb_addr := std_logic_vector(unsigned(wb_addr) + 4);
    end loop;
    wait until rising_edge(clk) and csr_we = '0' and csr_addr = x"B00" and csr_rdata /= x"00000000"; -- CSR MYCYCLE ADDR IS 0xB00
    info(logger, "---------------------------------------------------");
    info(logger, "To write the entire RAM (" & integer'image(2**RAM_DEPTH) & " elements) <" & to_string(to_integer(unsigned(csr_rdata))-1) & "> cycles were required"); 
    wb_addr := base_addr;
    for x in 0 to (2**RAM_DEPTH)-1 loop
      RAM_dout := std_logic_vector(to_signed(x, 32)); 
      wait until m_adr = wb_addr and m_cyc = '1' and m_stb = '1' and m_we = '0' and rising_edge(clk);
      info(logger, "---------------------------------------------------");
      info(logger, "For RAM address <0x" & to_hstring(wb_addr(2+(RAM_DEPTH-1) downto 2))  & "> | MEMORY MAPPED <0x" & to_hstring(m_adr) & ">"); 
      wait until m_ack = '1' and rising_edge(clk);  
      info(logger, "RAM OUTPUT is:  <0x" & to_hstring(m_din(RAM_WIDTH-1 downto 0)) & ">");
      check_equal(signed(m_din(RAM_WIDTH-1 downto 0)),signed(RAM_dout(RAM_WIDTH-1 downto 0)),"This is a failure!");
      tmp_RAM_8 (x) := m_din( 7 downto 0) when RAM_WIDTH =  8 else (others => '0');
      tmp_RAM_16(x) := m_din(15 downto 0) when RAM_WIDTH = 16 else (others => '0');
      tmp_RAM_32(x) := m_din(31 downto 0) when RAM_WIDTH = 32 else (others => '0');
      wb_addr := std_logic_vector(unsigned(wb_addr) + 4);
    end loop;
    wait until rising_edge(clk) and csr_we = '0' and csr_addr = x"B00" and csr_rdata /= x"00000000"; -- CSR MYCYCLE ADDR IS 0xB00
    info(logger, "---------------------------------------------------");
    info(logger, "To read the entire RAM (" & integer'image(2**RAM_DEPTH) & " elements) <" & to_string(to_integer(unsigned(csr_rdata))-1) & "> cycles were required");    
    wait until m_err = '1' and rising_edge(clk); -- stop condition to finish test, see associated main.c
    info(logger, "---------------------- store ----------------------");
    info(logger, "Store RAM in the file " & RAM_STORE_FILE);
    with RAM_WIDTH select
    store <= MEM8_STORE_HEX( RAM_STORE_FILE_8, RAM_DEPTH,tmp_RAM_8 ) when  8,               
             MEM16_STORE_HEX(RAM_STORE_FILE_16,RAM_DEPTH,tmp_RAM_16) when 16,
             MEM32_STORE_HEX(RAM_STORE_FILE_32,RAM_DEPTH,tmp_RAM_32) when 32,
             false                                               when others;
    wait until store;
    info(logger, "---------------------------------------------------");
    done <= true;
    wait;
  end process;

end architecture;
