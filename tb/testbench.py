# SPDX-FileCopyrightText: © 2025 XXX Authors
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
    clock = Clock(dut.clk, 10, 'ns')
    await cocotb.start(clock.start())

    dut.ena.value    = 1 # always 1
    dut.ui_in.value  = 0
    dut.uio_in.value = 0

    # Reset the design for 100ns
    dut.rst_n.value = 0
    await Timer(100, 'ns')
    dut.rst_n.value = 1
    await Timer(100, 'ns')

    # Initialize memory with program instructions (6-bit values)
    program = [
        0b010001,  # Address 0: set, pwm, 1
        0b010010,  # Address 1: add, pwm, 1
        0b110011,  # Address 2: shift, pwm, left, 1
        0b110011,  # Address 3: shift, pwm, left, 1
        0b110011,  # Address 4: shift, pwm, left, 1
        0b101101,  # Jmp back

        # Add more instructions as needed...
    ]

    # Fill remaining addresses with zeros
    program.extend([0b000000] * (32 - len(program)))

    # Load program into memory
    await load_program_to_memory(dut, program)

    # With 10-bit counter and cmp_value=512, PWM should be high for first 512 cycles
    # and low for remaining 512 cycles (50% duty cycle)

    await ClockCycles(dut.clk, 2)

    # Wait for half the period (512 cycles)
    await ClockCycles(dut.clk, 512)

    # Print the current clock cycle
    # assert dut.uo_out[0].value == 1, "PWM should be high during second half of period!"

    # Wait for another half period to complete the cycle
    await ClockCycles(dut.clk, 512)

    # Should be high again at start of new period
    # assert dut.uo_out[0].value[0] == 0, "PWM should be low again at start of new period!"


    await ClockCycles(dut.clk, 10)

async def load_program_to_memory(dut, program):
    """Load a program into the memory module via serial interface."""
    # Send start bit (high)
    dut.ui_in[0].value  = 1
    await ClockCycles(dut.clk, 1)
    for _, instruction in enumerate(program):
        # Send 6 bits of instruction data (LSB first)
        print(f"Loading instruction: {instruction:06b}")
        for bit in range(6):
            dut.ui_in[0].value = (instruction >> bit) & 1
            await ClockCycles(dut.clk, 1)



    # cocotb documentation: https://docs.cocotb.org/en/stable/refcard.html
if __name__ == "__main__":

    sim         = os.getenv("SIM", "verilator")
    pdk_root    = os.getenv("PDK_ROOT", "~/.ciel")
    pdk         = os.getenv("PDK", "ihp-sg13g2")
    scl         = os.getenv("SCL", "sg13g2_stdcell")
    gl          = os.getenv("GL", False)

    testbench_path = Path(__file__).resolve().parent
    sources = []#[testbench_path / 'testbench.sv']
    defines = {}

    MACRO_NL = testbench_path / '../macro/nl/heichips25_ppwm.nl.v'

    if gl:
        if not MACRO_NL.exists():
            print(f"The macro netlist {MACRO_NL} does not exist. Did you implement the macro?")
            sys.exit(0)
    
        sources.append(Path(pdk_root).expanduser() / pdk / "libs.ref" / scl / "verilog" / f"{scl}.v" )
        sources.append(MACRO_NL)
        defines = {'FUNCTIONAL': True, 'UNIT_DELAY': '#0'}
    else:
        sources.append(testbench_path / '../src/ppwm.sv')
        sources.append(testbench_path / '../src/counter.sv')
        sources.append(testbench_path / '../src/mem.sv')
        sources.append(testbench_path / '../src/pwm.sv')
        sources.append(testbench_path / '../src/serial_in.sv')
        sources.append(testbench_path / '../src/heichips25_ppwm.sv')
        defines = {'RTL': True}

    hdl_toplevel = "heichips25_ppwm"

    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel=hdl_toplevel,
        defines=defines,
        timescale=['1ns', '1ps'],
        waves=True,
        build_args=['--trace', '--trace-fst', '--trace-structs'] if sim == 'verilator' else ['-gno-specify'],
    )

    runner.test(
        hdl_toplevel=hdl_toplevel,
        test_module='testbench,',
        timescale=['1ns', '1ps'],
        waves=True,
        plusargs=['--trace-file', f'{hdl_toplevel}.fst']  if sim == 'verilator' else [],
    )
