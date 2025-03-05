#!/usr/bin/env bash

set -ex

cd $(dirname "$0")

./run.py -v --gtkwave-fmt vcd
#./run.py MEM.tb_rom_wishbone.8.partial_test -v --gtkwave-fmt vcd

mv vunit_out/wave/*.vcd   ../../..
mv vunit_out/outcsv/*.csv ../../..
