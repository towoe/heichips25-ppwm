all: macro copy-final

PDK_ROOT ?= ~/.ciel
PDK ?= ihp-sg13g2

RUN_TAG = $(shell ls librelane/runs/ -1 | tail -n 1)

# Macro - LibreLane

macro:
	cd librelane; librelane config.yaml --pdk $(PDK)
.PHONY: macro

macro-openroad:
	cd librelane; librelane config.yaml --pdk $(PDK) --last-run --flow OpenInOpenROAD
.PHONY: macro

macro-klayout:
	cd librelane; librelane config.yaml --pdk $(PDK) --last-run --flow OpenInKLayout
.PHONY: macro

copy-macro:
	mkdir -p macro/
	rm -rf macro/*
	cp -r librelane/runs/${RUN_TAG}/final/* macro/
.PHONY: copy-macro

# Simulation & Verification

sim:
	cd tb; python3 testbench.py
.PHONY: sim

sim-gl:
	cd tb; GL=1 python3 testbench.py
.PHONY: sim-gl

# FPGA

synth-ulx3s: ulx3s.json

build-ulx3s: ulx3s.bit

upload-ulx3s: ulx3s.bit
	openFPGALoader --board=ulx3s -f ulx3s.bit

ulx3s.json: $(RTL) $(FPGA_ULX3S)
	yosys -l $(basename $@)-yosys.log -DSYNTHESIS -DULX3S -DMODE_800x600 -p 'synth_ecp5 -top ulx3s_top -json $@' $(RTL) $(FPGA_ULX3S)

ulx3s.config: ulx3s.json fpga/constraints/ulx3s_v20.lpf
	nextpnr-ecp5 --85k --json $< \
		--lpf fpga/constraints/ulx3s_v20.lpf \
		--package CABGA381 \
		--textcfg $@

ulx3s.bit: ulx3s.config
	ecppack $< $@ --compress

clean:
	rm -f *.vvp *.vcd
	rm -f ulx3s.json ulx3s.config ulx3s.bit ulx3s-yosys.log

.PHONY: clean sim-icarus sim-verilator sim-cocotb sprites
