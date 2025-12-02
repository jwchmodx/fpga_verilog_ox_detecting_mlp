`timescale 1ns/1ps

//====================================================
// mlp_update : backprop both layers with flattened buses
//====================================================
module mlp_update #(
    parameter W    = 8,
    parameter N    = 8,
    parameter FRAC = 6
)(
    input                       clk,
    input                       rst_n,
    input                       learn,
    input        [15:0]         x,
    input  signed [W-1:0]       err,
    input  signed [N*(W+5)-1:0] h_act_bus,
    output signed [N*W-1:0]     w_o_bus,
    output signed [W-1:0]       b_o_out,
    output signed [N*16*W-1:0]  w_h_bus,
    output signed [N*W-1:0]     b_h_bus
);
    localparam HRAW_W = W + 5;

    reg signed [W-1:0] w_o [0:N-1];
    reg signed [W-1:0] b_o;
    reg signed [W-1:0] w_h [0:N-1][0:15];
    reg signed [W-1:0] b_h [0:N-1];

    integer i, j;
    reg signed [HRAW_W-1:0] h_val;
    reg signed [W-1:0]      delta_o;

    always @(posedge clk) begin
        if (!rst_n) begin
            b_o <= 0;
            for (i = 0; i < N; i = i + 1) begin
                w_o[i] <= ($random % 128) - 64;   // 초기화: -64 ~ +63 (-1.0 ~ +1.0)
                b_h[i] <= 0;
                for (j = 0; j < 16; j = j + 1)
                    w_h[i][j] <= ($random % 128) - 64;  // 초기화: -64 ~ +63
            end
        end else if (learn) begin
            for (i = 0; i < N; i = i + 1) begin
                h_val   = h_act_bus[i*HRAW_W +: HRAW_W];

                // 출력층 업데이트 (학습률 증가: FRAC-2)
                delta_o = ((err * (h_val > 0)) >>> (FRAC-2));  // 4배 더 큰 학습률
                w_o[i]  <= w_o[i] + delta_o;

                // hidden bias 업데이트 (학습률 증가)
                b_h[i]  <= b_h[i] + ((err * w_o[i]) >>> (FRAC-2));

                // 입력-히든 가중치 업데이트 (학습률 증가)
                for (j = 0; j < 16; j = j + 1)
                    w_h[i][j] <= w_h[i][j]
                               + ((err * w_o[i] * (x[j] ? 1 : -1)) >>> (2*FRAC-3));
            end
            b_o <= b_o + (err >>> 1);  // 출력 bias도 학습률 증가
        end
    end

    // 배열을 플랫 버스로 패킹
    genvar gi, gj;
    generate
        for (gi = 0; gi < N; gi = gi + 1) begin : pack_params
            assign w_o_bus[gi*W +: W] = w_o[gi];
            assign b_h_bus[gi*W +: W] = b_h[gi];
            for (gj = 0; gj < 16; gj = gj + 1) begin : pack_hidden_w
                assign w_h_bus[(gi*16+gj)*W +: W] = w_h[gi][gj];
            end
        end
    endgenerate

    assign b_o_out = b_o;

endmodule


