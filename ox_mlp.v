`timescale 1ns/1ps


//====================================================
// mlp_OX : 16xN x 1 MLP classifier (O vs X)
//   - y: O/X 이진 결과
//   - y_score_out: 출력층 raw score
//   - hidden_score: hidden pre-activation 합산 스코어
//   - o_prob_pct: O일 "확률(추정)" 0~100%
//====================================================ㅁㄴㅇㅁㄴㅇ
module mlp_OX #(
    parameter W    = 8,
    parameter N    = 8,
    parameter FRAC = 6
)(
    input              clk,
    input              rst_n,
    input      [15:0]  x,
    input              learn,
    input              is_O,
    output             y,                 // binary output: 1이면 O
    output      [6:0]  o_prob_pct,       // O일 확률(추정) 0~100(%)
    output signed [W+4:0] y_score_out,   // 출력층 score 그대로
    output signed [W+9:0] hidden_score   // hidden 전체 score (대충 넉넉한 폭)
);
    localparam HRAW_W = W + 5;

    wire signed [N*HRAW_W-1:0] h_raw_bus;
    wire signed [N*HRAW_W-1:0] h_act_bus;
    wire signed [N*16*W-1:0]   w_h_bus;
    wire signed [N*W-1:0]      b_h_bus;
    wire signed [N*W-1:0]      w_o_bus;
    wire signed [W-1:0]        b_o_bus;
    wire signed [W+4:0]        y_score;
    wire signed [W-1:0]        err_s3;

    wire [W-1:0] prob_q;
    wire [6:0]   prob_pct;

    // Hidden layer
    mlp_hidden_score #(.W(W), .N(N)) u_hidden (
        .clk(clk),
        .rst_n(rst_n),
        .x(x),
        .b_h_bus(b_h_bus),
        .w_h_bus(w_h_bus),
        .h_raw_bus(h_raw_bus)
    );

    // Output layer
    mlp_output_score #(.W(W), .N(N)) u_output (
        .clk(clk),
        .rst_n(rst_n),
        .h_raw_bus(h_raw_bus),
        .w_o_bus(w_o_bus),
        .b_o(b_o_bus),
        .y_score(y_score),
        .h_act_bus(h_act_bus)
    );

    // Error computation
    mlp_error #(.W(W), .FRAC(FRAC)) u_error (
        .clk(clk),
        .rst_n(rst_n),
        .y_in(y_score > 0),
        .is_O(is_O),
        .err_out(err_s3)
    );

    // Parameter update
    mlp_update #(.W(W), .N(N), .FRAC(FRAC)) u_update (
        .clk(clk),
        .rst_n(rst_n),
        .learn(learn),
        .x(x),
        .err(err_s3),
        .h_act_bus(h_act_bus),
        .w_o_bus(w_o_bus),
        .b_o_out(b_o_bus),
        .w_h_bus(w_h_bus),
        .b_h_bus(b_h_bus)
    );

    // --- Hidden 전체 스코어 (단순 합) ---
    reg signed [W+9:0] hidden_sum;
    integer hi;
    reg signed [HRAW_W-1:0] h_tmp;

    always @(*) begin
        hidden_sum = 0;
        for (hi = 0; hi < N; hi = hi + 1) begin
            h_tmp = h_raw_bus[hi*HRAW_W +: HRAW_W];
            hidden_sum = hidden_sum
                       + {{( (W+10) - HRAW_W){h_tmp[HRAW_W-1]}}, h_tmp};
        end
    end

    // y_score -> 시그모이드(근사) 확률(QFRAC)
    sigmoid_fixed #(
        .W     (W),
        .FRAC  (FRAC),
        .SHIFT (6),   // 민감도 향상: 9(512) -> 6(64). 작은 점수 변화에도 확률이 크게 변하도록 수정
        .CLIP_X(4)    // 범위 조정 (Score 범위에 맞게)
    ) u_prob_conv (
        .z  (y_score),
        .p_q(prob_q)
    );

    // 확률(QFRAC) -> 0~100%
    prob_to_percent #(
        .W(W),
        .FRAC(FRAC)
    ) u_prob_pct (
        .p_q    (prob_q),
        .percent(prob_pct)
    );

    assign y            = (y_score > 0);   // 기존 pass / non-pass
    assign o_prob_pct   = prob_pct;        // O일 확률(추정)
    assign y_score_out  = y_score;         // raw logit
    assign hidden_score = hidden_sum;      // hidden 레이어의 “점수”

endmodule
