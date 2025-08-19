# SPDX-FileCopyrightText: © 2025 Tobias Wölfel
# SPDX-License-Identifier: Apache-2.0

import os
import sys
from pathlib import Path
import cocotb
from cocotb.clock import Clock
from cocotb.runner import get_runner
from cocotb.triggers import Timer, ClockCycles


@cocotb.test()
async def pwm_test(dut):
    """Testing the PWM output behavior."""

    # Create a clock with a period of 10ns = 100MHz
    clock = Clock(dut.clk, 10, "ns")
    await cocotb.start(clock.start())

    dut.ena.value = 1  # always 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0

    # Reset the design for 100ns
    dut.rst_n.value = 0
    await Timer(100, "ns")
    dut.rst_n.value = 1
    await Timer(100, "ns")

    # Initialize memory with program instructions
    # 16 x 7-bit instructions
    program = [
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
    program_test_mv = [
        0b011_1_001,  # 0 set reg, 3
        0b00_1_1_011,  # 1 shift reg left
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

    # Load program into memory
    await load_program_to_memory(dut, program)
    await ClockCycles(dut.clk, 2)
    # Wait for another half period to complete the cycle
    await ClockCycles(dut.clk, 2048 * 24)

    # Reset the design for 100ns
    dut.rst_n.value = 0
    await Timer(100, "ns")
    dut.rst_n.value = 1
    await Timer(100, "ns")
    # Load program into memory
    await load_program_to_memory(dut, program_test_mv)
    await ClockCycles(dut.clk, 2)
    # Wait for another half period to complete the cycle
    await ClockCycles(dut.clk, 2048 * 24)


async def load_program_to_memory(dut, program):
    """Load a program into the memory module via serial interface."""
    # Send start bit (high)
    dut.ui_in[0].value = 1
    await ClockCycles(dut.clk, 1)
    for _, instruction in enumerate(program):
        # Send 7 bits of instruction data (LSB first)
        print(f"Loading instruction: {instruction:07b}")
        for bit in range(7):
            dut.ui_in[0].value = (instruction >> bit) & 1
            await ClockCycles(dut.clk, 1)

    # cocotb documentation: https://docs.cocotb.org/en/stable/refcard.html


if __name__ == "__main__":
    sim = os.getenv("SIM", "verilator")
    pdk_root = os.getenv("PDK_ROOT", "~/.ciel")
    pdk = os.getenv("PDK", "ihp-sg13g2")
    scl = os.getenv("SCL", "sg13g2_stdcell")
    gl = os.getenv("GL", False)

    testbench_path = Path(__file__).resolve().parent
    sources = []  # [testbench_path / 'testbench.sv']
    defines = {}

    MACRO_NL = testbench_path / "../macro/nl/heichips25_ppwm.nl.v"

    if gl:
        if not MACRO_NL.exists():
            print(
                f"The macro netlist {MACRO_NL} does not exist. Did you implement the macro?"
            )
            sys.exit(0)

        sources.append(
            Path(pdk_root).expanduser() / pdk / "libs.ref" / scl / "verilog" /
            f"{scl}.v")
        sources.append(MACRO_NL)
        defines = {"FUNCTIONAL": True, "UNIT_DELAY": "#0"}
    else:
        sources.append(testbench_path / "../src/ppwm.sv")
        sources.append(testbench_path / "../src/ppwm_pkg.sv")
        sources.append(testbench_path / "../src/counter.sv")
        sources.append(testbench_path / "../src/ex.sv")
        sources.append(testbench_path / "../src/mem.sv")
        sources.append(testbench_path / "../src/pwm.sv")
        sources.append(testbench_path / "../src/heichips25_ppwm.sv")
        defines = {"RTL": True}

    hdl_toplevel = "heichips25_ppwm"

    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel=hdl_toplevel,
        defines=defines,
        timescale=["1ns", "1ps"],
        waves=True,
        build_args=(["--trace", "--trace-fst", "--trace-structs"]
                    if sim == "verilator" else ["-gno-specify"]),
    )

    runner.test(
        hdl_toplevel=hdl_toplevel,
        test_module="testbench,",
        timescale=["1ns", "1ps"],
        waves=True,
        plusargs=["--trace-file", f"{hdl_toplevel}.fst"]
        if sim == "verilator" else [],
    )
