`timescale 1ns/1ps

//====================================================
// sigmoid_fixed : y_score -> 시그모이드(근사) 확률(QFRAC)
//   - Score를 256으로 나눈 몫(x)과 나머지(fraction)를 이용한 선형 보간
//   - 반올림 로직을 추가하여 하위 비트 정보를 최대한 보존
//====================================================
module sigmoid_fixed #(
    parameter W      = 8,   // 확률 출력 비트폭
    parameter FRAC   = 6,   // QFRAC (1.0 = 64)
    parameter SHIFT  = 8,   // Score / 256
    parameter CLIP_X = 8    // 클리핑 범위
)(
    input  signed [W+4:0] z,    // y_score
    output reg   [W-1:0]  p_q   // QFRAC 확률 (0~64)
);
    // z를 256으로 나눈 몫 (정수부)
    reg signed [W+4:0] x;
    // 나머지 (소수부 대용, 0~255)
    reg [7:0] fraction;
    
    // 정밀도 향상을 위해 4비트 더 크게 계산 (FRAC+4)
    // 목표값: 32(0.5) << 4 = 512
    reg signed [W+FRAC+8:0] tmp_high_prec;

    always @* begin
        x = z >>> SHIFT;        // z / 256
        fraction = z[SHIFT-1:0]; // z % 256 (하위 8비트)

        // 기본값 계산 (QFRAC * 16 스케일로 계산하여 정밀도 확보)
        // 1.0 = 64 * 16 = 1024
        // 0.5 = 32 * 16 = 512
        
        // --- 양수 구간 (x >= 0) ---
        if (x == 0) begin
            // 0~255 구간: 0.5(512) -> 0.75(768)
            // 기울기: (768-512)/256 = 1
            tmp_high_prec = 512 + fraction; 
        end
        else if (x == 1) begin
            // 256~511 구간: 0.75(768) -> 0.875(896)
            // 기울기: (896-768)/256 = 0.5 -> fraction >> 1
            tmp_high_prec = 768 + (fraction >>> 1);
        end
        else if (x == 2) begin
            // 512~767 구간: 0.875(896) -> 0.9375(960)
            // 기울기: (960-896)/256 = 0.25 -> fraction >> 2
            tmp_high_prec = 896 + (fraction >>> 2);
        end
        else if (x == 3) begin
            // 768~1023 구간: 0.9375(960) -> 0.968(992)
            // 기울기: 0.125 -> fraction >> 3
            tmp_high_prec = 960 + (fraction >>> 3);
        end
        else if (x >= 4) begin
            tmp_high_prec = 1024; // 1.0
        end
        
        // --- 음수 구간 (x < 0) ---
        else if (x == -1) begin
            // -256~-1 구간: 0.25(256) -> 0.5(512)
            // 기울기: 1
            tmp_high_prec = 256 + fraction;
        end
        else if (x == -2) begin
            // -512~-257 구간: 0.125(128) -> 0.25(256)
            // 기울기: 0.5
            tmp_high_prec = 128 + (fraction >>> 1);
        end
        else if (x == -3) begin
            // -768~-513 구간: 0.06(64) -> 0.125(128)
            // 기울기: 0.25
            tmp_high_prec = 64 + (fraction >>> 2);
        end
        else if (x == -4) begin
            // -1024~-769 구간: 0.03(32) -> 0.06(64)
            tmp_high_prec = 32 + (fraction >>> 3);
        end
        else begin // x <= -5
            tmp_high_prec = 0;
        end

        // 최종 클리핑 및 반올림 (원래 QFRAC 스케일로 복귀)
        // 16으로 나누기 전에 반올림 (+8)
        if (tmp_high_prec < 0) 
            p_q = 0;
        else if (tmp_high_prec > 1024) 
            p_q = 64; // 1.0
        else
            p_q = (tmp_high_prec + 8) >>> 4;
    end
endmodule
