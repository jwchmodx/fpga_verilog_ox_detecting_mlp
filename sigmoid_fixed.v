`timescale 1ns/1ps

//====================================================
// sigmoid_fixed : y_score -> 시그모이드(근사) 확률(QFRAC)
//   - 하드웨어 친화적인 hard-sigmoid 근사
//   - p(x) ≈ 0.5 + x/8, x∈[-4,4], 그 밖은 0 또는 1로 클리핑
//   - 입력 z는 꽤 큰 값일 수 있어서 z >> SHIFT로 먼저 스케일링
//====================================================
module sigmoid_fixed #(
    parameter W      = 8,   // 확률 출력 비트폭
    parameter FRAC   = 6,   // QFRAC (1.0 = 1<<FRAC)
    parameter SHIFT  = 10,   // 입력 스코어 스케일링: z_scaled = z >>> SHIFT
    parameter CLIP_X = 4    // 선형 구간 [-CLIP_X, +CLIP_X]
)(
    input  signed [W+4:0] z,    // y_score (mlp_output_score에서 나오는 raw score)
    output reg   [W-1:0]  p_q   // QFRAC 확률 (0.0~1.0)
);
    // z를 SHIFT 만큼 줄인 값 (정수 영역)
    reg signed [W+4:0] x;

    // 중간 계산용 (부호 포함, 약간 넉넉하게 잡음)
    reg signed [W+FRAC+1:0] tmp;

    always @* begin
        // 1) 입력 스코어 스케일링
        x = z >>> SHIFT;

        // 2) hard-sigmoid 근사
        //    - x <= -CLIP_X → p=0
        //    - x >=  CLIP_X → p=1
        //    - 그 사이는 p ≈ 0.5 + x/8
        if (x <= -CLIP_X) begin
            tmp = 0;
        end
        else if (x >= CLIP_X) begin
            tmp = (1 <<< FRAC);   // 1.0 in QFRAC
        end
        else begin
            // p ≈ 0.5 + x/8
            // 0.5 → 1<<(FRAC-1)
            // x/8 → x * 2^(FRAC-3) in QFRAC
            tmp = (1 <<< (FRAC-1)) + (x <<< (FRAC-3));

            // 안전하게 0~1 범위로 한 번 더 클리핑
            if (tmp < 0)
                tmp = 0;
            else if (tmp > (1 <<< FRAC))
                tmp = (1 <<< FRAC);
        end

        // 3) 최종 QFRAC 확률 출력 (하위 W비트만 사용)
        p_q = tmp[W-1:0];
    end

endmodule


