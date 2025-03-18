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

entity tb_RAM is
  generic (
    RAM_WIDTH      : natural; -- RAM_WIDTH = RAM data width; FROM run.py
    RAM_STORE_FILE : string;  -- RAM_STORE_FILE = PATH of the FILE where RAM could be stored; FROM run.py
    runner_cfg     :  string
  );
end entity;

architecture tb of tb_RAM is

-- Define UUT constants:
  -- RAM_DEPTH = Log2 of number of elements that the RAM has; Number of RAM elements has to be a power of two.
  constant RAM_DEPTH         : natural :=             10; -- RAM SIZE = 2^RAM_DEPTH= 2^10 = 1024 elements  

-- Define tb constants:
  constant clk_period        : time    :=          10 ns;
  constant RAM_STORE_FILE_8  : string  := RAM_STORE_FILE &  "8_string.hex"; 
  constant RAM_STORE_FILE_16 : string  := RAM_STORE_FILE & "16_string.hex"; 
  constant RAM_STORE_FILE_32 : string  := RAM_STORE_FILE & "32_string.hex"; 

-- Define UUT Signals:
  signal clk     : std_logic                              :=            '0' ;
  signal addr    : std_logic_vector(RAM_DEPTH-1 downto 0) := (others => '0');
  signal we      : std_logic                              :=            '0' ;
  signal stb     : std_logic                              :=            '0' ;
  signal din     : std_logic_vector(RAM_WIDTH-1 downto 0) := (others => '0');
  signal dout    : std_logic_vector(RAM_WIDTH-1 downto 0) := (others => '0');

-- Define tb signals:
  signal start   : boolean                                :=           false;
  signal done    : boolean                                :=           false;
  signal store   : boolean                                :=           false;

-- Logging:
  constant logger : logger_t := get_logger("tb_RAM_" & to_string(RAM_WIDTH));
  constant file_handler : log_handler_t := new_log_handler(
    output_path(runner_cfg) & "log.csv",
    format => csv,
    use_color => false
  );

begin

  RAM_0 : entity MEM.RAM
                        generic map(
                                    RAM_WIDTH     => RAM_WIDTH,
                                    RAM_DEPTH     => RAM_DEPTH
                                   )
                        port    map(
                                    CLK  => clk,
                                    ADDR => addr,
                                    STB  => stb,
                                    WE   => we,
                                    DIN  => din,
                                    DOUT => dout
                                   );

  clk <= not clk after clk_period/2;

  main: process
  begin
    test_runner_setup(runner, runner_cfg);
    while test_suite loop
    -- If you wish, you can choose a test when launching the simulation (Different widths: 8,16,32)
      if run("test_ram") then
        set_log_handlers(logger, (display_handler, file_handler));
        show_all(logger, file_handler);
        show_all(logger, display_handler);

        wait for 15*clk_period;
        info(logger, "Init <RAM write/read all check>");
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
    variable tmp_RAM_8  : t_MEM8  (0 to ( 2**RAM_DEPTH)-1);
    variable tmp_RAM_16 : t_MEM16 (0 to ( 2**RAM_DEPTH)-1);
    variable tmp_RAM_32 : t_MEM32 (0 to ( 2**RAM_DEPTH)-1);
    variable RAM_din    : std_logic_vector(31 downto 0) := (others => '0');
  begin
    wait until start and rising_edge(clk);
      stb <= '1';
      for x in 0 to (2**RAM_DEPTH)-1 loop
        addr <= std_logic_vector(to_unsigned(x, RAM_DEPTH));
        we   <= '1';
        RAM_din := std_logic_vector(to_signed(x, 32)); 
        din     <= RAM_din(RAM_WIDTH-1 downto 0);                             
        wait for clk_period;
        info(logger, "---------------------------------------------------");
        info(logger, "For address            <0x" & to_hstring(addr(RAM_DEPTH-1 downto 0)) & ">:");
        info(logger, "Write in RAM the value <0x" & to_hstring(din( RAM_WIDTH-1 downto 0)) & ">" );
        we   <= '0';
        wait until (RAM_WIDTH = 8 and dout /= x"UU") or (RAM_WIDTH = 16 and dout /= x"UUUU") or (RAM_WIDTH = 32 and dout /= x"UUUUUUUU");
        info(logger, "RAM OUTPUT is: <0x" & to_hstring(dout(RAM_WIDTH-1 downto 0)) & "> and it should match: <0x" & to_hstring(din(RAM_WIDTH-1 downto 0)) & ">");
        check_equal(signed(dout),signed(din(RAM_WIDTH-1 downto 0)),"This is a failure!");
        tmp_RAM_8 (x) := dout when RAM_WIDTH = 8 else  (others => '0');
        tmp_RAM_16(x) := dout when RAM_WIDTH = 16 else (others => '0');
        tmp_RAM_32(x) := dout when RAM_WIDTH = 32 else (others => '0');
      end loop;
      stb <= '0';    
      wait until rising_edge(clk);
      info(logger, "---------------------------------------------------");
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
