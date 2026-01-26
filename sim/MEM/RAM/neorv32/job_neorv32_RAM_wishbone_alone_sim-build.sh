#!/usr/bin/env bash

set -ex

cd $(dirname "$0")

cd ../../../../neorv32-setups/neorv32/sw/example 
mkdir ram
cp hello_world/makefile ram/makefile
cp ../../../../sw/MEM/RAM/main.c ram/main.c
cd ram
sed -i '19s|//#define sim|#define sim|' main.c
cd ../../..
make -C sw/example/ram clean_all MARCH=rv32imac_zicsr_zifencei info image
cp sw/example/ram/neorv32_imem_image.vhd ../../ram_neorv32_imem_image.vhd
