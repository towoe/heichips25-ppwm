// SPDX-FileCopyrightText: © 2025 Tobias Wölfel
// SPDX-License-Identifier: Apache-2.0

module mem #(
    parameter int WIDTH = 7,
    parameter int DEPTH = 32
) (
    input  logic                     clk,
    input  logic                     clk_prog,
    input  logic                     rst_n,
    input  logic                     data_i,
    input  logic [$clog2(DEPTH)-1:0] addr_i,
    output logic                     programmed_o,
    output logic [        WIDTH-1:0] data_o
);

  logic [WIDTH*DEPTH-1:0] memory;
  logic [$clog2(WIDTH*DEPTH)-1:0] bit_count;

  // Synchronize programming clock to system domain for edge detection
  logic clk_prog_sync1, clk_prog_sync2, clk_prog_sync3;
  logic clk_prog_posedge;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      clk_prog_sync1 <= 1'b0;
      clk_prog_sync2 <= 1'b0;
      clk_prog_sync3 <= 1'b0;
    end else begin
      clk_prog_sync1 <= clk_prog;
      clk_prog_sync2 <= clk_prog_sync1;
      clk_prog_sync3 <= clk_prog_sync2;
    end
  end

  assign clk_prog_posedge = clk_prog_sync2 && !clk_prog_sync3;

  // Synchronize data input
  logic data_sync1, data_sync2;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      data_sync1 <= 1'b0;
      data_sync2 <= 1'b0;
    end else begin
      data_sync1 <= data_i;
      data_sync2 <= data_sync1;
    end
  end

  logic programming;

// Counter and shift register
  always_ff @(posedge clk) begin
    if (!rst_n) begin
      bit_count <= '0;
      memory <= '0;
      programming <= 1'b0;
    end else if (clk_prog_posedge) begin
      if (data_sync2 && !programming) begin
        // Start bit detected - begin programming on next edge
        programming <= 1'b1;
        bit_count <= '0;
      end else if (programming) begin
        memory    <= {data_sync2, memory[WIDTH*DEPTH-1:1]};
        bit_count <= bit_count + 1;
        if (bit_count == $clog2(WIDTH * DEPTH)'(WIDTH * DEPTH - 1)) begin
          programming <= 1'b0;
        end
      end
    end
  end

  // Parallel read access
  assign data_o = memory[addr_i*WIDTH+:WIDTH];
  assign programmed_o = (bit_count == $clog2(WIDTH * DEPTH)'(WIDTH * DEPTH));

endmodule
