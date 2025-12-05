`timescale 1ns/1ps

//====================================================
// mlp_output_score : hidden activations -> y_score
//====================================================
module mlp_output_score #(
    parameter W = 8,
    parameter N = 8
)(
    input                       clk,
    input                       rst_n,
    input  signed [N*(W+5)-1:0] h_raw_bus,        // raw hidden scores (flattened)
    input  signed [N*W-1:0]     w_o_bus,
    input  signed [W-1:0]       b_o,
    output reg signed [W+4:0]   y_score,          // output layer score
    output reg signed [N*(W+5)-1:0] h_act_bus    // ReLU hidden outputs (flattened)
);

    localparam HRAW_W = W + 5;

    reg signed [HRAW_W-1:0] h_act [0:N-1];
    integer i, k;
    reg signed [HRAW_W-1:0] h_val;
    reg signed [W-1:0]      w_val;
    reg signed [HRAW_W-1:0] b_ext;
    reg signed [HRAW_W-1:0] w_ext;

    always @(posedge clk) begin
        if (!rst_n) begin
            y_score <= 0;
            for (i = 0; i < N; i = i + 1)
                h_act[i] <= 0;
        end else begin
            // ReLU 활성화
            for (i = 0; i < N; i = i + 1) begin
                h_val    = h_raw_bus[i*HRAW_W +: HRAW_W];
                h_act[i] <= (h_val > 0) ? h_val : 0;
            end

            // 출력층: y_score = b_o + sum_i(w_o[i] * h_act[i])  (실제 ReLU 값 사용)
            b_ext   = {{(HRAW_W-W){b_o[W-1]}}, b_o};
            y_score = b_ext;
            for (i = 0; i < N; i = i + 1) begin
                w_val = w_o_bus[i*W +: W];
                w_ext = {{(HRAW_W-W){w_val[W-1]}}, w_val};
                // 실제 ReLU 활성화 값을 사용 (더 정확한 계산)
                // h_act[i]는 이미 ReLU가 적용된 값이므로 그대로 곱함
                // 간단한 근사: w_o[i] * h_act[i] ≈ w_o[i] * (h_act[i] >> 3) for scaling
                if (h_act[i] > 0) begin
                    // h_act[i]를 스케일링하여 곱셈 (비트 시프트로 근사)
                    y_score = y_score + ((w_ext * h_act[i]) >>> 3);
                end
            end
        end
    end

    // ReLU 결과를 플랫 버스로
    always @(*) begin
        for (k = 0; k < N; k = k + 1)
            h_act_bus[k*HRAW_W +: HRAW_W] = h_act[k];
    end

endmodule


