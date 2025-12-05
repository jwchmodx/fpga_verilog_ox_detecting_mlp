`timescale 1ns/1ps

//====================================================
// prob_to_percent : QFRAC 확률 -> 0~100(%) 정수
//   - 반올림 로직 추가로 정밀도 향상
//====================================================
module prob_to_percent #(
    parameter W    = 8,
    parameter FRAC = 6
)(
    input      [W-1:0] p_q,          // 0~1 in QFRAC (0~64)
    output reg [6:0]   percent       // 0~100 (%), 7 bits면 충분
);
    wire [W+6:0] p_times100;  // p_q * 100
    
    // 1.0 (QFRAC 64) -> 100%
    // p_q * 100 / 64 계산
    
    assign p_times100 = p_q * 7'd100;

    always @(*) begin
        // 반올림을 위해 (Divisor / 2)를 더한 후 Shift
        // Divisor는 2^FRAC = 64, 반값은 32 (1<<(FRAC-1))
        // 식: (p_q * 100 + 32) >>> 6
        
        if ( ((p_times100 + (1<<(FRAC-1))) >>> FRAC) > 7'd100 )
            percent = 7'd100;
        else
            percent = (p_times100 + (1<<(FRAC-1))) >>> FRAC;
    end
endmodule
