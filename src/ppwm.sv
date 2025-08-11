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

  logic pwm_start;
  logic period_start;

  // Serial input of the PWM value
  logic [9:0] pwm_value;
  serial_in #(
      .WIDTH(10)
  ) u_serial_in (
      .clk(clk),
      .rst_n(rst_n),
      .data_i(data_i),
      .data_o(pwm_value),
      .done_o(pwm_start)
  );

  // PWM generation
  pwm #(
      .COUNTER_WIDTH(10)
  ) u_pwm (
      .clk(clk),
      .rst_n(rst_n),
      .cmp_value_i(pwm_value),
      .pwm_set_i(pwm_start),
      .period_start_o(period_start),
      .pwm_o(data_o)
  );

endmodule
