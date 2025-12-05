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
    reg signed [W-1:0]      delta_bh;
    reg signed [W-1:0]      delta_h;
    reg signed [W-1:0]      delta_bo;

    always @(posedge clk) begin
        if (!rst_n) begin
            b_o <= 0;
            for (i = 0; i < N; i = i + 1) begin
                // 가중치 초기화: 작은 범위로 균등 분포 (ReLU 클리핑 고려)
                // 출력층: 0 ~ +15 (작은 양수, 초기 출력이 골고루 분포되도록)
                w_o[i] <= ($random % 16);   // 초기화: 0 ~ +15
                // 히든 bias: 작은 음수로 설정하여 일부 뉴런만 활성화 (골고루 분포)
                b_h[i] <= ($random % 16) - 12;    // bias: -12 ~ +3 (약간 음수 중심)
                // 입력-히든 가중치: 작은 범위로 초기화 (양수/음수 균형)
                for (j = 0; j < 16; j = j + 1)
                    w_h[i][j] <= ($random % 16) - 8;  // 초기화: -8 ~ +7 (작은 범위)
            end
        end else if (learn) begin
            for (i = 0; i < N; i = i + 1) begin
                h_val   = h_act_bus[i*HRAW_W +: HRAW_W];

                // 출력층 업데이트 (학습률 조정: FRAC-2 = 4배, 안정적인 학습)
                delta_o = ((err * (h_val > 0)) >>> (FRAC-2));  // 4배 학습률
                // 가중치 클리핑: -128 ~ +127 범위 유지
                if (w_o[i] + delta_o > 127)
                    w_o[i] <= 127;
                else if (w_o[i] + delta_o < -128)
                    w_o[i] <= -128;
                else
                    w_o[i] <= w_o[i] + delta_o;

                // hidden bias 업데이트 (학습률 조정)
                delta_bh = ((err * w_o[i]) >>> (FRAC-2));
                if (b_h[i] + delta_bh > 127)
                    b_h[i] <= 127;
                else if (b_h[i] + delta_bh < -128)
                    b_h[i] <= -128;
                else
                    b_h[i] <= b_h[i] + delta_bh;

                // 입력-히든 가중치 업데이트 (학습률 조정)
                for (j = 0; j < 16; j = j + 1) begin
                    delta_h = ((err * w_o[i] * (x[j] ? 1 : -1)) >>> (2*FRAC-2));
                    if (w_h[i][j] + delta_h > 127)
                        w_h[i][j] <= 127;
                    else if (w_h[i][j] + delta_h < -128)
                        w_h[i][j] <= -128;
                    else
                        w_h[i][j] <= w_h[i][j] + delta_h;
                end
            end
            // 출력 bias 업데이트 (클리핑 포함)
            delta_bo = (err >>> 2);
            if (b_o + delta_bo > 127)
                b_o <= 127;
            else if (b_o + delta_bo < -128)
                b_o <= -128;
            else
                b_o <= b_o + delta_bo;
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


