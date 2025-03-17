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
        if key == "MEM.tb_neorv32_rom_wishbone.8.partial_test": # Copy the output csv and the wave in vcd to known path
            copyfile(
                str(Path(item.path) / "log.csv"),
                str(out_dir_csv / "tb_neorv32_ROM_wishbone_partial_8.csv"),
            )
            copyfile(
                str(Path(item.path) / "ghdl" / "wave.vcd"),
                str(out_dir_wave / "wave_neorv32_ROM_wishbone_partial_8.vcd"),
            )
        elif key == "MEM.tb_neorv32_rom_wishbone.16.partial_test": # Copy the output csv and the wave in vcd to known path
            copyfile(
                str(Path(item.path) / "log.csv"),
                str(out_dir_csv / "tb_neorv32_ROM_wishbone_partial_16.csv"),
            )
            copyfile(
                str(Path(item.path) / "ghdl" / "wave.vcd"),
                str(out_dir_wave / "wave_neorv32_ROM_wishbone_partial_16.vcd"),
            )
        elif key == "MEM.tb_neorv32_rom_wishbone.32.partial_test": # Copy the output csv and the wave in vcd to known path
            copyfile(
                str(Path(item.path) / "log.csv"),
                str(out_dir_csv / "tb_neorv32_ROM_wishbone_partial_32.csv"),
            )
            copyfile(
                str(Path(item.path) / "ghdl" / "wave.vcd"),
                str(out_dir_wave / "wave_neorv32_ROM_wishbone_partial_32.vcd"),
            )
        elif key == "MEM.tb_neorv32_rom_wishbone.8.read_all_test": # Copy the output csv and the wave in vcd to known path
            copyfile(
                str(Path(item.path) / "log.csv"),
                str(out_dir_csv / "tb_neorv32_ROM_wishbone_all_8.csv"),
            )
            copyfile(
                str(Path(item.path) / "ghdl" / "wave.vcd"),
                str(out_dir_wave / "wave_neorv32_ROM_wishbone_all_8.vcd"),
            )
        elif key == "MEM.tb_neorv32_rom_wishbone.16.read_all_test": # Copy the output csv; Don't copy the wave because it takes up too much space
            copyfile(
                str(Path(item.path) / "log.csv"),
                str(out_dir_csv / "tb_neorv32_ROM_wishbone_all_16.csv"),
            )
        elif key == "MEM.tb_neorv32_rom_wishbone.32.read_all_test": # Copy the output csv; Don't copy the wave because it takes up too much space
            copyfile(
                str(Path(item.path) / "log.csv"),
                str(out_dir_csv / "tb_neorv32_ROM_wishbone_all_32.csv"),
            )

vu = VUnit.from_argv()
vu.add_vhdl_builtins()
vu.add_verification_components()
vu.enable_location_preprocessing()

ROOT = Path(__file__).parent

MEM = vu.add_library("MEM")
MEM.add_source_files([
    ROOT /                              "tb_neorv32_ROM_wishbone.vhd",
    ROOT /                              "../../../uart_rx.simple.vhd",
    ROOT /                      "../../../../rtl/MEM/MEM_package.vhd",
    ROOT /                          "../../../../rtl/MEM/ROM/ROM.vhd",
    ROOT /        "../../../../rtl/MEM/ROM/wishbone/ROM_wishbone.vhd",
    ROOT / "../../../../rtl/MEM/ROM/neorv32/neorv32_ROM_wishbone.vhd",
    ROOT /        "../../../../neorv32-setups/neorv32/rtl/core/*.vhd", 
])

NEORV32 = vu.add_library("neorv32")
NEORV32.add_source_files([
    ROOT /        "../../../../neorv32-setups/neorv32/rtl/core/*.vhd", 
])

ROM_PATH      = [str(ROOT)+"/../../../../data/ROM-sim/"]
ROM_LOAD_FILE = ", ".join(map(str, ROM_PATH))
testbench     = MEM.entity("tb_neorv32_ROM_wishbone")
partial_test  = testbench.test ("partial_test")
read_all_test = testbench.test("read_all_test")

generics_8    =     dict(ROM_LOAD_FILE=ROM_LOAD_FILE, ROM_WIDTH="8")
partial_test.add_config (name='8', generics=generics_8)
read_all_test.add_config(name='8', generics=generics_8)
generics_16   =     dict(ROM_LOAD_FILE=ROM_LOAD_FILE,ROM_WIDTH="16")
partial_test.add_config (name='16', generics=generics_16)
read_all_test.add_config(name='16', generics=generics_16)
generics_32   =     dict(ROM_LOAD_FILE=ROM_LOAD_FILE,ROM_WIDTH="32")
partial_test.add_config (name='32', generics=generics_32)
read_all_test.add_config(name='32', generics=generics_32)

vu.set_compile_option("ghdl.a_flags", ["--std=08"])

vu.main(post_run=post_func)
