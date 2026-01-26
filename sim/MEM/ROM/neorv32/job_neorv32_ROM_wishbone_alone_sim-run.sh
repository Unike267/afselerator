#!/usr/bin/env bash

set -ex

cd $(dirname "$0")

mv ../../../../rom_partial_neorv32_imem_image.vhd ../../../../neorv32-setups/neorv32/rtl/core/neorv32_imem_image.vhd
./run.py -v MEM.tb_neorv32_rom_wishbone.8.partial_test  --gtkwave-fmt vcd
./run.py -v MEM.tb_neorv32_rom_wishbone.16.partial_test --gtkwave-fmt vcd
./run.py -v MEM.tb_neorv32_rom_wishbone.32.partial_test --gtkwave-fmt vcd
mv ../../../../rom_all_neorv32_imem_image.vhd ../../../../neorv32-setups/neorv32/rtl/core/neorv32_imem_image.vhd
./run.py -v MEM.tb_neorv32_rom_wishbone.8.read_all_test  --gtkwave-fmt vcd
./run.py -v MEM.tb_neorv32_rom_wishbone.16.read_all_test 
./run.py -v MEM.tb_neorv32_rom_wishbone.32.read_all_test 
mv vunit_out/wave/*.vcd ../../../..
mv vunit_out/outcsv/*.csv ../../../..
