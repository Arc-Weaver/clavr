GHDL    := ghdl
STD     := --std=08
WORKDIR := work
BUILDDIR := ../build/avr_soc

# Compile order: leaves first, top last, then testbench.
SRCS := \
    $(BUILDDIR)/isacle_ram_32x8.vhd    \
    $(BUILDDIR)/isacle_ram_2048x8.vhd  \
    $(BUILDDIR)/isacle_ram_16384x8.vhd \
    $(BUILDDIR)/isacle_rom_16x16.vhd   \
    $(BUILDDIR)/uart0.vhd              \
    $(BUILDDIR)/timer0.vhd             \
    $(BUILDDIR)/gpio0.vhd              \
    $(BUILDDIR)/ram0.vhd               \
    $(BUILDDIR)/cpu.vhd                \
    $(BUILDDIR)/databus.vhd            \
    $(BUILDDIR)/avr_soc.vhd            \
    tb_avr_soc.vhdl

TOP := tb_avr_soc

.PHONY: all sim clean

all: sim

$(WORKDIR)/work-obj08.cf: $(SRCS)
	@mkdir -p $(WORKDIR)
	$(GHDL) -a $(STD) --workdir=$(WORKDIR) $(SRCS)

$(WORKDIR)/$(TOP): $(WORKDIR)/work-obj08.cf
	$(GHDL) -e $(STD) --workdir=$(WORKDIR) --work=work $(TOP)

RUNOPTS := --ieee-asserts=disable

sim: $(WORKDIR)/$(TOP)
ifdef VCD
	$(GHDL) -r $(STD) --workdir=$(WORKDIR) --work=work $(TOP) $(RUNOPTS) --vcd=$(WORKDIR)/sim.vcd
	@echo "Waveform written to $(WORKDIR)/sim.vcd"
else
	$(GHDL) -r $(STD) --workdir=$(WORKDIR) --work=work $(TOP) $(RUNOPTS)
endif

clean:
	rm -rf $(WORKDIR)
