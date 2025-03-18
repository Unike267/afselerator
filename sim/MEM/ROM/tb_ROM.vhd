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

entity tb_ROM is
  generic (
    ROM_WIDTH     : natural; -- Generic from run.py
    ROM_LOAD_FILE :  string; -- Generic from run.py
    runner_cfg    :  string
  );
end entity;

architecture tb of tb_ROM is

-- Define UUT constants:
  -- ROM_DEPTH = Log2 of number of elements that the ROM has; Number of ROM elements has to be a power of two.
  constant ROM_DEPTH          : natural             := 10; -- ROM SIZE = 2^ROM_DEPTH= 2^10 = 1024 elements  

-- Define tb constants:
  constant clk_period         : time    :=          10 ns;
  constant all_items          : natural := (2**ROM_DEPTH);
  constant test_partial_items : natural :=             16;

  type addr_t is array (0 to test_partial_items-1) of integer;
  -- ADDR data: this array contains the addresses to be checked.
  constant addr_data : addr_t := (
    (   0), 
    (   1),
    (   2),
    (   4),
    (   8),
    (  16),
    (  32),
    (  64),
    ( 128),
    ( 256),
    ( 512),
    (1023),
    (  22),
    (  73),
    ( 587),
    ( 666)
  ); 

  type data_t is array (natural range <>) of signed;
  -- These arrays contains the data that should be given by the ROM
  constant test_data_8 : data_t (0 to test_partial_items-1)(31 downto 0)   := (
    (32ux"EC"), 
    (32ux"EA"),
    (32ux"B6"),
    (32ux"E9"),
    (32ux"76"),
    (32ux"EE"),
    (32ux"B8"),
    (32ux"3B"),
    (32ux"05"),
    (32ux"0A"),
    (32ux"48"),
    (32ux"01"),
    (32ux"7E"),
    (32ux"F4"),
    (32ux"8F"),
    (32ux"93")
  ); 
  constant test_data_16 : data_t (0 to test_partial_items-1)(31 downto 0) := (
    (32ux"6A6B"), 
    (32ux"1448"),
    (32ux"21FC"),
    (32ux"17EA"),
    (32ux"5798"),
    (32ux"8852"),
    (32ux"FD59"),
    (32ux"8926"),
    (32ux"BE2B"),
    (32ux"67ED"),
    (32ux"2EA1"),
    (32ux"1EEC"),
    (32ux"CF5B"),
    (32ux"9C4C"),
    (32ux"69BC"),
    (32ux"E13F")
  ); 
  constant test_data_32 : data_t (0 to test_partial_items-1)(31 downto 0) := (
    (x"FF7FFB87"), 
    (x"A5A38967"),
    (x"BDE9EC10"),
    (x"232E2B03"),
    (x"0DB4D5E0"),
    (x"07900A14"),
    (x"02BDCACD"),
    (x"29161675"),
    (x"13FB2C08"),
    (x"4D49E563"),
    (x"BF474041"),
    (x"C7114AB3"),
    (x"EA9735D9"),
    (x"6145000E"),
    (x"E28AD297"),
    (x"2710BA20")
  ); 
  
  -- Array to check ROM output
  type checker_t is array (0 to 3-1) of data_t;
  constant checker : checker_t := (
  test_data_8, test_data_16, test_data_32);

-- Define UUT Signals:
  signal clk     : std_logic                              :=            '0' ;
  signal addr    : std_logic_vector(ROM_DEPTH-1 downto 0) := (others => '0');
  signal stb     : std_logic                              :=            '0' ;
  signal dout    : std_logic_vector(ROM_WIDTH-1 downto 0) := (others => '0');

-- Define tb signals:
  signal start   : boolean                                :=           false;
  signal done    : boolean                                :=           false;
  signal partial : boolean                                :=           false;

-- Logging:
  constant logger : logger_t := get_logger("tb_ROM_" & to_string(ROM_WIDTH));
  constant file_handler : log_handler_t := new_log_handler(
    output_path(runner_cfg) & "log.csv",
    format => csv,
    use_color => false
  );

begin

  ROM_0 : entity MEM.ROM
                        generic map(
                                    ROM_WIDTH     => ROM_WIDTH,
                                    ROM_DEPTH     => ROM_DEPTH,
                                    ROM_LOAD_FILE => ROM_LOAD_FILE
                                   )
                        port    map(
                                    CLK  => clk,
                                    ADDR => addr,
                                    STB  => stb,
                                    DOUT => dout
                                   );

  clk <= not clk after clk_period/2;

  main: process
  begin
    test_runner_setup(runner, runner_cfg);
    while test_suite loop
    -- If you wish, you can choose any test when launching the simulation
      if run("partial_test") then
        set_log_handlers(logger, (display_handler, file_handler));
        show_all(logger, file_handler);
        show_all(logger, display_handler);

        wait for 15*clk_period;
        info(logger, "Init <ROM partial test check>");
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

        wait for 15*clk_period;
        info(logger, "Init <ROM read all check>");
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
    variable y : natural;       
  begin
    with ROM_WIDTH select
    y := 0  when  8,
         1  when 16,
         2  when 32,
         99 when others; -- Exception  
    done <= true when  y = 99  else false; -- Exit if size is not contemplated.
    wait until start and rising_edge(clk);
    if partial then
      stb <= '1';
      for x in 0 to test_partial_items-1 loop
        addr <= std_logic_vector(to_unsigned(addr_data(x), ROM_DEPTH));
        wait until  rising_edge(clk);
        wait until falling_edge(clk);
        info(logger, "---------------------------------------------------");
        info(logger, "For address    <0x" & to_hstring(to_unsigned(addr_data(x), ROM_DEPTH)) & ">:");
        info(logger, "ROM OUTPUT is: <0x" & to_hstring(dout(ROM_WIDTH-1 downto 0)) & "> and it should match: <0x" & to_hstring(checker(y)(x)(ROM_WIDTH-1 downto 0)) & ">");
        check_equal(signed(dout),checker(y)(x)(ROM_WIDTH-1 downto 0),"This is a failure!");
      end loop;
      info(logger, "---------------------------------------------------");
      stb <= '0';    
      wait until rising_edge(clk);
      done <= true;
      wait;
    else 
      stb <= '1';
      for x in 0 to (2**ROM_DEPTH)-1 loop
        addr <= std_logic_vector(to_unsigned(x, ROM_DEPTH));
        wait until  rising_edge(clk);
        wait until falling_edge(clk);
        info(logger, "---------------------------------------------------");
        info(logger, "For address    <0x" & to_hstring(to_unsigned(x, ROM_DEPTH)) & ">:");
        info(logger, "ROM OUTPUT is: <0x" & to_hstring(dout(ROM_WIDTH-1 downto 0)) & ">");
      end loop;
      info(logger, "---------------------------------------------------");
      stb <= '0';    
      wait until rising_edge(clk);
      done <= true;
      wait;
    end if;
  end process;

end architecture;
