#!/usr/bin/env bash

set -ex

cd $(dirname "$0")

./run.py -v --gtkwave-fmt vcd
#./run.py MEM.tb_ram.8.test_ram -v --gtkwave-fmt vcd

mv vunit_out/wave/*.vcd   ../../..
mv vunit_out/outcsv/*.csv ../../..
mv ../../../data/RAM-sim/8_string.hex ../../../ram_alone_8_string.hex
mv ../../../data/RAM-sim/16_string.hex ../../../ram_alone_16_string.hex
mv ../../../data/RAM-sim/32_string.hex ../../../ram_alone_32_string.hex
