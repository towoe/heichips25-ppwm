// SPDX-FileCopyrightText: © 2025 XXX Authors
// SPDX-License-Identifier: Apache-2.0

module counter #(
    parameter int WIDTH = 20,
    parameter int HIGH_WIDTH = 8
) (
    input  logic                  clk,
    input  logic                  rst_n,
    input  logic                  tick_i,
    output logic [HIGH_WIDTH-1:0] high_value_o
);

  logic [WIDTH-1:0] counter;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      counter <= '0;
    end else if (tick_i) begin
      counter <= counter + 1;
    end
  end

  assign high_value_o = counter[WIDTH-1:WIDTH-HIGH_WIDTH];

endmodule
