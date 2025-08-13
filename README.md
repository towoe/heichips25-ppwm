# HeiChips 2025 Programmable PWM

## Overview

This project aims to create a programmable PWM module.
In this context, "programmable" signifies that the module is initialized with a set of instructions.
These instructions are then executed by its internal state machine, enabling dynamic PWM behavior.
This allows for modifications to the PWM characteristics over time.
A practical application of this would be, for instance, creating a pulsing LED effect.

## Design

The hardware is structured into different blocks:
- memory:
  - serial input for programming
  - program counter to access the instructions
- global counter:
  - provide a long term counter for time resolution in the magnitude of seconds
- execution:
  - state machine to calculate the PWM duty cycle
- pulse width modulation
  - fixed pulse width and adjustable duty cycle

The program allows for 16 different instructions, and is allowed to run for 1024
cycles before the PWM value is sampled by the PWM module.
The program can pause before reaching this cycle limit and can resume in the
next iteration, changing the value over time.

### Instructions

The state machine support 7 different instructions. Some instructions can do
multiple things to make use of remaining bits in one instruction.

- ctrl (nop, wait)
- set
- arith (add, sub)
- shift
- jump
- cmp (global counter high, global counter low, 2 registers)
- branch

Instructions are 7 bit long. The opcode is 3 bit long. One bit is used to
differentiate between two registers. The immediate value is between 2 and 3
bits. Control transfer has access to 4 bits.

### Registers

The execution unit stores 2 values. Both are 10 bit wide, the same width as the
PWM max value.
One register is used to forward the new duty cylce to PWM. The other register
serves to hold user values.

### Memory

The memory is 7 x 16 bits, allowing for 16 instructions.
All 16 locations can be reached by the 4 bit wide control transfer.

### Global counter

The global counter uses 20 bit, make both halves fully accessible by the
comparison operation.

### PWM

The counter for PWM is 10 bit wide. As long as the counter is smaller than the
value receive by the execution unit, the output line is low.

## Program example

```
0b011_0_001  # set pwm 1 # 3
0b011_1_001  # set reg 3 # 3
0b000_1_110  # cmp reg counter
0b0001_111   # branch counter < reg, + 2
0b0010_101   # jump +2
0b001_0_010  # add pwm 1
0b0001_000   # wait
0b1011_101   # jump -5
```


## License

The code in this repository is licensed under Apache 2.0.
