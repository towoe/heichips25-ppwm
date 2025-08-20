// SPDX-FileCopyrightText: © 2025 Marcel Jung
// SPDX-License-Identifier: Apache-2.0

// Adapted from the Tiny Tapeout template

`default_nettype none
// `include "../../submodules/heichips25-ppwm/src/heichips25_ppwm.sv"
// `include "../../submodules/heichips25_SDR_new/src/heichips25_template.sv"

module tiny_wrapper (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // Sets which project will be active
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

    wire [7:0] ui_in_ppwm;
    wire [7:0] uo_out_ppwm;
    wire [7:0] uio_out_ppwm;
    wire [7:0] uio_oe_ppwm;
    wire rst_n_ppwm;
    wire ena_ppwm;

    wire [7:0] uo_out_sdr;
    wire [7:0] uio_out_sdr;
    wire [7:0] uio_oe_sdr;
    wire rst_n_sdr;
    wire ena_sdr;

    // If ena = 1, the PPWM project will be active and if ena = 0, the SDR will be active
    assign ena_sdr = ena;
    assign ena_ppwm = ~ena_sdr; // Only one project is enabled at the same time


    assign uo_out = ena_ppwm ? uo_out_ppwm : uo_out_sdr;
    assign uio_out = ena_ppwm ? uio_out_ppwm : uio_out_sdr;
    assign uio_oe = ena_ppwm ? uio_oe_ppwm : uio_oe_sdr;

    // Reset the project that is not enabled. Also reset if the external
    // reset is triggered.
    assign rst_n_ppwm = ena_ppwm & rst_n;
    assign rst_n_sdr = ena_sdr & rst_n;

    // Instantiation of the PPWM project
    heichips25_ppwm heichips25_ppwm_i (
        .ui_in(ui_in),
        .uo_out(uo_out_ppwm),
        .uio_in(uio_in),
        .uio_out(uio_out_ppwm),
        .uio_oe(uio_oe_ppwm),
        .ena(1'b1), // The internal enable signal is always 1
        .clk(clk),
        .rst_n(rst_n_ppwm)
    );

    // Instantiation of the SDR project
    // heichips25_template heichips25_template_i (
    //     .ui_in(ui_in),
    //     .uo_out(uo_out_sdr),
    //     .uio_in(uio_in),
    //     .uio_out(uio_out_sdr),
    //     .uio_oe(uio_oe_sdr),
    //     .ena(1'b1), // The internal enable signal is always 1
    //     .clk(clk),
    //     .rst_n(rst_n_sdr)
    // );

endmodule
