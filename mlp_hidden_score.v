`timescale 1ns/1ps

//====================================================
// mlp_hidden_score : x[15:0] -> hidden raw scores
//====================================================
module mlp_hidden_score #(
    parameter W = 8,
    parameter N = 8               // Hidden dimension size
)(
    input                       clk,
    input                       rst_n,
    input        [15:0]         x,                 // 16 inputs (logic 0/1)
    input  signed [N*W-1:0]     b_h_bus,
    input  signed [N*16*W-1:0]  w_h_bus,
    output reg signed [N*(W+5)-1:0] h_raw_bus      // Hidden pre-activation (flattened)
);

    localparam HRAW_W = W + 5;

    reg signed [HRAW_W-1:0] h_raw [0:N-1];
    integer i, j, k;
    reg signed [W-1:0]      weight;
    reg signed [W-1:0]      bias;
    reg signed [HRAW_W-1:0] sum;
    reg signed [HRAW_W-1:0] weight_ext;
    reg signed [HRAW_W-1:0] bias_ext;

    // w_h_bus 인덱싱용
    function integer idx;
        input integer neuron;
        input integer input_idx;
        begin
            idx = (neuron * 16 + input_idx) * W;
        end
    endfunction

    always @(posedge clk) begin
        if (!rst_n) begin
            for (i = 0; i < N; i = i + 1)
                h_raw[i] <= 0;
        end else begin
            for (i = 0; i < N; i = i + 1) begin
                // bias 가져오기
                bias     = b_h_bus[i*W +: W];
                bias_ext = {{(HRAW_W-W){bias[W-1]}}, bias};
                sum      = bias_ext;

                // 16비트 입력에 대해 +w 또는 -w 더하기
                for (j = 0; j < 16; j = j + 1) begin
                    weight     = w_h_bus[idx(i,j) +: W];
                    weight_ext = {{(HRAW_W-W){weight[W-1]}}, weight};
                    sum        = sum + (x[j] ? weight_ext : -weight_ext);
                end
                h_raw[i] <= sum;
            end
        end
    end

    // 배열 -> 플랫 버스
    always @(*) begin
        for (k = 0; k < N; k = k + 1)
            h_raw_bus[k*HRAW_W +: HRAW_W] = h_raw[k];
    end

endmodule


