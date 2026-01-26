#!/usr/bin/env bash

set -ex

cd $(dirname "$0")

mv ../../../../ram_neorv32_imem_image.vhd ../../../../neorv32-setups/neorv32/rtl/core/neorv32_imem_image.vhd
./run.py -v MEM.tb_neorv32_ram_wishbone.8.test_ram  --gtkwave-fmt vcd
./run.py -v MEM.tb_neorv32_ram_wishbone.16.test_ram --gtkwave-fmt vcd
./run.py -v MEM.tb_neorv32_ram_wishbone.32.test_ram --gtkwave-fmt vcd
mv vunit_out/wave/*.vcd ../../../..
mv vunit_out/outcsv/*.csv ../../../..
mv ../../../../data/RAM-sim/8_string.hex ../../../../neorv32_ram_alone_wishbone_8_string.hex
mv ../../../../data/RAM-sim/16_string.hex ../../../../neorv32_ram_alone_wishbone_16_string.hex
mv ../../../../data/RAM-sim/32_string.hex ../../../../neorv32_ram_alone_wishbone_32_string.hex
