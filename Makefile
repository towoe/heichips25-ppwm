all: macro copy-final

PDK_ROOT ?= ~/.ciel
PDK ?= ihp-sg13g2

RUN_TAG = $(shell ls librelane/runs/ -1 | tail -n 1)
TOP = decoder

macro:
	cd librelane; PDK_ROOT=$(PDK_ROOT) PDK=$(PDK) librelane config.yaml --manual-pdk
.phony: macro

macro-openroad:
	cd librelane; PDK_ROOT=$(PDK_ROOT) PDK=$(PDK) librelane config.yaml --manual-pdk --last-run --flow OpenInOpenROAD
.phony: macro

macro-klayout:
	cd librelane; PDK_ROOT=$(PDK_ROOT) PDK=$(PDK) librelane config.yaml --manual-pdk --last-run --flow OpenInKLayout
.phony: macro

copy-final:
	mkdir -p final/
	rm -rf final/*
	cp -r librelane/runs/${RUN_TAG}/final/* final/
.phony: copy-final
