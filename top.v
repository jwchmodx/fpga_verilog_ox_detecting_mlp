`timescale 1ns/1ps


module top (
    input  clk, // Calibrated for 50MHz
    input  rst,
    input  [2:0] in_from_keypad,
    input  btn_a,  // Extra button A
    input  btn_b,  // Extra button B
    input  btn_c,  // Extra button C
    input  btn_d,  // Extra button D
    input  btn_submit,  // Submit button to finalize input sequence
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
    wire [15:0] w_combined_value;  // Combined keypad (shifted) + buttons
    wire w_combined_valid;         // Valid signal for buttons or keypad
    wire [7:0] w_r [7:0];
    integer cnt_led;
    
    // Button edge detection
    reg btn_a_prev, btn_b_prev, btn_c_prev, btn_d_prev;
    wire btn_changed;
    
    // Input manager outputs
    wire [15:0] current_display;       // Current value to display on 7-seg
    wire display_valid;                // Display update signal
    wire [15:0] combined_input_flags;  // OR of all inputs (16-bit flags)
    wire [3:0] input_count;            // Number of inputs stored (for debug)

    // IN
    keypad_scan KS (.clk(clk), .rst(rst), .in_from_keypad(in_from_keypad), // input
                    .out_to_keypad(out_to_keypad), .out(w_value), .valid(w_valid)); // output

    // Combine keypad and buttons in specific order: A,1,2,3,B,4,5,6,C,7,8,9,D,*,0,#
    // bit[0]:A, bit[1]:1, bit[2]:2, bit[3]:3, bit[4]:B, bit[5]:4, bit[6]:5, bit[7]:6
    // bit[8]:C, bit[9]:7, bit[10]:8, bit[11]:9, bit[12]:D, bit[13]:*, bit[14]:0, bit[15]:#
    // Adjusted mapping: keypad scan has 1-clock delay, so shift by 3 positions
    // When button is pressed, ignore keypad values (use only buttons)
    wire any_button_pressed = btn_a || btn_b || btn_c || btn_d;
    wire [11:0] keypad_masked = any_button_pressed ? 12'b0 : w_value;
    
    assign w_combined_value = {keypad_masked[2], keypad_masked[1], keypad_masked[0], btn_d,     // #, 0, *, D
                               keypad_masked[11], keypad_masked[10], keypad_masked[9], btn_c,    // 9, 8, 7, C
                               keypad_masked[8], keypad_masked[7], keypad_masked[6], btn_b,      // 6, 5, 4, B
                               keypad_masked[5], keypad_masked[4], keypad_masked[3], btn_a};     // 3, 2, 1, A
    
    // Button change detection
    always @(posedge clk or negedge rst) begin
        if (~rst) begin
            btn_a_prev <= 0;
            btn_b_prev <= 0;
            btn_c_prev <= 0;
            btn_d_prev <= 0;
        end else begin
            btn_a_prev <= btn_a;
            btn_b_prev <= btn_b;
            btn_c_prev <= btn_c;
            btn_d_prev <= btn_d;
        end
    end
    
    assign btn_changed = (btn_a != btn_a_prev) || (btn_b != btn_b_prev) || 
                        (btn_c != btn_c_prev) || (btn_d != btn_d_prev);
    
    // Combined valid: keypad valid OR button changed OR any button pressed
    assign w_combined_valid = w_valid || btn_changed || btn_a || btn_b || btn_c || btn_d;

    // Input Manager - handles input accumulation and combination
    input_manager INPUT_MGR (
        .clk(clk),
        .rst(rst),
        .input_value(w_combined_value),
        .input_valid(w_combined_valid),
        .btn_submit(btn_submit),
        .current_display(current_display),
        .display_valid(display_valid),
        .combined_input_flags(combined_input_flags),
        .input_count(input_count)
    );

    // OUT - Display current input on 7-segment
    display_seg DP_SEG (
        .clk(clk),
        .rst(rst),
        .scan_data(current_display),
        .valid(display_valid),
        .r7(w_r[7]), .r6(w_r[6]), .r5(w_r[5]), .r4(w_r[4]),
        .r3(w_r[3]), .r2(w_r[2]), .r1(w_r[1]), .r0(w_r[0])
    );

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