#!/usr/bin/env bash

set -ex

cd $(dirname "$0")

mv ../../../../ram_neorv32_application_image.vhd ../../../../neorv32-setups/neorv32/rtl/core/neorv32_application_image.vhd
./run.py -v MEM.tb_neorv32_ram_wishbone.8.test_ram  --gtkwave-fmt vcd
./run.py -v MEM.tb_neorv32_ram_wishbone.16.test_ram --gtkwave-fmt vcd
./run.py -v MEM.tb_neorv32_ram_wishbone.32.test_ram --gtkwave-fmt vcd
mv vunit_out/wave/*.vcd ../../../..
mv vunit_out/outcsv/*.csv ../../../..
mv ../../../../data/RAM-sim/*.hex ../../../..
