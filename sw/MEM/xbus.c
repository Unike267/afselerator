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

#include "xbus.h"

// Definition of functions 

//Write to DUAL-PORT RAM through default memory mapped interface i.e XBUS
void write_RAM(unsigned int address, int value)
{
    unsigned int offset = address + RAM_BASE_ADDR;

    int volatile * const data_wr = (int *) offset;
    *data_wr = value;
    return;
}

//Read from DUAL-PORT ROM through default memory mapped interface i.e XBUS
int read_ROM(unsigned int address)
{
    unsigned int offset = address + ROM_BASE_ADDR;
    int read;

    int volatile * const data_rd = (int *) offset;
    read = *data_rd;
    return read;
}

//Read from DUAL-PORT RAM through default memory mapped interface i.e XBUS
int read_RAM(unsigned int address)
{
    unsigned int offset = address + RAM_BASE_ADDR;
    int read;

    int volatile * const data_rd = (int *) offset;
    read = *data_rd;
    return read;
}
