# Makefile for simulating the design

# Add source files here as the project grows.
SRC_DIR = ../src
SRC    += $(SRC_DIR)/rom_freq.vhd
SRC    += $(SRC_DIR)/calc_freq.vhd
SRC    += $(SRC_DIR)/rom_logsin.vhd
SRC    += $(SRC_DIR)/rom_exp.vhd
SRC    += $(SRC_DIR)/float2fixed.vhd
SRC    += $(SRC_DIR)/calc_sine.vhd
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

show: $(FST)
	gtkwave $(FST) $(SAVE)

$(FST): $(SRC) $(TB_SRC) build
	ghdl -i --ieee=synopsys --std=08 --workdir=build --work=work $(SRC) $(TB_SRC)
	ghdl -m --ieee=synopsys --std=08 --workdir=build -frelaxed-rules $(TB)
	ghdl -r $(TB) --assert-level=error --fst=$(FST)

build:
	mkdir -p build


#####################################
# Cleanup
#####################################

clean:
	rm -rf build
	rm -rf *.o
	rm -rf $(TB)
	rm -rf music.wav

