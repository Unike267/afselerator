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

entity finisher is
port (
    CLK_i   : in  std_logic;                     -- Clock
    RSTN_i  : in  std_ulogic;                    -- Low-active async reset
    ADDR_i  : in  std_logic_vector(31 downto 0); -- Wishbone address input
    WE_i    : in  std_logic;                     -- Wishbone write enable signal
    SEL_i   : in  std_logic_vector(3 downto 0);  -- Wishbone select input signal
    STB_i   : in  std_logic;                     -- Wishbone strobe input signal
    ACK_o   : out std_logic;                     -- Wishbone acknowledge output signal
    CYC_i   : in  std_logic;                     -- Wishbone cycle input signal
    ERR_o   : out std_logic;                     -- Wishbone error output signal
    STALL_o : out std_logic                      -- Wishbone pipeline stall output signal
    );
end finisher;

architecture finisher_RTL of finisher is

-- Define finisher constants:
  constant finisher_addr : std_logic_vector(31 downto 0) := x"B0000000";

-- Define finisher signals:
  signal wb            : boolean                                :=          false ;
  signal err           : boolean                                :=          false ;

begin

-- The finisher is a dummy wishbone slave without storage, memory mapped to NEORV32 at the single address 0xB0000000.
-- Software ends a simulation by writing to this address (see finish() in sw/MEM/xbus.c): the access is acknowledged
-- and the testbenches use that acknowledge (m_ack = '1' and m_adr = 0xB0000000) as the stop condition.
-- No data is stored or returned (reads return zero through the interconnect).
-- The interconnect only selects the finisher for the exact address 0xB0000000; the error signal below is kept as a
-- safeguard in case the finisher is connected with a wider address decoding.
--
-- NOTE (FPGA implementation): the finisher is only meaningful in simulation, but it is also synthesized when the
-- circuit is implemented on the FPGA. Synthesis pragmas (translate_off/on) are tool specific and this code is meant
-- to be synthesizable by several tools (e.g. Vivado and nextpnr-xilinx), so they are not used. The portable way to
-- remove it would be a generic plus if-generate in the wrappers (see PR #3), but for now it is kept: it is very
-- little logic (one 32-bit comparator and one flip-flop) and it has no side effects, since the implementation
-- software never accesses 0xB0000000.

-- Manage wishbone signal
  -- Activated when a wishbone request is made by wishbone master
  wb <= ?? (STB_i and CYC_i);

-- Manage error signal:
  -- Error when reading/writing attempt occurs and address is not exactly 0xB0000000.
  err <= (wb) and (ADDR_i /= finisher_addr);

  ERR_o <= '1' when err else '0';

-- Manage stall signal
  STALL_o <= '0';

-- Manage ack signal

  Manage_ack_signal: process (CLK_i, RSTN_i)
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

end finisher_RTL;
