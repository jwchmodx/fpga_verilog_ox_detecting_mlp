`timescale 1ns/1ps

//====================================================
// sigmoid_fixed : y_score -> 시그모이드(근사) 확률(QFRAC)
//   - 개선된 piecewise linear sigmoid 근사
//   - 더 정교한 구간별 선형 근사로 다양성 향상
//====================================================
module sigmoid_fixed #(
    parameter W      = 8,   // 확률 출력 비트폭
    parameter FRAC   = 6,   // QFRAC (1.0 = 1<<FRAC)
    parameter SHIFT  = 6,   // 입력 스코어 스케일링 (10 -> 6으로 감소, 더 민감하게)
    parameter CLIP_X = 8    // 클리핑 범위 확대 (4 -> 8)
)(
    input  signed [W+4:0] z,    // y_score (mlp_output_score에서 나오는 raw score)
    output reg   [W-1:0]  p_q   // QFRAC 확률 (0.0~1.0)
);
    // z를 SHIFT 만큼 줄인 값 (정수 영역)
    reg signed [W+4:0] x;

    // 중간 계산용 (부호 포함, 약간 넉넉하게 잡음)
    reg signed [W+FRAC+2:0] tmp;

    always @* begin
        // 1) 입력 스코어 스케일링 (SHIFT 감소로 더 민감하게)
        x = z >>> SHIFT;

        // 2) 개선된 piecewise linear sigmoid 근사
        //    구간별로 다른 기울기를 사용하여 더 다양하고 정확한 확률 생성
        if (x <= -CLIP_X) begin
            tmp = 0;
        end
        else if (x >= CLIP_X) begin
            tmp = (1 <<< FRAC);   // 1.0 in QFRAC
        end
        else if (x <= -4) begin
            // [-8, -4]: 기울기 1/16, y절편 조정
            tmp = (1 <<< (FRAC-4)) + ((x + 4) <<< (FRAC-4));
        end
        else if (x <= 0) begin
            // [-4, 0]: 기울기 1/8, 0.5에서 시작
            tmp = (1 <<< (FRAC-1)) + (x <<< (FRAC-3));
        end
        else if (x <= 4) begin
            // [0, 4]: 기울기 1/8, 0.5에서 시작
            tmp = (1 <<< (FRAC-1)) + (x <<< (FRAC-3));
        end
        else begin
            // [4, 8]: 기울기 1/16, 0.75에서 시작
            tmp = (3 <<< (FRAC-2)) + ((x - 4) <<< (FRAC-4));
        end

        // 3) 안전하게 0~1 범위로 클리핑
        if (tmp < 0)
            tmp = 0;
        else if (tmp > (1 <<< FRAC))
            tmp = (1 <<< FRAC);

        // 4) 최종 QFRAC 확률 출력 (하위 W비트만 사용)
        p_q = tmp[W-1:0];
    end

endmodule


