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
  // BASE address 0x90000000
  static uint32_t add   = 0x90000000;
  // ROM Items (2**ROM depth)
  uint32_t items        =       1024;
  // Array to store data from the ROM
  uint32_t DATA[items];
  int i;

  #if defined sim
  // Choice between partial test or read all test
  uint32_t partial = 1;
  // Items to be checked in partial test
  uint32_t test_partial_items = 16;
  // Array of addresses to be checked in partial test
  // ARRAY[N] = {POS0,POS1,POS2,...,POSN}
  uint32_t addr_data[16] = {0x90000000,0x90000004,0x90000008,0x90000010,0x90000020,0x90000040,0x90000080,
      0x90000100,0x90000200,0x90000400,0x90000800,0x90000FFC,0x90000058,0x90000124,0x9000092C,0x90000A68};
  // Items to be checked in visual test via UART
  uint32_t visual_items_check = 2;
  // Array of addresses to be checked in visual test via UART
  uint32_t visual_checker[2] = {0,297};

  // Intro
  neorv32_uart0_printf("S");
  
  if(partial == 1){
    for (i=0; i < test_partial_items; i++){
      neorv32_cpu_load_unsigned_word(addr_data[i]);
    }
  }
  else{
    neorv32_cpu_csr_write(CSR_MCYCLE, 0);
      for (i=0; i < items; i++){
        DATA[i] = neorv32_cpu_load_unsigned_word(add);
        add = add + 4;
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

  // Force error to stop the test. It is trying to load an out of range data from address 0x90000FFD (if items are 1024 the maximum address is 0x90000FFC see ROM_wishbone.vhd file) so the err wishbone signal is going to activate.
    neorv32_cpu_load_unsigned_word(0x90001000);
  #else
  uint32_t lat;
  // Items to check
  uint32_t visual_items_check = 16;
  // Array of addresses to be checked 
  // ARRAY[N] = {POS0,POS1,POS2,...,POSN}
  uint32_t visual_checker[16] = {0,1,2,4,8,16,32,64,128,256,512,1023,22,73,587,666};

  // Intro
  neorv32_uart0_printf("\n<<< LOAD DATA FROM ROM >>>\n");

  // Measures how many cycles are used to read the entire ROM
  neorv32_cpu_csr_write(CSR_MCYCLE, 0);
  for (i=0; i < items; i++){
    DATA[i] = neorv32_cpu_load_unsigned_word(add);
    add = add + 4;
  }
  lat = neorv32_cpu_csr_read(CSR_MCYCLE) - 1; 

  neorv32_uart0_printf("\nTo load the entire ROM (%u elements) %u cycles were required\n", items, lat);
  neorv32_uart0_printf("\nCheck these 16 data to verify the reading\n");

  for (i=0; i < visual_items_check; i++){
    neorv32_uart0_printf("\nFOR address:  %u    <0x%x>",visual_checker[i],visual_checker[i]);
    neorv32_uart0_printf("\nROM OUTPUT is: %u   <0x%x>\n",DATA[visual_checker[i]],DATA[visual_checker[i]]);
  }
  // End
  neorv32_uart0_printf("\nProgram execution completed.\n");
  #endif

  return 0;
}
