module testbench (
    input clk,
    input rst_n,
    input ena,
    input [7:0] ui_in,
    input [7:0] uio_in,
    output [7:0] uo_out_wrapper,
    output [7:0] uio_out_wrapper,
    output [7:0] uio_oe_wrapper,
    output [7:0] uo_out_ppwm,
    output [7:0] uio_out_ppwm,
    output [7:0] uio_oe_ppwm,
    output [7:0] uo_out_sdr,
    output [7:0] uio_out_sdr,
    output [7:0] uio_oe_sdr
);

    heichips25_ppwm ppwm_i (
        .clk(clk),
        .rst_n(rst_n),
        .ena(1'b1),
        .ui_in(ui_in),
        .uio_in(uio_in),
        .uo_out(uo_out_ppwm),
        .uio_out(uio_out_ppwm),
        .uio_oe(uio_oe_ppwm)
    );

    heichips25_tiny_wrapper heichips25_tiny_wrapper_i (
        .clk(clk),
        .rst_n(rst_n),
        .ena(ena),
        .ui_in(ui_in),
        .uio_in(uio_in),
        .uo_out(uo_out_wrapper),
        .uio_out(uio_out_wrapper),
        .uio_oe(uio_oe_wrapper)
    );

    heichips25_template sdr_i (
        .clk(clk),
        .rst_n(rst_n),
        .ena(1'b1),
        .ui_in(ui_in),
        .uio_in(uio_in),
        .uo_out(uo_out_sdr),
        .uio_out(uio_out_sdr),
        .uio_oe(uio_oe_sdr)
    );
endmodule
