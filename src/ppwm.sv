// SPDX-FileCopyrightText: © 2025 XXX Authors
// SPDX-License-Identifier: Apache-2.0

module ppwm #(
    parameter int COUNTER_WIDTH = 10,
    parameter int INSTR_WIDTH = 7,
    parameter int PC_WIDTH = 4
) (
    input  logic clk,
    input  logic rst_n,
    input  logic data_i,
    output logic data_o
);

  logic mem_write_done;
  logic period_start;

  logic [COUNTER_WIDTH-1:0] pwm_value;

  // PWM generation
  pwm #(
      .COUNTER_WIDTH(COUNTER_WIDTH)
  ) u_pwm (
      .clk(clk),
      .rst_n(rst_n),
      .cmp_value_i(pwm_value),
      .pwm_set_i(mem_write_done),
      .period_start_o(period_start),
      .pwm_o(data_o)
  );

  logic [COUNTER_WIDTH-1:0] global_counter_high;

  // Global counter for user functions
  counter #(
      .WIDTH(20),
      .HIGH_WIDTH(COUNTER_WIDTH)
  ) u_global_counter (
      .clk(clk),
      .rst_n(rst_n),
      .tick_i(period_start),
      .high_value_o(global_counter_high)
  );

  logic [PC_WIDTH-1:0] pc;
  logic [INSTR_WIDTH-1:0] instr;
  // Instruction execution to calculate the PWM value for each period
  ex #(
      .COUNTER_WIDTH(COUNTER_WIDTH),
      .INSTR_WIDTH(INSTR_WIDTH),
      .PC_WIDTH(PC_WIDTH)
  ) u_ex (
      .clk(clk),
      .rst_n(rst_n),
      .start_i(period_start),
      .global_counter_i(global_counter_high),
      .instr_i(instr),
      .pc_o(pc),
      .pwm_value_o(pwm_value)
  );

  // Instruction memory
  // Serial line for programming, high start bit
  mem #(
      .WIDTH(INSTR_WIDTH),
      .DEPTH(PC_WIDTH**2)
  ) u_mem (
      .clk(clk),
      .rst_n(rst_n),
      .data_i(data_i),
      .addr_i(pc),
      .programmed_o(mem_write_done),
      .data_o(instr)
  );

endmodule
