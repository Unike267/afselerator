#!/usr/bin/env bash

set -ex

cd $(dirname "$0")

./run.py -v --gtkwave-fmt vcd
#./run.py MEM.tb_ram.8.test_ram -v --gtkwave-fmt vcd

mv vunit_out/wave/*.vcd   ../../..
mv vunit_out/outcsv/*.csv ../../..
mv ../../../data/RAM-sim/*.hex ../../..
