`timescale 1ns/1ps

//====================================================
// mlp_error : y_hat vs target (O/X에 대한 에러)
//====================================================
module mlp_error #(
    parameter W    = 8,
    parameter FRAC = 6
)(
    input               clk,
    input               rst_n,
    input               y_in,   // y_score > 0
    input               is_O,   // 정답이 O인지
    output reg signed [W-1:0] err_out
);

    // target, output을 QFRAC 고정소수점으로
    wire signed [W-1:0] target   = is_O ? (1 <<< FRAC) : 0;
    wire signed [W-1:0] output_q = y_in ? (1 <<< FRAC) : 0;

    always @(posedge clk) begin
        if (!rst_n)
            err_out <= 0;
        else
            err_out <= target - output_q;
    end
endmodule


