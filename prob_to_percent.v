`timescale 1ns/1ps

//====================================================
// prob_to_percent : QFRAC 확률 -> 0~100(%) 정수
//====================================================
module prob_to_percent #(
    parameter W    = 8,
    parameter FRAC = 6
)(
    input      [W-1:0] p_q,          // 0~1 in QFRAC
    output reg [6:0]   percent       // 0~100 (%), 7 bits면 충분
);
    wire [W+6:0] p_times100;  // p_q * 100

    assign p_times100 = p_q * 7'd100;

    always @(*) begin
        // QFRAC 비트 제거 후 정수화
        if ( (p_times100 >>> FRAC) > 7'd100 )
            percent = 7'd100;
        else
            percent = p_times100 >>> FRAC;
    end
endmodule


