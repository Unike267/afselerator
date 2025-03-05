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
use std.textio.all;

package MEM_package is

  -- Types (Available in 8, 16 and 32 bits):
  type MEM8_t  is array (natural range <>) of std_logic_vector( 7 downto 0); -- Memory with  8-bit data width
  type MEM16_t is array (natural range <>) of std_logic_vector(15 downto 0); -- Memory with 16-bit data width
  type MEM32_t is array (natural range <>) of std_logic_vector(31 downto 0); -- Memory with 32-bit data width

  impure function MEM8_INIT_HEX (LOAD_FILE : string; MEM_ITEMS : natural) return  MEM8_t;
  impure function MEM16_INIT_HEX(LOAD_FILE : string; MEM_ITEMS : natural) return MEM16_t;
  impure function MEM32_INIT_HEX(LOAD_FILE : string; MEM_ITEMS : natural) return MEM32_t;

end MEM_package;

package body MEM_package is

  impure function MEM8_INIT_HEX(LOAD_FILE : STRING; MEM_ITEMS : natural) return MEM8_t is
    file     mem_file  : text open read_mode is LOAD_FILE;
    variable mem_line  : line;
    variable temp_word : std_logic_vector(7 downto 0);
    variable temp_mem  : MEM8_t(0 to MEM_ITEMS-1) := (others => (others => '0'));
  begin
    for i in 0 to MEM_ITEMS-1 loop
      exit when endfile (mem_file);
      readline(mem_file, mem_line);
      hread  (mem_line, temp_word);
      temp_mem(i)     := temp_word;
    end loop;
    return temp_mem;
  end function;

  impure function MEM16_INIT_HEX(LOAD_FILE : STRING; MEM_ITEMS : natural) return mem16_t is
    file     mem_file : text open read_mode is LOAD_FILE;
    variable mem_line : line;
    variable temp_word : std_logic_vector(15 downto 0);
    variable temp_mem : MEM16_t(0 to MEM_ITEMS-1) := (others => (others => '0'));
  begin
    for i in 0 to MEM_ITEMS-1 loop
      exit when endfile (mem_file);
      readline(mem_file, mem_line);
      hread  (mem_line, temp_word);
      temp_mem(i)     := temp_word;
    end loop;
    return temp_mem;
  end function;

  impure function MEM32_INIT_HEX(LOAD_FILE : STRING; MEM_ITEMS : natural) return mem32_t is
    file     mem_file : text open read_mode is LOAD_FILE;
    variable mem_line : line;
    variable temp_word : std_logic_vector(31 downto 0);
    variable temp_mem : MEM32_t(0 to MEM_ITEMS-1) := (others => (others => '0'));
  begin
    for i in 0 to MEM_ITEMS-1 loop
      exit when endfile (mem_file);
      readline(mem_file, mem_line);
      hread  (mem_line, temp_word);
      temp_mem(i)     := temp_word;
    end loop;
    return temp_mem;
  end function;

end MEM_package;
