// SPDX-FileCopyrightText: © 2025 Tobias Wölfel
// SPDX-License-Identifier: Apache-2.0

// Adapted from the Tiny Tapeout template

`default_nettype none

module heichips25_ppwm (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  // List all unused inputs to prevent warnings
  wire  _unused = &{ena, ui_in[7:2], uio_in[7:0]};

  ppwm #(
      .COUNTER_WIDTH(10)
  ) u_ppwm (
      .clk(clk),
      .rst_n(rst_n),
      .data_i(ui_in[0]),
      .clk_data_i(ui_in[1]),
      .data_o(uo_out[0])
  );

  assign uo_out[7:1] = 7'h00;
  assign uio_out = '0;
  assign uio_oe = '0;

endmodule
