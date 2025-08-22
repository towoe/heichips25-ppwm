# SPDX-FileCopyrightText: © 2025 XXX Authors
# SPDX-License-Identifier: Apache-2.0

import os
import sys
from pathlib import Path
import importlib.util

import cocotb
from cocotb.clock import Clock
from cocotb.runner import get_runner
from cocotb.triggers import Timer, ClockCycles, RisingEdge

# ------------------------------
# Import the PPWM testbench from the submodule
#
# Needs special handling due to the dash in the path
# ------------------------------
this_path = Path(__file__).resolve().parent
ppwm_tb_path = this_path.parent / "submodules/heichips25-ppwm/tb/testbench.py"

spec = importlib.util.spec_from_file_location("ppwm_tb", ppwm_tb_path)
ppwm_tb = importlib.util.module_from_spec(spec)
spec.loader.exec_module(ppwm_tb)


@cocotb.test()
async def compare_wrapper_vs_gold(dut):
    """Testing the PWM output behavior."""

    # Create a clock with a period of 10ns = 100MHz
    clock = Clock(dut.clk, 10, "ns")
    await cocotb.start(clock.start())

    dut.ena.value = 0  # Enable PPWM, disable SDR
    dut.ui_in.value = 0
    dut.uio_in.value = 0

    # Reset the designs for 100ns
    dut.rst_n.value = 0
    await Timer(100, "ns")
    dut.rst_n.value = 1
    await Timer(100, "ns")

    cocotb.start_soon(checker(dut))

    await exec_ppwm_test(dut)

    dut.ena.value = 1  # Disable PPWM, enable SDR

    await exec_sdr_test(dut)


@cocotb.test()
async def exec_ppwm_test(dut):
    """Execute the test for the ppwm module."""
    # Set PPWM-specific signals
    dut.ena.value = 0  # PPWM expects ena=0
    dut.ui_in.value = 0
    dut.uio_in.value = 0

    # Call the extracted test sequence function from PPWM testbench
    await ppwm_tb.pwm_test(dut)


async def exec_sdr_test(dut):
    """Execute the test for the sdr module."""
    await apply_sdr_inputs(0, 2, 0, 2, dut)
    await ClockCycles(dut.clk, 1)
    await apply_sdr_inputs(0, 2, 0, 2, dut)
    await ClockCycles(dut.clk, 1)
    await apply_sdr_inputs(0, 2, 0, 2, dut)
    await ClockCycles(dut.clk, 1)
    await apply_sdr_inputs(0, 2, 0, 2, dut)
    await ClockCycles(dut.clk, 1)
    await apply_sdr_inputs(0, 2, 0, 2, dut)
    await ClockCycles(dut.clk, 1)
    await apply_sdr_inputs(0, 0, 0, 0, dut)

    # Wait for 10 clock cycles
    await ClockCycles(dut.clk, 10)

    # Enable the counter
    dut.ui_in.value = 1

    # Wait for 10 clock cycles
    await ClockCycles(dut.clk, 10)


async def apply_sdr_inputs(I1, Q1, I2, Q2, dut):
    """Apply the test stimuli to the sdr module."""
    dut.heichips25_tiny_wrapper_i.ui_in.value = Q1 << 4 | I1
    dut.heichips25_tiny_wrapper_i.uio_in.value = Q2 << 4 | I2
    await ClockCycles(dut.clk, 1)


async def check_wrapper_vs_dut_values(wrapper_value, project_value, project_name):
    """Check the wrapper output values against the dut output values."""
    assert wrapper_value == project_value, (
        f"Mismatch: wrapper={wrapper_value} {project_name}={project_value}"
    )


async def check_wrapper_vs_project_all_outputs(dut, project, project_name):
    """Wrap the checks for all outputs."""
    await check_wrapper_vs_dut_values(
        dut.heichips25_tiny_wrapper_i.uo_out.value, project.uo_out.value, project_name
    )
    await check_wrapper_vs_dut_values(
        dut.heichips25_tiny_wrapper_i.uio_out.value, project.uio_out.value, project_name
    )
    await check_wrapper_vs_dut_values(
        dut.heichips25_tiny_wrapper_i.uio_oe.value, project.uio_oe.value, project_name
    )


async def checker(dut):
    """Asynchronous checker that compares wrapper vs. standalone outputs."""
    while True:
        await RisingEdge(dut.clk)

        # Only check when ena is asserted
        if not dut.ena.value:
            await check_wrapper_vs_project_all_outputs(dut, dut.ppwm_i, "PPWM")
        else:
            await check_wrapper_vs_project_all_outputs(dut, dut.sdr_i, "SDR")


if __name__ == "__main__":
    sim = os.getenv("SIM", "icarus")
    pdk_root = os.getenv("PDK_ROOT", "~/.ciel")
    pdk = os.getenv("PDK", "ihp-sg13g2")
    scl = os.getenv("SCL", "sg13g2_stdcell")
    gl = os.getenv("GL", False)

    testbench_path = Path(__file__).resolve().parent
    sources = []
    defines = {}

    MACRO_NL = testbench_path / "../macro/nl/heichips25_tiny_wrapper.nl.v"

    if gl:
        if not MACRO_NL.exists():
            print(
                f"The macro netlist {MACRO_NL} does not exist. Did you implement the macro?"
            )
            sys.exit(0)

        sources.append(
            Path(pdk_root).expanduser()
            / pdk
            / "libs.ref"
            / scl
            / "verilog"
            / f"{scl}.v"
        )
        sources.append(MACRO_NL)
        defines = {"FUNCTIONAL": True, "UNIT_DELAY": "#0"}
    else:
        sources.extend(list(testbench_path.glob("../src/*")))
        sources.extend(list(testbench_path.glob("../submodules/heichips25-ppwm/src/*")))
        sources.extend(
            list(testbench_path.glob("../submodules/heichips25_SDR_new/src/*"))
        )
        sources.extend(list(testbench_path.glob("testbench.sv")))
        defines = {"RTL": True}

    hdl_toplevel = "testbench"

    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel=hdl_toplevel,
        defines=defines,
        timescale=["1ns", "1ps"],
        waves=True,
        build_args=["--trace", "--trace-fst", "--trace-structs"]
        if sim == "verilator"
        else ["-gno-specify"],
    )

    runner.test(
        hdl_toplevel=hdl_toplevel,
        test_module="testbench,",
        timescale=["1ns", "1ps"],
        waves=True,
        plusargs=["--trace-file", f"{hdl_toplevel}.fst"] if sim == "verilator" else [],
    )
