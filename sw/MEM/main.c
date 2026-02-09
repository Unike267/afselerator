// Author:
//   Unai Sainz-Estebanez
// Email:
//  <unai.sainze@ehu.eus>
//
// Licensed under the GNU General Public License v3.0;
// You may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.gnu.org/licenses/gpl-3.0.html

#include <neorv32.h>
#include <string.h>
#include "xbus.h"

#define BAUD_RATE 19200

// This define allows you to switch between simulation or implementation. 
// Commented for implementation uncommented for simulation
//#define sim

int main() {
    
  // Capture all exceptions and give debug info via UART0
  neorv32_rte_setup();

  // Setup UART at default baud rate, no interrupts
  neorv32_uart0_setup(BAUD_RATE, 0);

  // Check if UART0 unit is implemented at all
  if (neorv32_uart0_available() == 0) {
    return -1; // abort if not implemented
  }

  // check if the CPU base counters are implemented
  if ((neorv32_cpu_csr_read(CSR_MXISA) & (1 << CSR_MXISA_ZICNTR)) == 0) {
    neorv32_uart0_printf("ERROR! Base counters ('Zicntr' ISA extensions) not implemented!\n");
    return -1;
  }

  // Declaration of variables 
  // MEM Items (2**MEM depth); ROM and RAM has the same items
  uint32_t items        =       1024;
  // Array to store data from the RAM
  uint32_t DATA[items];

  int i;

  #if defined sim
  // Choice between partial test or read/write all test
  uint32_t partial = 1;
  // Items to be checked in partial test
  uint32_t test_partial_items = 16;
  // Array of addresses to be checked in partial test
  // ARRAY[N] = {POS0,POS1,POS2,...,POSN}
  uint32_t addr_data[16] = {0x00000000,0x00000004,0x00000008,0x00000010,0x00000020,0x00000040,0x00000080,
      0x00000100,0x00000200,0x00000400,0x00000800,0x00000FFC,0x00000058,0x00000124,0x0000092C,0x00000A68};
  // Items to be checked in visual test via UART
  uint32_t visual_items_check = 2;
  // Array of addresses to be checked in visual test via UART
  uint32_t visual_checker[2] = {0,297};

  // Intro
  neorv32_uart0_printf("S");

  if(partial == 1){
    for (i=0; i < test_partial_items; i++){
      // Write to RAM what has been read in ROM
      write_RAM(addr_data[i],read_ROM(addr_data[i]));
    }
  }
  else{
    neorv32_cpu_csr_write(CSR_MCYCLE, 0);
    for (i=0; i < items * 4 ; i+=4){
      // Write to RAM what has been read in ROM
      write_RAM(i,read_ROM(i));
    }
    neorv32_cpu_csr_read(CSR_MCYCLE); 

    neorv32_cpu_csr_write(CSR_MCYCLE, 0);
    for (i=0; i < items * 4 ; i+=4){
      // READ all the RAM
      DATA[i/4] = read_RAM(i);
    }
    neorv32_cpu_csr_read(CSR_MCYCLE); 

    // Visual check via UART
    for (i=0; i < visual_items_check; i++){
    // Please note that decimal numbers will be printed.
    // addr   0 (0x00)  -> 236 (0xEC), 27243 (0x6A6B), 4286577543 (0xFF7FFB87)
    // addr 297 (0x129) ->  46 (0x2E), 52099 (0xCB83),    7858042 (0x0077E77A)
    neorv32_uart0_printf("-%u,%u-",visual_checker[i],DATA[visual_checker[i]]);
      // To make sure that the previous uart printout is finished correctly (this print will only be made halfway)
      if (i == visual_items_check - 1){
        neorv32_uart0_printf("END");
      }
    }
  }

  // Force error to stop the test. It is trying to load a misaligned data from address 0xA0000001 (see RAM_wishbone.vhd file) so the err wishbone signal is going to activate.
  neorv32_cpu_load_unsigned_byte(0xA0000001);

  #else
  uint32_t wr_lat;
  uint32_t rd_lat;
  // Items to check
  uint32_t visual_items_check = 16;
  // Array of addresses to be checked 
  // ARRAY[N] = {POS0,POS1,POS2,...,POSN}
  uint32_t visual_checker[16] = {0,1,2,4,8,16,32,64,128,256,512,1023,22,73,587,666};
  // Intro
  neorv32_uart0_printf("\n<<< LOAD DATA FROM ROM; WRITE THESE LOADED DATA IN RAM; READ THE RAM >>>\n");

  // Measures how many cycles are used to write to RAM what has been read in ROM
  neorv32_cpu_csr_write(CSR_MCYCLE, 0);
  for (i=0; i < items * 4 ; i+=4){
    // Write to RAM what has been read in ROM
    write_RAM(i,read_ROM(i));
  }
  wr_lat = neorv32_cpu_csr_read(CSR_MCYCLE) - 1; 

  // Measures how many cycles are used to read the entire RAM
  neorv32_cpu_csr_write(CSR_MCYCLE, 0);
  for (i=0; i < items * 4 ; i+=4){
  // READ all the RAM
    DATA[i/4] = read_RAM(i);
  }
  rd_lat = neorv32_cpu_csr_read(CSR_MCYCLE) - 1;

  neorv32_uart0_printf("\nTo write to RAM what has been read in ROM (both %u elements) %u cycles were required\n", items, wr_lat);
  neorv32_uart0_printf("\nTo read the entire RAM  (%u elements) %u cycles were required\n", items, rd_lat);
  neorv32_uart0_printf("\nCheck these 16 data to verify the reading\n");

  for (i=0; i < visual_items_check; i++){
    neorv32_uart0_printf("\nFOR address:  %u    <0x%x>",visual_checker[i],visual_checker[i]);
    neorv32_uart0_printf("\nRAM OUTPUT is: %u   <0x%x>\n",DATA[visual_checker[i]],DATA[visual_checker[i]]);
  }
  // End
  neorv32_uart0_printf("\nProgram execution completed.\n");
  #endif

  return 0;
}
