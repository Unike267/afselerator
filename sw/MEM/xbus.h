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

#include <string.h>
#include <stdint.h>

// Definition of constants
// The ROM BASE address is 0x90000000
#define ROM_BASE_ADDR       0x90000000
// The RAM base address is 0xA0000000
#define RAM_BASE_ADDR       0xA0000000


// Declaration of functions
void write_RAM(unsigned int address, int value);
int  read_ROM (unsigned int address);
int  read_RAM (unsigned int address);
