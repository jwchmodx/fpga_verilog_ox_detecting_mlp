module top (
    input  clk, // Calibrated for 50MHz
    input  rst,
    input  [2:0] in_from_keypad,
    output [3:0] out_to_keypad,
    output reg [7:0] out_to_led,
    output [7:0] out_to_seg_data,
    output [7:0] out_to_seg_en,
    output lcd_e,
    output lcd_rw,
    output lcd_rs,
    output [7:0] lcd_data
);

    wire w_valid;
    wire [11:0] w_value;
    wire [7:0] w_r [7:0];
    integer cnt_led;

    // IN
    keypad_scan KS (.clk(clk), .rst(rst), .in_from_keypad(in_from_keypad), // input
                    .out_to_keypad(out_to_keypad), .out(w_value), .valid(w_valid)); // output

    // TO-DO
    // Design your logics here

    // OUT
    display_seg DP_SEG (.clk(clk), .rst(rst), .scan_data(w_value), .valid(w_valid), // input
                        .r7(w_r[7]), .r6(w_r[6]), .r5(w_r[5]), .r4(w_r[4]), // output
                        .r3(w_r[3]), .r2(w_r[2]), .r1(w_r[1]), .r0(w_r[0]));

    always @(posedge clk or negedge rst) begin
        if (~rst)    out_to_led = 8'b00000000;
        else begin
            if (cnt_led == 16000000) cnt_led = 0;
            else                     cnt_led = cnt_led + 1;
            case (cnt_led)
                0:        out_to_led = 8'b00000001;
                2000000:  out_to_led = 8'b00000010;
                4000000:  out_to_led = 8'b00000100;
                6000000:  out_to_led = 8'b00001000;
                8000000:  out_to_led = 8'b00010000;
                10000000: out_to_led = 8'b00100000;
                12000000: out_to_led = 8'b01000000;
                14000000: out_to_led = 8'b10000000;
            endcase
        end
    end

    seg_controller #(.MAX_CNT_CLK(1024)
    ) SEG_CTRL (
        .clk(clk), .rst(rst), // input
        .seg_7(w_r[7]), .seg_6(w_r[6]), .seg_5(w_r[5]), .seg_4(w_r[4]),
        .seg_3(w_r[3]), .seg_2(w_r[2]), .seg_1(w_r[1]), .seg_0(w_r[0]),
        .seg_data(out_to_seg_data), .seg_en(out_to_seg_en)); // output

    text_lcd TXL (.clk(clk), .rst(rst), // input
                  .lcd_e(lcd_e), .lcd_rw(lcd_rw), .lcd_rs(lcd_rs), .lcd_data(lcd_data)); // output

endmodule