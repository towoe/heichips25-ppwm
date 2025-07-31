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
.PHONY: macro-openroad

macro-klayout:
	cd librelane; librelane config.yaml --pdk $(PDK) --last-run --flow OpenInKLayout
.PHONY: macro-klayout

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

# FPGA Emulation

## iCE40HX8K

ICE40HX8K_SOURCES = $(wildcard fpga/ice40hx8k/*.sv) $(wildcard src/*.sv)

synth-ice40hx8k: ice40hx8k.json

pnr-ice40hx8k: ice40hx8k.bit

upload-ice40hx8k: ice40hx8k.bit
	openFPGALoader --board=ice40_generic -f ice40hx8k.bit

ice40hx8k.json: $(ICE40HX8K_SOURCES)
	yosys -l $(basename $@)-yosys.log -DSYNTHESIS -DICE40HX8K -p 'synth_ice40 -top ice40hx8k_top -json $@' $^

ice40hx8k.asc: ice40hx8k.json fpga/ice40hx8k/ice40hx8k-evb.pcf
	nextpnr-ice40 --hx8k --json $< \
		--pcf fpga/ice40hx8k/ice40hx8k-evb.pcf \
		--package ct256 \
		--asc $@

ice40hx8k.bit: ice40hx8k.asc
	icepack $< $@

## iCEBreaker

ICEBREAKER_SOURCES = $(wildcard fpga/icebreaker/*.sv) $(wildcard src/*.sv)

synth-icebreaker: icebreaker.json

pnr-icebreaker: icebreaker.bit

upload-icebreaker: icebreaker.bit
	openFPGALoader --board=ice40_generic -f icebreaker.bit

icebreaker.json: $(ICEBREAKER_SOURCES)
	yosys -l $(basename $@)-yosys.log -DSYNTHESIS -DICEBREAKER -p 'synth_ice40 -top icebreaker_top -json $@' $^

icebreaker.asc: icebreaker.json fpga/icebreaker/icebreaker.pcf
	nextpnr-ice40 --up5k --json $< \
		--pcf fpga/icebreaker/icebreaker.pcf \
		--package sg48 \
		--asc $@

icebreaker.bit: icebreaker.asc
	icepack $< $@

## ULX3S

ULX3S_SOURCES = $(wildcard fpga/ulx3s/*.sv) $(wildcard src/*.sv)

synth-ulx3s: ulx3s.json

pnr-ulx3s: ulx3s.bit

upload-ulx3s: ulx3s.bit
	openFPGALoader --board=ulx3s -f ulx3s.bit

ulx3s.json: $(ULX3S_SOURCES)
	yosys -l $(basename $@)-yosys.log -DSYNTHESIS -DULX3S -p 'synth_ecp5 -top ulx3s_top -json $@' $^

ulx3s.config: ulx3s.json fpga/ulx3s/ulx3s_v20.lpf
	nextpnr-ecp5 --85k --json $< \
		--lpf fpga/ulx3s/ulx3s_v20.lpf \
		--package CABGA381 \
		--textcfg $@

ulx3s.bit: ulx3s.config
	ecppack $< $@ --compress

# Common

clean:
	rm -f ice40hx8k.json ice40hx8k.asc ice40hx8k.bit ice40hx8k-yosys.log
	rm -f icebreaker.json icebreaker.asc icebreaker.bit icebreaker-yosys.log
	rm -f ulx3s.json ulx3s.config ulx3s.bit ulx3s-yosys.log

