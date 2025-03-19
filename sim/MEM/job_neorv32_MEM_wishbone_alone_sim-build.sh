#!/usr/bin/env bash

set -ex

cd $(dirname "$0")

cd ../../neorv32-setups/neorv32/sw/example 
mkdir mem-partial 
mkdir mem-all 
cp hello_world/makefile mem-partial/makefile 
cp hello_world/makefile mem-all/makefile 
cp ../../../../sw/MEM/main.c mem-partial/main.c 
cp ../../../../sw/MEM/main.c mem-all/main.c 
cd mem-partial
sed -i '19s|//#define sim|#define sim|' main.c
cd ../mem-all
sed -i '19s|//#define sim|#define sim|' main.c
sed -i '54s|  uint32_t partial = 1;|  uint32_t partial = 0;|' main.c
cd ../../..
make -C sw/example/mem-partial clean_all MARCH=rv32imac_zicsr_zifencei info image
make -C sw/example/mem-all clean_all MARCH=rv32imac_zicsr_zifencei info image
cp sw/example/mem-partial/neorv32_application_image.vhd ../../mem_partial_neorv32_application_image.vhd
cp sw/example/mem-all/neorv32_application_image.vhd ../../mem_all_neorv32_application_image.vhd
