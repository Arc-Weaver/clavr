GHDL     := ghdl
STD      := --std=08
WORKDIR  := work
VHDLDIR  := ../vhdl/Example.Project.topEntity

SRCS := $(VHDLDIR)/avr_soc_types.vhdl \
        $(VHDLDIR)/avr_soc.vhdl \
        tb_avr_soc.vhdl

TOP := tb_avr_soc

.PHONY: all sim clean

all: sim

# Compile all VHDL sources into the work library
work/work-obj08.cf: $(SRCS)
	@mkdir -p $(WORKDIR)
	$(GHDL) -a $(STD) --workdir=$(WORKDIR) $(SRCS)

# Elaborate the top entity
$(WORKDIR)/$(TOP): work/work-obj08.cf
	$(GHDL) -e $(STD) --workdir=$(WORKDIR) --work=work $(TOP)

# Run simulation; optionally emit a VCD with: make sim VCD=1
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
