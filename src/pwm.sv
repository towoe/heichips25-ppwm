// SPDX-FileCopyrightText: © 2025 XXX Authors
// SPDX-License-Identifier: Apache-2.0

module pwm #(
    parameter int COUNTER_WIDTH = 8
) (
    input logic clk,
    input logic rst_n,
    input logic [COUNTER_WIDTH-1:0] cmp_value_i,
    input logic pwm_set_i,
    output logic period_start_o,
    output logic pwm_o
);
  logic [COUNTER_WIDTH-1:0] counter;
  logic period_start;

  assign period_start_o = period_start;

  always_ff @(posedge clk or negedge rst_n) begin : start_signal
    if (!rst_n) begin
      period_start <= 1'b0;
    end else begin
      period_start <= (counter == {COUNTER_WIDTH{1'b0}});
    end
  end

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n || pwm_set_i) begin
      counter <= {COUNTER_WIDTH{1'b0}};
      pwm_o   <= 1'b0;
    end else begin
      counter <= counter + 1;
      if (counter < cmp_value_i) begin
        pwm_o <= 1'b0;
      end else begin
        pwm_o <= 1'b1;
      end
    end
  end
endmodule
