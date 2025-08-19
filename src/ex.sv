// SPDX-FileCopyrightText: © 2025 Tobias Wölfel
// SPDX-License-Identifier: Apache-2.0

module ex #(
    parameter int COUNTER_WIDTH = 10,
    parameter int GLOBAL_COUNTER_WIDTH = 20,
    parameter int INSTR_WIDTH = 7,
    parameter int PC_WIDTH = 4
) (
    input  logic                            clk,
    input  logic                            rst_n,
    input  logic                            start_i,            // Start of new PWM period
    input  logic [GLOBAL_COUNTER_WIDTH-1:0] global_counter_i,
    input  logic [         INSTR_WIDTH-1:0] instr_i,
    output logic [            PC_WIDTH-1:0] pc_o,
    output logic                            output_polarity_o,
    output logic [       COUNTER_WIDTH-1:0] pwm_value_o
);

  import ppwm_pkg::*;
  localparam int OpcodeWidth = 3;
  localparam int ImmWidth = 3;
  localparam int CtrlTransWidth = 4;
  localparam int TargetPos = OpcodeWidth + 1;
  localparam int CntPadWidth = COUNTER_WIDTH - ImmWidth;

  typedef enum logic [1:0] {
    StIdle = 2'b00,  // Idle state
    StExec = 2'b01,  // Executing instruction
    StWait = 2'b10   // Wait for new start without resetting the program counter
  } state_e;
  state_e state_q, state_d;

  // Program counter
  logic [PC_WIDTH-1:0] pc_d, pc_q;
  // Compare flag, set if global counter is smaller
  logic cmp_flag_d, cmp_flag_q;

  // PWM output polarity
  logic output_polarity_d, output_polarity_q;

  command_e instr_cmd;
  target_e instr_trgt;
  cmp_args_e instr_cmp_args;
  mv_args_e instr_mv_args;
  logic [ImmWidth-1:0] instr_imm;
  logic [COUNTER_WIDTH-1:0] instr_imm_sig_ext;
  logic [CtrlTransWidth-1:0] instr_ctrl_offset;

  assign instr_cmd = command_e'(instr_i[OpcodeWidth-1:0]);
  assign instr_trgt = target_e'(instr_i[TargetPos-1]);
  assign instr_cmp_args = cmp_args_e'(instr_i[OpcodeWidth+2:OpcodeWidth]);
  assign instr_mv_args = mv_args_e'(instr_i[OpcodeWidth+2:OpcodeWidth]);
  assign instr_imm = instr_i[INSTR_WIDTH-1:INSTR_WIDTH-ImmWidth];
  assign instr_imm_sig_ext = {{CntPadWidth{instr_imm[ImmWidth-1]}}, instr_imm};
  assign instr_ctrl_offset = instr_i[INSTR_WIDTH-1:OpcodeWidth];

  // PWM value and register storage
  logic [COUNTER_WIDTH-1:0] pwm_value_d, pwm_value_q;
  logic [COUNTER_WIDTH-1:0] reg_value_d, reg_value_q;

  // Execution control
  always_comb begin
    state_d = state_q;
    pc_d = pc_q;
    cmp_flag_d = cmp_flag_q;
    output_polarity_d = output_polarity_q;

    // Default assignments
    pwm_value_d = pwm_value_q;
    reg_value_d = reg_value_q;

    case (state_q)
      StIdle: begin
        if (start_i) begin
          state_d = StExec;
        end
      end
      StExec: begin
        // Last instruction will end execution
        // Can be continued by jumping to the first instruction explicitly
        if (pc_q == '1) begin
          state_d = StIdle;
        end
        pc_d = pc_q + 1;

        case (instr_cmd)
          CMD_CTRL: begin
            // FSM control commands
            // Uses a bit pattern to change behaviour
            case (instr_i[INSTR_WIDTH-1:OpcodeWidth])
              4'b0000: begin
                // NOP
              end
              4'b0001: begin
                // Wait for a new start signal
                state_d = StWait;
              end
              4'b0010: begin
                output_polarity_d = 1'b0;  // Set output polarity to low
              end
              4'b0011: begin
                output_polarity_d = 1'b1;  // Set output polarity to high
              end
              default: begin
                // Unrecognized control command, do nothing
              end
            endcase
          end
          CMD_SET: begin
            if (instr_trgt == TRGT_REG) begin
              reg_value_d = {{CntPadWidth{1'b0}}, instr_imm};
            end else if (instr_trgt == TRGT_PWM) begin
              pwm_value_d = {{CntPadWidth{1'b0}}, instr_imm};
            end
          end
          CMD_ARITH: begin
            if (instr_trgt == TRGT_REG) begin
              reg_value_d = reg_value_q + instr_imm_sig_ext;
            end else if (instr_trgt == TRGT_PWM) begin
              pwm_value_d = pwm_value_q + instr_imm_sig_ext;
            end
          end
          CMD_SHIFT: begin
            if (instr_trgt == TRGT_REG) begin
              if (instr_imm[0]) begin
                reg_value_d = reg_value_q << (instr_imm[2:1] + 1);  // Shift left
              end else begin
                reg_value_d = reg_value_q >> (instr_imm[2:1] + 1);  // Shift right
              end
            end else if (instr_trgt == TRGT_PWM) begin
              if (instr_imm[0]) begin
                pwm_value_d = pwm_value_q << (instr_imm[2:1] + 1);  // Shift left
              end else begin
                pwm_value_d = pwm_value_q >> (instr_imm[2:1] + 1);  // Shift right
              end
            end
          end
          CMD_JUMP: begin
            pc_d = pc_q + instr_ctrl_offset;
          end
          CMD_CMP: begin
            // Compare operation
            cmp_flag_d = 1'b0;
            case (instr_cmp_args)
              CMP_GCNT_L_PWM: begin
                if (global_counter_i[COUNTER_WIDTH-1:0] < pwm_value_q) begin
                  cmp_flag_d = 1'b1;
                end
              end
              CMP_GCNT_H_PWM: begin
                if (global_counter_i[GLOBAL_COUNTER_WIDTH-1:COUNTER_WIDTH] < pwm_value_q) begin
                  cmp_flag_d = 1'b1;
                end
              end
              CMP_GCNT_L_REG: begin
                if (global_counter_i[COUNTER_WIDTH-1:0] < reg_value_q) begin
                  cmp_flag_d = 1'b1;
                end
              end
              CMP_GCNT_H_REG: begin
                if (global_counter_i[GLOBAL_COUNTER_WIDTH-1:COUNTER_WIDTH] < reg_value_q) begin
                  cmp_flag_d = 1'b1;
                end
              end
              CMP_PWM_REG: begin
                if (pwm_value_q < reg_value_q) begin
                  cmp_flag_d = 1'b1;
                end
              end
              default: begin
              end
            endcase
          end
          CMD_MV: begin
            case (instr_mv_args)
              MV_REG_TO_PWM: begin
                // Move register value to PWM value
                pwm_value_d = reg_value_q;
              end
              MV_PWM_TO_REG: begin
                // Move PWM value to register
                reg_value_d = pwm_value_q;
              end
              MV_GCNT_L_REG: begin
                // Move lower part of global counter to register
                reg_value_d = global_counter_i[COUNTER_WIDTH-1:0];
              end
              MV_GCNT_H_REG: begin
                // Move upper part of global counter to register
                reg_value_d = global_counter_i[GLOBAL_COUNTER_WIDTH-1:COUNTER_WIDTH];
              end
              MV_GCNT_L_PWM: begin
                // Move lower part of global counter to PWM value
                pwm_value_d = global_counter_i[COUNTER_WIDTH-1:0];
              end
              MV_GCNT_H_PWM: begin
                // Move upper part of global counter to PWM value
                pwm_value_d = global_counter_i[GLOBAL_COUNTER_WIDTH-1:COUNTER_WIDTH];
              end
              default: begin
              end
            endcase
          end
          CMD_BRANCH: begin
            // Branch if condition is met
            if (cmp_flag_q) begin
              pc_d = pc_q + instr_ctrl_offset;
            end
          end
          default: begin
          end
        endcase
      end
      StWait: begin
        // Wait for a new start signal without resetting the program counter
        if (start_i) begin
          state_d = StExec;
        end
      end
      default: begin
        state_d = StIdle;
      end
    endcase
  end

  // State transition logic
  always_ff @(posedge clk) begin
    if (!rst_n) begin
      state_q           <= StIdle;
      pc_q              <= '0;
      cmp_flag_q        <= 1'b0;
      pwm_value_q       <= '0;
      reg_value_q       <= '0;
      output_polarity_q <= 1'b0;
    end else begin
      state_q           <= state_d;
      pc_q              <= pc_d;
      cmp_flag_q        <= cmp_flag_d;
      pwm_value_q       <= pwm_value_d;
      reg_value_q       <= reg_value_d;
      output_polarity_q <= output_polarity_d;
    end
  end

  assign pc_o              = pc_q;
  assign pwm_value_o       = pwm_value_q;
  assign output_polarity_o = output_polarity_q;

endmodule
