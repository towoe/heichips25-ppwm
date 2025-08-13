// SPDX-FileCopyrightText: © 2025 XXX Authors
// SPDX-License-Identifier: Apache-2.0

module mem #(
    parameter int WIDTH = 7,
    parameter int DEPTH = 32
) (
    input  logic                     clk,
    input  logic                     rst_n,
    input  logic                     data_i,
    input  logic [$clog2(DEPTH)-1:0] addr_i,
    output logic                     programmed_o,
    output logic [        WIDTH-1:0] data_o
);

  logic [WIDTH*DEPTH-1:0] memory;
  logic [$clog2(WIDTH*DEPTH)-1:0] bit_count;

  typedef enum logic [1:0] {
    StIdle,
    StShift,
    StDone
  } state_e;

  state_e state_d, state_q;

  // Combinational logic for next state
  always_comb begin
    state_d = state_q;

    unique case (state_q)
      StIdle: begin
        if (data_i) begin
          state_d = StShift;
        end
      end

      StShift: begin
        if (bit_count == $clog2(WIDTH * DEPTH)'(WIDTH * DEPTH - 1)) begin
          state_d = StDone;
        end
      end

      StDone: begin
        // Stay in this state to signal programmed memory
        if (data_i) begin
          state_d = StIdle;
        end
      end

      default: state_d = StIdle;
    endcase
  end

  // State register
  always_ff @(posedge clk) begin
    if (!rst_n) begin
      state_q <= StIdle;
    end else begin
      state_q <= state_d;
    end
  end

  // Counter and shift register
  always_ff @(posedge clk) begin
    if (!rst_n) begin
      bit_count <= '0;
      memory <= '0;
    end else begin
      unique case (state_q)
        StIdle: begin
          bit_count <= '0;
        end
        StShift: begin
          memory    <= {data_i, memory[WIDTH*DEPTH-1:1]};
          bit_count <= bit_count + 1;
        end
        default: begin
        end
      endcase
    end
  end

  // Parallel read access
  assign data_o = memory[addr_i*WIDTH+:WIDTH];
  assign programmed_o = (state_q == StDone);

endmodule
