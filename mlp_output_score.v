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

            // 출력층: y_score = b_o + sum_i(w_o[i] * scaled_h_act[i])
            // h_act[i]의 크기에 따라 다른 스케일링 적용하여 다양성 향상
            b_ext   = {{(HRAW_W-W){b_o[W-1]}}, b_o};
            y_score = b_ext;
            for (i = 0; i < N; i = i + 1) begin
                w_val = w_o_bus[i*W +: W];
                w_ext = {{(HRAW_W-W){w_val[W-1]}}, w_val};
                // h_act[i]의 크기에 따라 다른 스케일링 적용
                if (h_act[i] > 0) begin
                    // h_act[i]의 크기를 3단계로 분류하여 다양성 향상
                    if (h_act[i] > (1 << (HRAW_W-2))) begin
                        // 큰 활성화: 전체 가중치 적용
                        y_score = y_score + w_ext;
                    end else if (h_act[i] > (1 << (HRAW_W-3))) begin
                        // 중간 활성화: 가중치의 3/4 적용
                        y_score = y_score + ((w_ext * 3) >>> 2);
                    end else begin
                        // 작은 활성화: 가중치의 1/2 적용
                        y_score = y_score + (w_ext >>> 1);
                    end
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


