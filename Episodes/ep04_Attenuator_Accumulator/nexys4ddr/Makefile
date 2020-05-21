# Specify install location of the Xilinx Vivado tool
XILINX_DIR = /opt/Xilinx/Vivado/2019.2

# Add source files here as the project grows.
SRC_DIR = ../src
SRC    += $(SRC_DIR)/saturated_sum_unsigned.vhd
SRC    += $(SRC_DIR)/saturated_sum_signed.vhd
SRC    += $(SRC_DIR)/accumulator.vhd
SRC    += $(SRC_DIR)/rom_freq.vhd
SRC    += $(SRC_DIR)/calc_freq.vhd
SRC    += $(SRC_DIR)/rom_logsin.vhd
SRC    += $(SRC_DIR)/rom_exp.vhd
SRC    += $(SRC_DIR)/float2fixed.vhd
SRC    += $(SRC_DIR)/calc_sine.vhd
SRC    += $(SRC_DIR)/ym2151.vhd

# These are specific for the Nexys4DDR board.
SRC    += nexys4ddr.vhd
SRC    += clk_rst.vhd
SRC    += pwm.vhd


#####################################
# Synthesis
#####################################

# Configure the FPGA on the Nexys4DDR board with the generated bit-file
fpga: build/nexys4ddr.bit
	djtgcfg prog -d Nexys4DDR -i 0 --file $<


# Generate the bit-file used to configure the FPGA
build/nexys4ddr.bit: build/nexys4ddr.tcl $(SRC) nexys4ddr.xdc
	bash -c "source $(XILINX_DIR)/settings64.sh ; vivado -mode tcl -source $<"


# Generate the build script used by Vivado
build/nexys4ddr.tcl: Makefile
	mkdir -p build
	echo "# This is a tcl command script for the Vivado tool chain" > $@
	echo "read_vhdl -vhdl2008 { $(SRC)  }" >> $@
	echo "read_xdc nexys4ddr.xdc" >> $@
	echo "synth_design -top nexys4ddr -part xc7a100tcsg324-1 -flatten_hierarchy none" >> $@
	echo "opt_design -directive NoBramPowerOpt" >> $@
	echo "place_design" >> $@
	echo "route_design" >> $@
	echo "write_checkpoint -force build/nexys4ddr.dcp" >> $@
	echo "write_bitstream -force build/nexys4ddr.bit" >> $@
	echo "exit" >> $@


#####################################
# Cleanup
#####################################

clean:
	rm -rf build
	rm -rf vivado*
	rm -rf .Xil
	rm -rf .cache

