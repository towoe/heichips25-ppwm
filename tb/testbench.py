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

# Initialize memory with program instructions
# 16 x 7-bit instructions
PROGRAM = [
    0b011_0_001,  # 0 set pwm 3
    0b011_1_001,  # 1 set reg 3
    0b0_001_110,  # 2 cmp gcntl < reg
    0b_0010_111,  # 3 branch #5
    0b_0010_101,  # 4 jump #6
    0b001_0_010,  # 5 add pwm 1
    0b_0001_000,  # 6 wait
    0b_1010_101,  # 7 jump #2
    0b0000000,  # ctrl nop
    0b0000000,  # ctrl nop
    0b0000000,  # ctrl nop
    0b0000000,  # ctrl nop
    0b0000000,  # ctrl nop
    0b0000000,  # ctrl nop
    0b0000000,  # ctrl nop
    0b0000000,  # ctrl nop
]

PROGRAM_TEST_MV = [
    0b011_1_001,  # 0 set reg, 3
    0b11_1_1_011,  # 1 shift reg left
    0b00_1_1_011,  # 2 shift reg left
    0b00_1_1_011,  # 3 shift reg left
    0b0_001_110,  # 4 cmp global counter < reg
    0b0011_111,  # 5 branch #8
    0b0_000_100,  # 6 mv reg to pwm
    0b0010_101,  # 7 jump +2
    0b0_100_100,  # 8 mv global counter l to pwm
    0b0001_000,  # 9 ctrl wait
    0b1010_101,  # a jump #4
    0b0000000,  # b
    0b0000000,  # c
    0b0000000,  # d
    0b0000000,  # e
    0b0000000,  # f
]


@cocotb.test()
async def compare_wrapper_vs_gold(dut):
    """Testing the PWM output behavior."""

    # Create a clock with a period of 10ns = 100MHz
    clock = Clock(dut.clk, 10, "ns")
    await cocotb.start(clock.start())

    dut.ena.value = 0  # Enable PPWM, disable SDR
    dut.ui_in.value = 0
    dut.uio_in.value = 0

    # Reset the design for 100ns
    dut.rst_n.value = 0
    await Timer(100, "ns")
    dut.rst_n.value = 1
    await Timer(100, "ns")

    cocotb.start_soon(checker(dut))

    await exec_ppwm_test(dut, PROGRAM)

    dut.ena.value = 1  # Disable PPWM, enable SDR
    await exec_ppwm_test(dut, PROGRAM_TEST_MV)


async def exec_ppwm_test(dut, program):
    """Execute the test for the ppwm module."""
    # Load program into memory
    await ClockCycles(dut.clk, 1)
    await ppwm_tb.load_program_to_memory(dut, PROGRAM)
    await ClockCycles(dut.clk, 2)
    # Wait for another half period to complete the cycle
    await ClockCycles(dut.clk, 2048 * 24)

    # Reset the design for 100ns
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 1)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 1)
    # Load program into memory
    await ppwm_tb.load_program_to_memory(dut, PROGRAM_TEST_MV)
    await ClockCycles(dut.clk, 2)
    # Wait for another half period to complete the cycle
    await ClockCycles(dut.clk, 2048 * 24)


async def checker(dut):
    """Asynchronous checker that compares wrapper vs. standalone outputs."""
    while True:
        await RisingEdge(dut.clk)

        # Only check when ena is asserted
        if not dut.ena.value:
            assert dut.tiny_wrapper_i.uo_out.value == dut.ppwm_i.uo_out.value, (
                f"Mismatch: wrapper={dut.tiny_wrapper_i.uo_out.value} ppwm={dut.ppwm_i.uo_out.value}"
            )
        # FIXME: check against the SDR instance once it is fixed
        else:
            gold = "zzzzzzzz"
            assert dut.tiny_wrapper_i.uo_out.value == gold, (
                f"Mismatch: wrapper={dut.tiny_wrapper_i.uo_out.value} gold={gold}"
            )
            # assert dut.tiny_wrapper_i.uo_out.value == dut.sdr_i.uo_out.value, (
            #     f"Mismatch: wrapper={dut.tiny_wrapper_i.uo_out.value} sdr={dut.sdr_i.uo_out.value}"
            # )


if __name__ == "__main__":
    sim = os.getenv("SIM", "icarus")
    pdk_root = os.getenv("PDK_ROOT", "~/.ciel")
    pdk = os.getenv("PDK", "ihp-sg13g2")
    scl = os.getenv("SCL", "sg13g2_stdcell")
    gl = os.getenv("GL", False)

    testbench_path = Path(__file__).resolve().parent
    sources = []
    defines = {}

    MACRO_NL = testbench_path / "../macro/nl/tiny_wrapper.nl.v"

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
