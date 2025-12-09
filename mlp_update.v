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

    // -----------------------------------------------------------
    // 합성 가능한 의사 난수 생성 함수 (Hash Function)
    // - 입력(인덱스)에 대해 결정적이지만 난수처럼 보이는 값을 반환
    // -----------------------------------------------------------
    function signed [W-1:0] get_random_weight;
        input integer idx1;
        input integer idx2; // 2차원 인덱스 또는 Salt
        reg [31:0] hash_val;
        begin
            // 1. 인덱스를 섞음 (매직 넘버 사용)
            // Golden Ratio Prime: 0x9E3779B9
            hash_val = (idx1 * 32'h9E3779B9) ^ (idx2 * 32'h5F356495);
            
            // 2. 비트 믹싱 (Avalanche Effect 유도)
            hash_val = hash_val ^ (hash_val >> 16);
            hash_val = hash_val * 32'h85EBCA6B;
            hash_val = hash_val ^ (hash_val >> 13);
            hash_val = hash_val * 32'hC2B2AE35;
            hash_val = hash_val ^ (hash_val >> 16);
            
            // 3. 하위 4비트 추출 (0~15) -> -8 offset 적용 (-8 ~ +7 범위)
            // W비트 signed로 변환하여 반환
            get_random_weight = $signed({1'b0, hash_val[3:0]}) - 8'sd8;
        end
    endfunction

    always @(posedge clk) begin
        if (!rst_n) begin
            // 출력 bias는 0으로 초기화
            b_o <= 0;
            
            for (i = 0; i < N; i = i + 1) begin
                // 직접 구현한 난수 함수로 초기화
                // idx2에 서로 다른 값을 주어 패턴 중복 방지
                w_o[i] <= get_random_weight(i, 100);    // Salt: 100
                b_h[i] <= get_random_weight(i, 200);    // Salt: 200
                
                for (j = 0; j < 16; j = j + 1)
                    w_h[i][j] <= get_random_weight(i, j); // 2D Index 사용
            end
        end else if (learn) begin
            for (i = 0; i < N; i = i + 1) begin
                h_val   = h_act_bus[i*HRAW_W +: HRAW_W];

                // 출력층 업데이트
                delta_o = ((err * (h_val > 0)) >>> (FRAC-1));
                if (w_o[i] + delta_o > 127)      w_o[i] <= 127;
                else if (w_o[i] + delta_o < -128) w_o[i] <= -128;
                else                              w_o[i] <= w_o[i] + delta_o;

                // hidden bias 업데이트
                delta_bh = ((err * w_o[i]) >>> (FRAC-1));
                if (b_h[i] + delta_bh > 127)      b_h[i] <= 127;
                else if (b_h[i] + delta_bh < -128) b_h[i] <= -128;
                else                               b_h[i] <= b_h[i] + delta_bh;

                // 입력-히든 가중치 업데이트
                for (j = 0; j < 16; j = j + 1) begin
                    delta_h = ((err * w_o[i] * (x[j] ? 1 : -1)) >>> (2*FRAC-1));
                    if (w_h[i][j] + delta_h > 127)      w_h[i][j] <= 127;
                    else if (w_h[i][j] + delta_h < -128) w_h[i][j] <= -128;
                    else                                 w_h[i][j] <= w_h[i][j] + delta_h;
                end
            end
            // 출력 bias 업데이트
            delta_bo = (err >>> 3);
            if (b_o + delta_bo > 127)      b_o <= 127;
            else if (b_o + delta_bo < -128) b_o <= -128;
            else                            b_o <= b_o + delta_bo;
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
