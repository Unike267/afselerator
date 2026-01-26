#!/usr/bin/env bash

set -ex

cd $(dirname "$0")

cd ../../../../neorv32-setups/neorv32/sw/example 
mkdir rom-partial 
mkdir rom-all 
cp hello_world/makefile rom-partial/makefile 
cp hello_world/makefile rom-all/makefile 
cp ../../../../sw/MEM/ROM/main.c rom-partial/main.c 
cp ../../../../sw/MEM/ROM/main.c rom-all/main.c 
cd rom-partial
sed -i '19s|//#define sim|#define sim|' main.c
cd ../rom-all
sed -i '19s|//#define sim|#define sim|' main.c
sed -i '51s|  uint32_t partial = 1;|  uint32_t partial = 0;|' main.c
cd ../../..
make -C sw/example/rom-partial clean_all MARCH=rv32imac_zicsr_zifencei info image
make -C sw/example/rom-all clean_all MARCH=rv32imac_zicsr_zifencei info image
cp sw/example/rom-partial/neorv32_imem_image.vhd ../../rom_partial_neorv32_imem_image.vhd
cp sw/example/rom-all/neorv32_imem_image.vhd ../../rom_all_neorv32_imem_image.vhd
