#!/usr/bin/env python3

# Author:
#   Unai Sainz-Estebanez
# Email:
#  <unai.sainze@ehu.eus>
#
# Licensed under the GNU General Public License v3.0;
# You may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.gnu.org/licenses/gpl-3.0.html

from pathlib import Path
from vunit import VUnit
from shutil import copyfile
from os import makedirs, getenv
import re, os

# Function to take the csv from a folder with unknown path and put that csv into a folder with known path
def post_func(results):
    report = results.get_report()
    out_dir_csv = Path(report.output_path) / "outcsv"
    out_dir_wave = Path(report.output_path) / "wave"
    list = [out_dir_csv,out_dir_wave]

    for items in list:        
        try:
            makedirs(str(items))
        except FileExistsError:
            pass

    for key, item in report.tests.items():
        if key == "MEM.tb_ram.8.test_ram": # Copy the output csv and the wave in vcd to known path
            copyfile(
                str(Path(item.path) / "log.csv"),
                str(out_dir_csv / "tb_RAM_8.csv"),
            )
            copyfile(
                str(Path(item.path) / "ghdl" / "wave.vcd"),
                str(out_dir_wave / "wave_RAM_8.vcd"),
            )
        elif key == "MEM.tb_ram.16.test_ram": # Copy the output csv and the wave in vcd to known path
            copyfile(
                str(Path(item.path) / "log.csv"),
                str(out_dir_csv / "tb_RAM_16.csv"),
            )
            copyfile(
                str(Path(item.path) / "ghdl" / "wave.vcd"),
                str(out_dir_wave / "wave_RAM_16.vcd"),
            )
        elif key == "MEM.tb_ram.32.test_ram": # Copy the output csv and the wave in vcd to known path
            copyfile(
                str(Path(item.path) / "log.csv"),
                str(out_dir_csv / "tb_RAM_32.csv"),
            )
            copyfile(
                str(Path(item.path) / "ghdl" / "wave.vcd"),
                str(out_dir_wave / "wave_RAM_32.vcd"),
            )
       

vu = VUnit.from_argv()
vu.add_vhdl_builtins()
vu.enable_location_preprocessing()

ROOT = Path(__file__).parent

MEM = vu.add_library("MEM")
MEM.add_source_files([
    ROOT /                       "tb_RAM.vhd",
    ROOT / "../../../rtl/MEM/MEM_package.vhd",
    ROOT /     "../../../rtl/MEM/RAM/RAM.vhd",
])

RAM_PATH       = [str(ROOT)+"/../../../data/RAM-sim/"]
RAM_STORE_FILE = ", ".join(map(str, RAM_PATH))
testbench      = MEM.entity("tb_RAM")
test_ram       = testbench.test ("test_ram")

generics_8    =     dict(RAM_STORE_FILE=RAM_STORE_FILE, RAM_WIDTH="8")
test_ram.add_config(name='8' , generics=generics_8 )
generics_16    =     dict(RAM_STORE_FILE=RAM_STORE_FILE, RAM_WIDTH="16")
test_ram.add_config(name='16', generics=generics_16)
generics_32    =     dict(RAM_STORE_FILE=RAM_STORE_FILE, RAM_WIDTH="32")
test_ram.add_config(name='32', generics=generics_32)

vu.set_compile_option("ghdl.a_flags", ["--std=08"])

vu.main(post_run=post_func)
