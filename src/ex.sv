// SPDX-FileCopyrightText: © 2025 XXX Authors
// SPDX-License-Identifier: Apache-2.0

module ex #(
    parameter int COUNTER_WIDTH = 8,
    parameter int INSTR_WIDTH = 6,
    parameter int PC_WIDTH = 4
) (
    input  logic                     clk,
    input  logic                     rst_n,
    input  logic                     start_i,           // Start of new PWM period
    input  logic [COUNTER_WIDTH-1:0] global_counter_i,  // Upper value of global counter
    input  logic [  INSTR_WIDTH-1:0] instr_i,
    output logic [     PC_WIDTH-1:0] pc_o,
    output logic [COUNTER_WIDTH-1:0] pwm_value_o
);

  import ppwm_pkg::*;

  typedef enum logic [1:0] {
    STATE_IDLE = 2'b00,  // Idle state
    STATE_EXEC = 2'b01   // Executing instruction
  } state_e;
  state_e current_state, next_state;

  // Program counter
  logic [PC_WIDTH-1:0] pc_d, pc_q;
  // Compare flag, set if global counter is smaller
  logic cmp_flag_d, cmp_flag_q;

  command_e command;
  target_e target;
  logic [1:0] immediate;
  assign command = command_e'(instr_i[2:0]);
  assign target = target_e'(instr_i[3]);
  assign immediate = instr_i[5:4];

  // PWM value and register storage
  logic [COUNTER_WIDTH-1:0] pwm_value_d, pwm_value_q;
  logic [COUNTER_WIDTH-1:0] reg_value_d, reg_value_q;

  // Execution control
  always_comb begin
    next_state = current_state;
    pc_d = pc_q;
    cmp_flag_d = cmp_flag_q;

    // Default assignments
    pwm_value_d = pwm_value_q;
    reg_value_d = reg_value_q;

    case (current_state)
      STATE_IDLE: begin
        if (start_i) begin
          next_state = STATE_EXEC;
        end
      end
      STATE_EXEC: begin
        // Last instruction will end exectuion
        // Can be continued by jumping to the first instruction explicitally
        if (pc_q == '1) begin
          next_state = STATE_IDLE;
        end
        pc_d = pc_q + 1;

        case (command)
          CMD_NOP: begin
            // No operation, just continue
          end
          CMD_SET: begin
            if (target == TRGT_REG) begin
              reg_value_d = {8'b0, immediate};
            end else if (target == TRGT_PWM) begin
              pwm_value_d = {8'b0, immediate};
            end
          end
          CMD_ARITH: begin
            if (target == TRGT_REG) begin
              reg_value_d = reg_value_q + {8'b0, immediate};
            end else if (target == TRGT_PWM) begin
              pwm_value_d = pwm_value_q + {8'b0, immediate};
            end
          end
          CMD_SHIFT: begin
            if (target == TRGT_REG) begin
              if (immediate[0]) begin
                reg_value_d = {reg_value_q[COUNTER_WIDTH-2:0], 1'b0};  // Shift left
              end else begin
                reg_value_d = {1'b0, reg_value_q[COUNTER_WIDTH-1:1]};  // Shift right
              end
            end else if (target == TRGT_PWM) begin
              if (immediate[0]) begin
                pwm_value_d = {pwm_value_q[COUNTER_WIDTH-2:0], 1'b0};  // Shift left
              end else begin
                pwm_value_d = {1'b0, pwm_value_q[COUNTER_WIDTH-1:1]};  // Shift right
              end
            end
          end
          CMD_WAIT: begin
            next_state = STATE_IDLE;
          end
          CMD_JUMP: begin
            pc_d = pc_q + {{(PC_WIDTH-3){instr_i[5]}}, instr_i[5:3]};
          end
          CMD_CMP_CNTR: begin
            // Compare global counter with register or PWM value
            if (target == TRGT_REG) begin
              if (global_counter_i < reg_value_q) begin
                cmp_flag_d = 1'b1;
              end
            end else if (target == TRGT_PWM) begin
              if (global_counter_i < pwm_value_q) begin
                cmp_flag_d = 1'b1;
              end
            end
          end
          CMD_BRANCH: begin
            // Branch if condition is met
            if (cmp_flag_q) begin
              pc_d = pc_q + {1'b0, instr_i[5:3]};
            end
          end
          default: begin
          end
        endcase

      end
      default: begin
        next_state = STATE_IDLE;
      end
    endcase
  end

  // State transition logic
  always_ff @(posedge clk) begin
    if (!rst_n) begin
      current_state <= STATE_IDLE;
      pc_q <= '0;
      cmp_flag_q <= 1'b0;
      pwm_value_q <= '0;
      reg_value_q <= '0;
    end else begin
      current_state <= next_state;
      pc_q <= pc_d;
      cmp_flag_q <= cmp_flag_d;
      pwm_value_q <= pwm_value_d;
      reg_value_q <= reg_value_d;
    end
  end

  assign pc_o = pc_q;
  assign pwm_value_o = pwm_value_q;

endmodule
