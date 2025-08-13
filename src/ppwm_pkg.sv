// SPDX-FileCopyrightText: © 2025 XXX Authors
// SPDX-License-Identifier: Apache-2.0

package ppwm_pkg;

  typedef enum logic [2:0] {
    CMD_CTRL   = 3'b000,  // FSM control
    CMD_SET    = 3'b001,  // Set starting value
    CMD_ARITH  = 3'b010,  // Arithmetic (signed immediate for add and sub)
    CMD_SHIFT  = 3'b011,  // Shift (function for direction)
    CMD_RSRV   = 3'b100,  // Future use
    CMD_JUMP   = 3'b101,  // Jump, signed offset
    CMD_CMP    = 3'b110,  // Compare, global counter, PWM, REG
    CMD_BRANCH = 3'b111   // Branch if condition is met
  } command_e;

  typedef enum logic {
    TRGT_PWM = 1'b0,  // Target is PWM value
    TRGT_REG = 1'b1   // Target is register
  } target_e;

  typedef enum logic [1:0] {
    CMP_GCNT_PWM = 2'b00,
    CMP_GCNT_REG = 2'b01,
    CMP_PWM_REG  = 2'b10
  } cmp_args_e;

endpackage
