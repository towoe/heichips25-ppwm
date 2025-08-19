// SPDX-FileCopyrightText: © 2025 Tobias Wölfel
// SPDX-License-Identifier: Apache-2.0

module pwm #(
    parameter int COUNTER_WIDTH = 10
) (
    input  logic                     clk,
    input  logic                     rst_n,
    input  logic [COUNTER_WIDTH-1:0] cmp_value_i,
    input  logic                     pwm_set_i,
    output logic                     period_start_o,
    input  logic                     output_polarity_i,
    output logic                     pwm_o
);
  logic [COUNTER_WIDTH-1:0] counter;
  logic [COUNTER_WIDTH-1:0] cmp_value;
  logic period_start;

  assign period_start_o = period_start;

  always_ff @(posedge clk) begin : start_signal
    if (!rst_n) begin
      period_start <= 1'b0;
    end else begin
      period_start <= (counter == {COUNTER_WIDTH{1'b1}});
    end
  end

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      cmp_value <= {COUNTER_WIDTH{1'b0}};
    end else begin
      if (counter == {COUNTER_WIDTH{1'b0}}) begin
        cmp_value <= cmp_value_i;
      end
    end
  end

  always @(posedge clk) begin
    if (!rst_n) begin
      counter <= {COUNTER_WIDTH{1'b0}};
      pwm_o   <= 1'b0;
    end else begin
      if (pwm_set_i) begin
        counter <= counter + 1;
      end
      if (counter < cmp_value) begin
        pwm_o <= output_polarity_i ? 1'b1 : 1'b0;
      end else begin
        pwm_o <= output_polarity_i ? 1'b0 : 1'b1;
      end
    end
  end
endmodule
