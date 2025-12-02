`timescale 1ns / 1ps

module tb_top;

    // =========================================
    // 테스트벤치 신호 선언
    // =========================================
    
    // 입력 신호 (reg로 선언)
    reg clk;
    reg rst;
    reg [2:0] in_from_keypad;
    
    // 출력 신호 (wire로 선언)
    wire [3:0] out_to_keypad;
    wire [7:0] out_to_led;
    wire [7:0] out_to_seg_data;
    wire [7:0] out_to_seg_en;
    wire lcd_e;
    wire lcd_rw;
    wire lcd_rs;
    wire [7:0] lcd_data;

    // =========================================
    // DUT (Device Under Test) 인스턴스화
    // =========================================
    top DUT (
        .clk(clk),
        .rst(rst),
        .in_from_keypad(in_from_keypad),
        .out_to_keypad(out_to_keypad),
        .out_to_led(out_to_led),
        .out_to_seg_data(out_to_seg_data),
        .out_to_seg_en(out_to_seg_en),
        .lcd_e(lcd_e),
        .lcd_rw(lcd_rw),
        .lcd_rs(lcd_rs),
        .lcd_data(lcd_data)
    );

    // =========================================
    // 클럭 생성 (50MHz = 20ns 주기)
    // =========================================
    parameter CLK_PERIOD = 20; // 50MHz
    
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // =========================================
    // 테스트 시퀀스
    // =========================================
    initial begin
        // 파형 덤프 (시뮬레이터에서 파형 확인용)
        $dumpfile("tb_top.vcd");
        $dumpvars(0, tb_top);
        
        // 초기화
        rst = 1;
        in_from_keypad = 3'b111; // 키패드 눌리지 않은 상태 (pull-up)
        
        // 리셋 시퀀스
        #100;
        rst = 0;  // 리셋 활성화 (active low)
        #200;
        rst = 1;  // 리셋 해제
        #100;
        
        $display("========================================");
        $display("테스트 시작: %0t ns", $time);
        $display("========================================");
        
        // ----------------------------------------
        // 테스트 1: LED 순차 점등 확인
        // ----------------------------------------
        $display("\n[테스트 1] LED 순차 점등 테스트");
        // LED가 바뀌는 것을 확인하기 위해 일정 시간 대기
        // 실제로는 2000000 클럭 사이클이 필요하지만, 시뮬레이션에서는 축소
        repeat(1000) @(posedge clk);
        $display("  LED 상태: %b", out_to_led);
        
        // ----------------------------------------
        // 테스트 2: 키패드 입력 테스트
        // ----------------------------------------
        $display("\n[테스트 2] 키패드 입력 테스트");
        
        // 키패드 입력 시뮬레이션 (여러 키 조합)
        // out_to_keypad 스캔 신호에 따라 in_from_keypad 응답
        
        // 키 '1' 입력 시뮬레이션
        wait(out_to_keypad == 4'b1110);
        in_from_keypad = 3'b110;  // 첫 번째 열, 첫 번째 행 키 눌림
        #(CLK_PERIOD * 100);
        in_from_keypad = 3'b111;  // 키 해제
        $display("  키 '1' 입력 완료 at %0t ns", $time);
        
        #(CLK_PERIOD * 500);
        
        // 키 '5' 입력 시뮬레이션
        wait(out_to_keypad == 4'b1101);
        in_from_keypad = 3'b101;  // 두 번째 열, 두 번째 행 키 눌림
        #(CLK_PERIOD * 100);
        in_from_keypad = 3'b111;  // 키 해제
        $display("  키 '5' 입력 완료 at %0t ns", $time);
        
        #(CLK_PERIOD * 500);
        
        // 키 '9' 입력 시뮬레이션
        wait(out_to_keypad == 4'b1011);
        in_from_keypad = 3'b011;  // 세 번째 열, 세 번째 행 키 눌림
        #(CLK_PERIOD * 100);
        in_from_keypad = 3'b111;  // 키 해제
        $display("  키 '9' 입력 완료 at %0t ns", $time);
        
        #(CLK_PERIOD * 500);
        
        // ----------------------------------------
        // 테스트 3: 7세그먼트 출력 확인
        // ----------------------------------------
        $display("\n[테스트 3] 7세그먼트 출력 테스트");
        repeat(100) @(posedge clk);
        $display("  SEG_DATA: %h, SEG_EN: %b", out_to_seg_data, out_to_seg_en);
        
        // ----------------------------------------
        // 테스트 4: LCD 출력 확인
        // ----------------------------------------
        $display("\n[테스트 4] LCD 출력 테스트");
        repeat(100) @(posedge clk);
        $display("  LCD_E: %b, LCD_RW: %b, LCD_RS: %b, LCD_DATA: %h", 
                 lcd_e, lcd_rw, lcd_rs, lcd_data);
        
        // ----------------------------------------
        // 추가 동작 관찰
        // ----------------------------------------
        $display("\n[테스트 5] 추가 동작 관찰");
        repeat(5000) @(posedge clk);
        
        // ----------------------------------------
        // 테스트 종료
        // ----------------------------------------
        $display("\n========================================");
        $display("테스트 종료: %0t ns", $time);
        $display("========================================");
        
        #1000;
        $finish;
    end

    // =========================================
    // 모니터링 (주요 신호 변화 감지)
    // =========================================
    
    // LED 변화 모니터링
    always @(out_to_led) begin
        $display("[%0t ns] LED 변화: %b", $time, out_to_led);
    end
    
    // 7세그먼트 enable 변화 모니터링
    always @(out_to_seg_en) begin
        $display("[%0t ns] SEG_EN 변화: %b, SEG_DATA: %h", $time, out_to_seg_en, out_to_seg_data);
    end
    
    // 키패드 스캔 출력 모니터링 (너무 많은 출력 방지를 위해 주석 처리)
    // always @(out_to_keypad) begin
    //     $display("[%0t ns] KEYPAD_SCAN: %b", $time, out_to_keypad);
    // end

endmodule

