# Author:  Michael Jørgensen
# License: Public domain; do with it what you like :-)
# Project: YM2151 implementation
#
# Description: Makefile for simulating the design.

# Add source files here as the project grows.
SRC_DIR = ../src
SRC    += $(SRC_DIR)/ring_buffer.vhd
SRC    += $(SRC_DIR)/configurator.vhd
SRC    += $(SRC_DIR)/saturated_sum_unsigned.vhd
SRC    += $(SRC_DIR)/saturated_sum_signed.vhd
SRC    += $(SRC_DIR)/envelope_generator.vhd
SRC    += $(SRC_DIR)/accumulator.vhd
SRC    += $(SRC_DIR)/pg/rom_freq.vhd
SRC    += $(SRC_DIR)/pg/calc_freq.vhd
SRC    += $(SRC_DIR)/phase_generator.vhd
SRC    += $(SRC_DIR)/op/rom_logsin.vhd
SRC    += $(SRC_DIR)/op/rom_exp.vhd
SRC    += $(SRC_DIR)/op/float2fixed.vhd
SRC    += $(SRC_DIR)/operator.vhd
SRC    += $(SRC_DIR)/ym2151.vhd

# These are testbench related.
TB      = ym2151_tb
TB_SRC += wav2file.vhd
TB_SRC += $(TB).vhd
FST     = build/$(TB).fst
SAVE    = $(TB).gtkw


#####################################
# Simulation.
#####################################

.PHONY: show
show: $(FST)
	gtkwave $(FST) $(SAVE)

$(FST): $(SRC) $(TB_SRC) build
	ghdl -i --std=08 --workdir=build $(SRC) $(TB_SRC)
	ghdl -m --std=08 --workdir=build $(TB)
	ghdl -r --std=08 --workdir=build $(TB) --fst=$(FST)

build:
	mkdir -p build


#####################################
# Cleanup
#####################################

clean:
	rm -rf build
	rm -rf output.wav

