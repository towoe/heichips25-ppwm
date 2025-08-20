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

add-logo: macro/gds_logo/heichips25_ppwm.gds
.PHONY: add-logo
macro/gds_logo/heichips25_ppwm.gds: macro/gds/heichips25_ppwm.gds logo/gds/logo.gds
	mkdir -p macro/gds_logo
	python3 scripts/insert_logo.py $^ $@

# Simulation & Verification

sim:
	cd tb; python3 testbench.py
.PHONY: sim

sim-gl:
	cd tb; GL=1 python3 testbench.py
.PHONY: sim-gl

# Common

clean:
	rm -f ice40hx8k.json ice40hx8k.asc ice40hx8k.bit ice40hx8k-yosys.log
	rm -f icebreaker.json icebreaker.asc icebreaker.bit icebreaker-yosys.log
	rm -f ulx3s.json ulx3s.config ulx3s.bit ulx3s-yosys.log
	rm -f basys3.json basys3.bin basys3.fasm basys3.frames basys3.bit basys3-yosys.log
	rm -f nano9k.json nano9k.bin nano9k.fasm nano9k.frames nano9k.fs nano9k-yosys.log nano9k_pnr.json
