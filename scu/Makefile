
VHDL_SOURCES= \
	impl/constants.vhd \
	impl/common.vhd \
	impl/reg.vhd \
	impl/addr_decoder.vhd \
	impl/boot_vector.vhd \
	impl/isab/isa_addr_decoder.vhd \
	impl/isab/isab.vhd \
	impl/ideb/ideb.vhd \
	impl/fmcb/fmcb.vhd \
	impl/mcb/addr_mux.vhd \
	impl/mcb/cas_generator.vhd \
	impl/mcb/ras_generator.vhd \
	impl/mcb/mcb.vhd \
	impl/mcb/abr.vhd \
	impl/pwb/pwb.vhd \
	impl/top.vhd \
	sim/dram.vhd \
	sim/dram_module.vhd \
	sim/flash.vhd \
	sim/mx8315.vhd \
	sim/testbench.vhd

#	impl/romc.vhd \
#	impl/addrmux.vhd \
#	impl/rasgen.vhd \
#	impl/casgen.vhd \
#	impl/memc.vhd \

TOPLEVEL_LANG=vhdl
TOPLEVEL=testbench
MODULE=sim.sim

SIM=ghdl
COMPILE_ARGS=-fsynopsys -frelaxed
EXTRA_ARGS=--std=08
SIM_ARGS=--wave=wave.ghw
GHDL_TIME_RESOLUTION=ps

include $(shell cocotb-config --makefiles)/Makefile.sim
