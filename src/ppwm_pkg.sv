// SPDX-FileCopyrightText: © 2025 Tobias Wölfel
// SPDX-License-Identifier: Apache-2.0

package ppwm_pkg;

  // All instructions are 7 bits wide
  // All instructions use 3 bits for the opcode
  //   [xxxx ccc] with c defined in `command_e`
  // They differentiate on how they use the upper 4 bits
  // - CMD_CTRL
  //   [ffff 000]   f: 4 bits for FSM control
  //
  // - CMD_SET
  //   [III t 001]
  // - CMD_ARITH
  //   [III t 010]  t: target (0 = PWM, 1 = REG)
  //                I: 3 immediate bits, signed
  // - CMD_SHIFT
  //   [ee d t 011] t: target (0 = PWM, 1 = REG)
  //                d: shift direction (0 = right, 1 = left)
  //                e: shift amount (0 = 1, 1 = 2, 2 = 4, 3 = 8)
  // - CMD_CMP (if a < b, set flag)
  //   [x PPP 110]  P: compare arguments defined in `cmp_args_e`
  //
  // - CMD_JUMP
  //   [OOOO 101]
  // - CMD_BRANCH (compare flag set)
  //   [OOOO 111]   O: signed offset
  //
  // - CMD_MV
  //   [x MMM 100]  M: move arguments defined in `mv_args_e`

  typedef enum logic [2:0] {
    CMD_CTRL   = 3'b000,  // FSM control
    CMD_SET    = 3'b001,  // Set starting value
    CMD_ARITH  = 3'b010,  // Arithmetic (signed immediate for add and sub)
    CMD_SHIFT  = 3'b011,  // Shift (function for direction)
    CMD_MV     = 3'b100,  // Move
    CMD_JUMP   = 3'b101,  // Jump, signed offset
    CMD_CMP    = 3'b110,  // Compare, global counter, PWM, REG
    CMD_BRANCH = 3'b111   // Branch if condition is met
  } command_e;

  typedef enum logic {
    TRGT_PWM = 1'b0,  // Target is PWM value
    TRGT_REG = 1'b1   // Target is register
  } target_e;

  typedef enum logic [2:0] {
    CMP_GCNT_L_PWM = 3'b000,
    CMP_GCNT_H_PWM = 3'b100,
    CMP_GCNT_L_REG = 3'b001,
    CMP_GCNT_H_REG = 3'b101,
    CMP_PWM_REG    = 3'b010
  } cmp_args_e;

  typedef enum logic [2:0] {
    MV_REG_TO_PWM = 3'b000,  // Move register to PWM value
    MV_PWM_TO_REG = 3'b001,  // Move PWM value to register
    MV_GCNT_L_REG = 3'b010,  // Move global counter to register
    MV_GCNT_H_REG = 3'b011,  // Move global counter high to register
    MV_GCNT_L_PWM = 3'b100,  // Move global counter to PWM value
    MV_GCNT_H_PWM = 3'b101   // Move global counter high to PWM value
  } mv_args_e;

endpackage
