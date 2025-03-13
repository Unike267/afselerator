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

entity tb_neorv32_ROM_wishbone is
  generic (
    ROM_WIDTH     : natural; -- Generic from run.py
    ROM_LOAD_FILE :  string; -- Generic from run.py
    runner_cfg    :  string
  );
end entity;

architecture tb of tb_neorv32_ROM_wishbone is

-- Define UUT constants:
  -- ROM_DEPTH = Log2 of number of elements that the ROM has; Number of ROM elements has to be a power of two.
  constant ROM_DEPTH          : natural :=             10; -- ROM SIZE = 2^ROM_DEPTH= 2^10 = 1024 elements  
  constant baud0_rate_c       : natural :=          19200;
  constant CLOCK_FREQUENCY    : natural :=      100000000;

-- Define tb constants:
  constant clk_period         : time                          :=          10 ns;
  constant all_items          : natural                       := (2**ROM_DEPTH);
  constant test_partial_items : natural                       :=             16;
  constant base_addr          : std_logic_vector(31 downto 0) :=    x"90000000";

  type addr_t is array (natural range <>) of std_logic_vector;
  -- ADDR data: this array contains the addresses to be checked.
  constant addr_data : addr_t (0 to test_partial_items-1)(31 downto 0)     := (
    -- Memory mapped addr: | -- ROM addr:
    (x"90000000"),                    -- 0
    (x"90000004"),                    -- 1
    (x"90000008"),                    -- 2
    (x"90000010"),                    -- 4
    (x"90000020"),                    -- 8
    (x"90000040"),                    -- 16
    (x"90000080"),                    -- 32
    (x"90000100"),                    -- 64
    (x"90000200"),                    -- 128
    (x"90000400"),                    -- 256
    (x"90000800"),                    -- 512
    (x"90000FFC"),                    -- 1023
    (x"90000058"),                    -- 22
    (x"90000124"),                    -- 73
    (x"9000092C"),                    -- 587
    (x"90000A68")                     -- 666
  );  

  type data_t is array (natural range <>) of signed;
  -- These arrays contains the data that should be given by the ROM
  constant test_data_8 : data_t (0 to test_partial_items-1)(31 downto 0)   := (
    (32ux"ec"), 
    (32ux"ea"),
    (32ux"b6"),
    (32ux"e9"),
    (32ux"76"),
    (32ux"ee"),
    (32ux"b8"),
    (32ux"3b"),
    (32ux"05"),
    (32ux"0a"),
    (32ux"48"),
    (32ux"01"),
    (32ux"7e"),
    (32ux"f4"),
    (32ux"8f"),
    (32ux"93")
  ); 
  constant test_data_16 : data_t (0 to test_partial_items-1)(31 downto 0) := (
    (32ux"6a6b"), 
    (32ux"1448"),
    (32ux"21fc"),
    (32ux"17ea"),
    (32ux"5798"),
    (32ux"8852"),
    (32ux"fd59"),
    (32ux"8926"),
    (32ux"be2b"),
    (32ux"67ed"),
    (32ux"2ea1"),
    (32ux"1eec"),
    (32ux"cf5b"),
    (32ux"9c4c"),
    (32ux"69bc"),
    (32ux"e13f")
  ); 
  constant test_data_32 : data_t (0 to test_partial_items-1)(31 downto 0) := (
    (x"ff7ffb87"), 
    (x"a5a38967"),
    (x"bde9ec10"),
    (x"232e2b03"),
    (x"0db4d5e0"),
    (x"07900a14"),
    (x"02bdcacd"),
    (x"29161675"),
    (x"13fb2c08"),
    (x"4d49e563"),
    (x"bf474041"),
    (x"c7114ab3"),
    (x"ea9735d9"),
    (x"6145000e"),
    (x"e28ad297"),
    (x"2710ba20")
  ); 
  
  -- Array to check ROM output
  type checker_t is array (0 to 3-1) of data_t;
  constant checker : checker_t := (
  test_data_8, test_data_16, test_data_32);

-- Define UART constant
  constant uart0_baud_val_c   : real    := real(CLOCK_FREQUENCY) / real(baud0_rate_c);

-- Define UUT Signals:
  signal clk       : std_logic                     :=            '0' ;
  signal rstn      : std_logic                     :=            '0' ;
  signal uart0_txd : std_logic;

-- Define tb signals:
  signal start     : boolean                        :=           false;
  signal done      : boolean                        :=           false;
  signal partial   : boolean                        :=           false;
  signal m_we      : std_logic                      :=            '0' ;
  signal m_stb     : std_logic                      :=            '0' ;
  signal m_ack     : std_logic                      :=            '0' ;
  signal m_cyc     : std_logic                      :=            '0' ;
  signal m_err     : std_logic                      :=            '0' ;
  signal m_din     : std_ulogic_vector(31 downto 0) := (others => '0');
  signal m_adr     : std_ulogic_vector(31 downto 0) := (others => '0');
  signal ctrl      : ctrl_bus_t;
  signal csr_we    : std_logic                      :=            '0' ;
  signal csr_addr  : std_ulogic_vector(11 downto 0) := (others => '0');
  signal csr_rdata : std_ulogic_vector(31 downto 0) := (others => '0');


-- Logging:
  constant logger : logger_t := get_logger("tb_neorv32_ROM_wishbone_" & to_string(ROM_WIDTH));
  constant file_handler : log_handler_t := new_log_handler(
    output_path(runner_cfg) & "log.csv",
    format    => csv,
    use_color => false
  );

begin

  uut : 
  entity MEM.neorv32_ROM_wishbone
                                 generic map(
                                            CLOCK_FREQUENCY   => CLOCK_FREQUENCY,
                                            MEM_INT_IMEM_SIZE => 8192,
                                            MEM_INT_DMEM_SIZE => 8192,
                                            ROM_WIDTH         => ROM_WIDTH,
                                            ROM_DEPTH         => ROM_DEPTH,
                                            ROM_LOAD_FILE     => ROM_LOAD_FILE
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
  m_we  <= << signal .tb_neorv32_ROM_wishbone.uut.neorv32_top_inst.xbus_we_o  : std_logic >>;
  m_stb <= << signal .tb_neorv32_ROM_wishbone.uut.neorv32_top_inst.xbus_stb_o : std_logic >>;
  m_ack <= << signal .tb_neorv32_ROM_wishbone.uut.neorv32_top_inst.xbus_ack_i : std_logic >>;
  m_cyc <= << signal .tb_neorv32_ROM_wishbone.uut.neorv32_top_inst.xbus_cyc_o : std_logic >>;
  m_err <= << signal .tb_neorv32_ROM_wishbone.uut.neorv32_top_inst.xbus_err_i : std_logic >>;
  m_din <= << signal .tb_neorv32_ROM_wishbone.uut.neorv32_top_inst.xbus_dat_i : std_ulogic_vector >>;
  m_adr <= << signal .tb_neorv32_ROM_wishbone.uut.neorv32_top_inst.xbus_adr_o : std_ulogic_vector >>;

  -- Capture CSR signals through external names
  ctrl      <= << signal .tb_neorv32_ROM_wishbone.uut.neorv32_top_inst.core_complex_gen(0).neorv32_cpu_inst.neorv32_cpu_control_inst.ctrl_o : ctrl_bus_t >>;
  csr_we    <= ctrl.csr_we;
  csr_addr  <= ctrl.csr_addr;
  csr_rdata <= << signal .tb_neorv32_ROM_wishbone.uut.neorv32_top_inst.core_complex_gen(0).neorv32_cpu_inst.neorv32_cpu_control_inst.csr_rdata_o : std_ulogic_vector(XLEN-1 downto 0) >>;

  main: process
  begin
    test_runner_setup(runner, runner_cfg);
    while test_suite loop
    -- If you wish, you can choose a test when launching the simulation
      if run("partial_test") then
        set_log_handlers(logger, (display_handler, file_handler));
        show_all(logger, file_handler);
        show_all(logger, display_handler);

        rstn <= '0';
        wait for 15*clk_period;
        rstn <= '1';
        info(logger, "Init <NEORV32 wishbone partial test check>");
        info(logger, "---------------------------------------------------");
        info(logger, "Config:");
        info(logger, "PATH of ROM FILE: <" & ROM_LOAD_FILE & ">");
        info(logger, "ROM WIDTH: <" & to_string(ROM_WIDTH) & ">");
        wait until rising_edge(clk);
        start <= true;
        partial <= true;
        wait until rising_edge(clk);
        start <= false;
        wait until (done and rising_edge(clk));
        info(logger, "Test done");
        partial <= false;
      elsif run("read_all_test") then
        set_log_handlers(logger, (display_handler, file_handler));
        show_all(logger, file_handler);
        show_all(logger, display_handler);
        
        rstn <= '0';
        wait for 15*clk_period;
        rstn <= '1';
        info(logger, "Init <NEORV32 wishbone read all ROM>");
        info(logger, "---------------------------------------------------");
        info(logger, "Config:");
        info(logger, "PATH of ROM FILE: <" & ROM_LOAD_FILE & ">");
        info(logger, "ROM WIDTH: <" & to_string(ROM_WIDTH) & ">");
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
    variable y       :                       natural :=             0  ;   
    variable wb_addr : std_logic_vector(31 downto 0) :=       base_addr;
  begin
    with ROM_WIDTH select
    y := 0  when  8,
         1  when 16,
         2  when 32,
         99 when others; -- Exception 
    done <= true when  y = 99  else false; -- Exit if size is not contemplated.
    wait until start and rising_edge(clk);
    if partial then
      for x in 0 to test_partial_items-1 loop
        wait until m_adr = addr_data(x) and m_cyc = '1' and m_stb = '1' and m_we = '0' and rising_edge(clk);
        info(logger, "---------------------------------------------------");
        info(logger, "For ROM address <0x" & to_hstring(addr_data(x)(2+(ROM_DEPTH-1) downto 2))  & "> | MEMORY MAPPED <0x" & to_hstring(m_adr) & ">");  
        wait until m_ack = '1' and rising_edge(clk);  
        info(logger, "ROM OUTPUT is:  <0x" & to_hstring(m_din(ROM_WIDTH-1 downto 0)) & "> and it should match: <0x" & to_hstring(checker(y)(x)(ROM_WIDTH-1 downto 0)) & ">");
        check_equal(signed(m_din(ROM_WIDTH-1 downto 0)),checker(y)(x)(ROM_WIDTH-1 downto 0),"This is a failure!");
      end loop;
      info(logger,   "---------------------------------------------------");
      wait until m_err = '1' and rising_edge(clk); -- stop condition to finish test, see associated main.c
      done <= true;
      wait;
    else 
      for x in 0 to (2**ROM_DEPTH)-1 loop
        wait until m_adr = wb_addr and m_cyc = '1' and m_stb = '1' and m_we = '0' and rising_edge(clk);
        info(logger, "---------------------------------------------------");
        info(logger, "For ROM address <0x" & to_hstring(wb_addr(2+(ROM_DEPTH-1) downto 2))  & "> | MEMORY MAPPED <0x" & to_hstring(m_adr) & ">"); 
        wait until m_ack = '1' and rising_edge(clk);  
        info(logger, "ROM OUTPUT is:  <0x" & to_hstring(m_din(ROM_WIDTH-1 downto 0)) & ">");
        wb_addr := std_logic_vector(unsigned(wb_addr) + 4);
      end loop;
      wait until rising_edge(clk) and csr_we = '0' and csr_addr = x"B00" and csr_rdata /= x"00000000"; -- CSR MYCYCLE ADDR IS 0xB00
      info(logger, "---------------------------------------------------");
      info(logger, "To load the entire ROM (" & integer'image(2**ROM_DEPTH) & " elements) <" & to_string(to_integer(unsigned(csr_rdata))-1) & "> cycles were required"); 
      info(logger, "---------------------------------------------------");
      wait until m_err = '1' and rising_edge(clk); -- stop condition to finish test, see associated main.c
      done <= true;
      wait;
    end if;
  end process;

end architecture;
