# SPDX-FileCopyrightText: © 2025 Tobias Wölfel
# SPDX-License-Identifier: Apache-2.0

import os
import sys
from pathlib import Path
import cocotb
from cocotb.clock import Clock
from cocotb.runner import get_runner
from cocotb.triggers import Timer, ClockCycles


async def run_pwm_test_sequence(dut, programs=None):
    """Run the PWM test sequence with given programs or defaults."""
    if programs is None:
        programs = [
            [  # Default program 1
                0b011_0_001,  # 0 set pwm 3
                0b011_1_001,  # 1 set reg 3
                0b0_001_110,  # 2 cmp gcntl < reg
                0b_0010_111,  # 3 branch #5
                0b_0010_101,  # 4 jump #6
                0b001_0_010,  # 5 add pwm 1
                0b_0001_000,  # 6 wait
                0b_0011_000,  # 7 ctrl output polarity
                0b_1001_101,  # 8 jump #2
                0b0000000,  # 9 ctrl nop
                0b0000000,  # a ctrl nop
                0b0000000,  # b ctrl nop
                0b0000000,  # c ctrl nop
                0b0000000,  # d ctrl nop
                0b0000000,  # e ctrl nop
                0b0000000,  # f ctrl nop
            ],
            [  # Test MV program
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
        ]

    for i, program in enumerate(programs):
        if i > 0:  # Reset between programs
            dut.rst_n.value = 0
            await program_clk(dut)
            dut.rst_n.value = 1
            await program_clk(dut)

        await load_program_to_memory(dut, program)
        await ClockCycles(dut.clk, 2)
        await ClockCycles(dut.clk, 2048 * 24)


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
    await Timer(100, "ns")
    dut.rst_n.value = 1
    await program_clk(dut)

    # Run the test sequence
    await run_pwm_test_sequence(dut)


async def load_program_to_memory(dut, program):
    """Load a program into the memory module via serial interface."""
    # Send start bit (high)
    dut.ui_in[0].value = 1
    await program_clk(dut)
    for _, instruction in enumerate(program):
        # Send 7 bits of instruction data (LSB first)
        print(f"Loading instruction: {instruction:07b}")
        for bit in range(7):
            dut.ui_in[0].value = (instruction >> bit) & 1
            await program_clk(dut)

    # cocotb documentation: https://docs.cocotb.org/en/stable/refcard.html


async def program_clk(dut):
    dut.ui_in[1].value = 1
    await ClockCycles(dut.clk, 10)
    dut.ui_in[1].value = 0
    await ClockCycles(dut.clk, 10)


if __name__ == "__main__":
    sim = os.getenv("SIM", "icarus")
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
