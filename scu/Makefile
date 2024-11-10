
VHDL_SOURCES= \
	impl/constants.vhd \
	impl/common.vhd \
	impl/reg.vhd \
	impl/addr_decoder.vhd \
	impl/cpu_interface.vhd \
	impl/dram/addr_mux.vhd \
	impl/dram/cas_generator.vhd \
	impl/dram/ras_generator.vhd \
	impl/dram_controller.vhd \
	impl/flash_controller.vhd \
	impl/irq_controller.vhd \
	impl/isa_controller.vhd \
	impl/power_controller.vhd \
	impl/timer/timer_channel.vhd \
	impl/timer.vhd \
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
