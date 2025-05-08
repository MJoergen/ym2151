# Author:  Michael Jørgensen
# License: Public domain; do with it what you like :-)
# Project: YM2151 implementation
#
# Description: Makefile for simulating the design.

# Add source files here as the project grows.
SRC_DIR = ../src
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

COV = -Wc,-fprofile-arcs -Wc,-ftest-coverage -Wl,-lgcov


#####################################
# Simulation.
#####################################

.PHONY: default
default: html

.PHONY: show
show: $(FST)
	gtkwave $(FST) $(SAVE)

.PHONY: show_coverage
show_coverage: html
	xdg-open html/index.html

$(FST): $(TB)
	ghdl -r --std=08 --workdir=build $(TB) --fst=$(FST)

$(TB): $(SRC) $(TB_SRC) build
	ghdl -i --std=08 --workdir=build $(SRC) $(TB_SRC)
	ghdl -m --std=08 --workdir=build $(COV) $(TB)

build:
	mkdir -p build

html: $(FST)
	rm -f e~$(TB).gcno
	rm -f e~$(TB).gcda
	rm -rf html
	lcov -c -d . -o $(TB)_gcov.info
	genhtml -o html $(TB)_gcov.info




#####################################
# Cleanup
#####################################

clean:
	rm -rf build
	rm -rf output.wav

