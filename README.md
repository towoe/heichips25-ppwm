# HeiChips 2025 Hackathon Template

This repository is the submission template for the HeiChips 2025 Hackathon.

Please implement your design using this template as basis and notify us about it so we can integrate your design into the chip for tapeout. See [Submission](#Submission).

Your design will be connected to a small eFPGA together with all of the other designs. This allows you to configure the eFPGA to route the IOs of your design to the chip IOs, implement additional logic to complement your design, connect several designs together (ask what other teams implement!), and make use of the SRAM.
See the HeiChips 2025 Chip repository for more info: TODO

> [!IMPORTANT]  
> You must rename the top-level of your design to make it unique. It must start with `tt_um_`, for example `tt_um_bestteam4ever`.
> Make sure to update the top-level name throughout the repository.

To ensure easy integration of your design into the chip we provide two different DEF templates which specifies the geometry of you macro and the pin positions.
The first DEF template is used by default and 200um high, the second one is twice as high. If you want to use the second one please talk to use as there are limited slots available.

> [!TIP]
> If you only need a fraction of the small DEF template, please coordinate and merge with another team to make the best possible use of area.

All submitted designs will go on the chip, however a winning team will be selected based on several factors. The exact judgment criteria will be announced before the Hackathon.

TODO Nix installed and cache

## Verification

To verify your design implement a testbench with [cocotb](https://www.cocotb.org/) and, as the underlying simulator, Icarus Verilog or Verilator.

### Setup

Enable a shell using Nix with both simulators and a waveform viewer:

```
nix shell nixpkgs#{iverilog,verilator,gtkwave,surfer}
```

Next, create a virtual environment if not already done:

```
python3 -m venv heichips-venv
```

Enable the virtual environment:

```
source heichips-venv/bin/activate
```

And install cocotb:

```
pip3 install cocotb==2.0.0b
```

> [!NOTE]  
> cocotb 2.0.0 will soon be released! 🥳

### Run the Testbench

```
python3 tb/testbench.py 
```

make simulate

The waveforms are stored under `tb/sim_build/waveforms.fst`.

By default Icarus Verilog is used as simulator. To use Verilator, simply set `export SIM=verilator` and run the testbench again.

You can view them using, e.g., GTKWave:

```
gtkwave tb/sim_build/waveforms.fst
```

Make sure to update the testbench for your design.

## Emulation on an FPGA

For designs that use VGA output

Enable an environment using Nix with both simulators:

```
nix shell nixpkgs#{yosys,nextpnr,icestorm,trellis,openfpgaloader}
```

## Physical Implementation using LibreLane

Enable a shell with LibreLane (`ihp` branch):

```
nix shell github:librelane/librelane/ihp
```

### Implementation

Inside the `librelane/` directory:

```
export ~/.ciel && export PDK=ihp-sg13g2
```

```
librelane config.yaml --manual-pdk
```

### View the Design

Open the design in the OpenROAD GUI:

```
librelane config.yaml --last-run --flow OpenInOpenROAD
```

View the layout of the design:

```
librelane config.yaml --last-run --flow OpenInKLayout
```

## Submission

In order to submit your design for integration into the HeiChips 2025 Chip, please open an issue at the following repository: TODO

The issue should contain the following information:

- The name of the group
- The link to your template repository

Your template repository needs to contain the final macro.

Checklist:

- [ ] The top-level has a unique name starting with `tt_um_`.
- [ ] The design is verified and tested.
- [ ] The macro is stored under `final/`.
- [ ] `TopMetal2` in the macro is empty (for integration).
- [ ] The macro is DRC clean (minimal DRC set without fill checks).

## License

The code in this repository is licensed under Apache 2.0.