// SPDX-FileCopyrightText: © 2025 XXX Authors
// SPDX-License-Identifier: Apache-2.0

module ppwm #(
    parameter int COUNTER_WIDTH = 8
) (
    input  logic clk,
    input  logic rst_n,
    input  logic data_i,
    output logic data_o
);

  logic mem_write_done;
  logic period_start;

  logic [9:0] pwm_value;

  // PWM generation
  pwm #(
      .COUNTER_WIDTH(10)
  ) u_pwm (
      .clk(clk),
      .rst_n(rst_n),
      .cmp_value_i(pwm_value),
      .pwm_set_i(mem_write_done),
      .period_start_o(period_start),
      .pwm_o(data_o)
  );

  logic [9:0] global_counter_high;

  // Global counter for user functions
  counter #(
      .WIDTH(20),
      .HIGH_WIDTH(10)
  ) u_global_counter (
      .clk(clk),
      .rst_n(rst_n),
      .tick_i(period_start),
      .high_value_o(global_counter_high)
  );

  // Instruction memory
  // Serial line for programming, high start bit
  mem #(
      .WIDTH(6),
      .DEPTH(32)
  ) u_mem (
      .clk(clk),
      .rst_n(rst_n),
      .data_i(data_i),
      .addr_i(pc),
      .programmed_o(mem_write_done),
      .data_o(instr)
  );

endmodule
