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
    input  btn_train,   // Train button to start training
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
    
    // Neural network signals
    wire nn_y;                         // NN output: O(1) vs X(0)
    wire [6:0] nn_o_prob_pct;         // Probability of O (0-100%)
    wire signed [12:0] nn_y_score;    // Raw output score
    wire signed [17:0] nn_hidden_score; // Hidden layer score
    
    // Training controller signals
    wire [15:0] train_x;               // Training input from controller
    wire train_learn;                  // Training mode enable
    wire train_is_O;                   // Training label (O=1, X=0)
    wire training_active;              // Training in progress
    wire [7:0] current_epoch;          // Current epoch number
    wire [7:0] current_sample;         // Current sample index
    wire training_done;                // Training complete flag
    
    // Neural network input multiplexer
    wire [15:0] nn_x_input;            // Input to NN (training or inference)
    wire nn_learn;                     // Learning mode (training or inference)
    wire nn_is_O;                      // Label (training mode only)
    
    // Control signals for neural network
    reg nn_execute;                    // Trigger NN execution after submit
    reg btn_submit_prev;

    // IN
    keypad_scan KS (.clk(clk), .rst(rst), .in_from_keypad(in_from_keypad), // input
                    .out_to_keypad(out_to_keypad), .out(w_value), .valid(w_valid)); // output

    // Combine keypad and buttons
    // Order: A,1,2,3 | B,4,5,6 | C,7,8,9 | D,*,0,#
    // Mapping:
    // [0-3]: A, 1, 2, 3
    // [4-7]: B, 4, 5, 6
    // [8-11]: C, 7, 8, 9
    // [12-15]: D, #, 0, * (Note: keypad.v output mapping matches this group)
    
    wire any_button_pressed = btn_a || btn_b || btn_c || btn_d;
    wire [11:0] keypad_masked = any_button_pressed ? 12'b0 : w_value;
    
    assign w_combined_value = {keypad_masked[8], keypad_masked[7], keypad_masked[6], btn_d,     // #, 0, *, D
                               keypad_masked[5], keypad_masked[4], keypad_masked[3], btn_c,    // 9, 8, 7, C
                               keypad_masked[2], keypad_masked[1], keypad_masked[0], btn_b,      // 6, 5, 4, B
                               keypad_masked[11], keypad_masked[10], keypad_masked[9], btn_a};     // 3, 2, 1, A
    
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
    
    // Training Controller - manages training data and process
    train_controller #(
        .NUM_EPOCHS(10),  // 에폭 수: 10
        .NUM_TRAIN_O(100),
        .NUM_TRAIN_X(100)
    ) TRAIN_CTRL (
        .clk(clk),
        .rst_n(rst),            // Corrected port name: rst_n
        .btn_train(btn_train),  
        .train_x(train_x),
        .train_learn(train_learn),
        .train_is_O(train_is_O),
        .training_active(training_active),
        .current_epoch(current_epoch),
        .current_sample(current_sample),
        .training_done(training_done)
    );
    
    // Multiplexer: Training mode or Inference mode
    assign nn_x_input = training_active ? train_x : combined_input_flags;
    assign nn_learn = training_active ? train_learn : 1'b0;
    assign nn_is_O = training_active ? train_is_O : 1'b0;
    
    // Neural Network - O vs X classifier
    mlp_OX #(
        .W(8),      // 8-bit weights
        .N(12),     // 히든 뉴런 수 증가: 8 -> 12 (학습 능력 향상)
        .FRAC(6)    // 6 fractional bits
    ) NN_OX (
        .clk(clk),
        .rst_n(rst),
        .x(nn_x_input),
        .learn(nn_learn),
        .is_O(nn_is_O),
        .y(nn_y),
        .o_prob_pct(nn_o_prob_pct),
        .y_score_out(nn_y_score),
        .hidden_score(nn_hidden_score)
    );
    
    // Neural network control logic
    always @(posedge clk or negedge rst) begin
        if (~rst) begin
            btn_submit_prev <= 0;
            nn_execute <= 0;
        end else begin
            btn_submit_prev <= btn_submit;
            
            // Detect submit button press (rising edge)
            if (btn_submit && !btn_submit_prev && !training_active) begin
                nn_execute <= 1;  // Trigger NN inference (only when not training)
            end else begin
                nn_execute <= 0;
            end
        end
    end

    // 7-segment display multiplexer
    wire [15:0] seg_display_data;
    wire seg_display_valid;
    wire seg_number_mode;    // 0: one-hot mode, 1: number display mode
    wire [15:0] epoch_display;  // Changed from reg to wire
    wire [7:0] prob_tens;    // Probability tens digit (0-10)
    wire [7:0] prob_ones;    // Probability ones digit (0-9)
    wire [15:0] prob_display; // Probability in BCD format
    wire [15:0] done_display; // "99" for training complete
    
    // Convert probability to tens and ones digits
    assign prob_tens = nn_o_prob_pct / 10;
    assign prob_ones = nn_o_prob_pct % 10;
    assign prob_display = {8'b0, prob_tens[3:0], prob_ones[3:0]};
    
    // Training complete display: "99" (완료 표시)
    assign done_display = {8'b0, 4'd9, 4'd9};  // 99 in BCD format
    
    // Convert epoch number to BCD format for number display
    // Display epoch number (0-19) as 2-digit number
    wire [3:0] epoch_tens = current_epoch / 10;  // 10의 자리 (0-1)
    wire [3:0] epoch_ones = current_epoch % 10;   // 1의 자리 (0-9)
    assign epoch_display = {8'b0, epoch_tens[3:0], epoch_ones[3:0]};  // BCD format
    
    // 키패드 매핑용 변수와 로직은 이제 불필요하므로 제거해도 되지만, 
    // 나중을 위해 주석 처리하거나 무시됨.
    
    // Display mode selector
    // Training complete: display "99" (number mode) for 3 seconds, then return to normal
    // Training mode: display epoch number (number mode, 0-19)
    // Submit 버튼 눌린 상태: display probability (number mode, 2 digits)
    // 키패드/버튼 입력: display current input (one-hot mode, 8 digits same value)
    // Inference mode: display current input (one-hot mode)
    
    // NOTE: w_combined_valid가 있을 때도 number_mode를 0으로 유지하여 
    // display_seg 모듈이 one-hot 매핑 테이블을 사용하도록 함.
    assign seg_display_data = done_display_active ? done_display :
                              (training_active ? epoch_display : 
                              (btn_submit ? prob_display : 
                              current_display)); // Use current_display directly
                              
    assign seg_display_valid = done_display_active ? 1'b1 :
                               (training_active ? 1'b1 : 
                               (btn_submit ? 1'b1 :  // submit 버튼 눌린 상태면 항상 유효
                               (w_combined_valid ? 1'b1 : display_valid)));  // 키패드/버튼 입력이면 유효
                               
    // NOTE: Removed w_combined_valid from number_mode condition
    assign seg_number_mode = (done_display_active || training_active || btn_submit) ? 1'b1 : 1'b0;

    // OUT - Display on 7-segment
    display_seg DP_SEG (
        .clk(clk),
        .rst(rst),
        .scan_data(seg_display_data),
        .valid(seg_display_valid),
        .number_mode(seg_number_mode),
        .r7(w_r[7]), .r6(w_r[6]), .r5(w_r[5]), .r4(w_r[4]),
        .r3(w_r[3]), .r2(w_r[2]), .r1(w_r[1]), .r0(w_r[0])
    );

    // LED display logic
    // Training mode: Show progress (running LEDs)
    // Inference mode: Show NN result
    reg nn_result_valid;  // Flag to show NN result
    reg training_done_prev;  // Previous state of training_done for edge detection
    reg [25:0] led_timer;  // Timer for LED (50MHz: 50,000,000 clocks = 1 second)
    reg led_complete_active;  // Flag for LED complete display (1 second)
    reg [26:0] done_display_timer;  // Timer for "99" display (50MHz: 150,000,000 clocks = 3 seconds)
    reg done_display_active;  // Flag for "99" display (3 seconds)
    reg [26:0] nn_result_timer;  // Timer for NN result display (50MHz: 150,000,000 clocks = 3 seconds)
    
    always @(posedge clk or negedge rst) begin
        if (~rst) begin
            out_to_led = 8'b00000000;
            nn_result_valid = 0;
            training_done_prev = 0;
            led_timer = 0;
            led_complete_active = 0;
            done_display_timer = 0;
            done_display_active = 0;
            nn_result_timer = 0;
        end else begin
            // Detect training_done rising edge
            if (training_done && !training_done_prev) begin
                led_complete_active = 1;
                led_timer = 0;
                done_display_active = 1;
                done_display_timer = 0;
            end
            training_done_prev = training_done;
            
            // "99" display timer: 3 seconds (150,000,000 clocks at 50MHz)
            if (done_display_active) begin
                if (done_display_timer >= 27'd150000000) begin
                    done_display_active = 0;
                    done_display_timer = 0;
                end else begin
                    done_display_timer = done_display_timer + 1;
                end
            end
            
            // nn_result_valid는 더 이상 사용하지 않음 (btn_submit으로 직접 제어)
            // submit 버튼이 떼어지면 자동으로 해제됨
            
            // LED timer: 1 second (50,000,000 clocks at 50MHz)
            if (led_complete_active) begin
                if (led_timer >= 26'd50000000) begin
                    led_complete_active = 0;
                    led_timer = 0;
                    out_to_led = 8'b00000000;
                end else begin
                    led_timer = led_timer + 1;
                    out_to_led = 8'b11111111;
                end
            end else if (training_active) begin
                // Training mode: Running LEDs to show activity
                nn_result_valid = 0;
                if (cnt_led == 4000000) cnt_led = 0;  // Faster animation during training
                else                    cnt_led = cnt_led + 1;
                case (cnt_led)
                    0:       out_to_led = 8'b00000001;
                    500000:  out_to_led = 8'b00000010;
                    1000000: out_to_led = 8'b00000100;
                    1500000: out_to_led = 8'b00001000;
                    2000000: out_to_led = 8'b00010000;
                    2500000: out_to_led = 8'b00100000;
                    3000000: out_to_led = 8'b01000000;
                    3500000: out_to_led = 8'b10000000;
                endcase
            end else begin
                // Inference mode
                // submit 버튼이 눌려있는 동안만 NN 결과 표시 (LED)
                if (btn_submit) begin
                    // LED[7]: O(1) or X(0)
                    // LED[6:0]: Probability bar (0-100% mapped to 0-7 LEDs)
                    out_to_led[7] = nn_y;
                    
                    // Probability bar: show LEDs based on confidence
                    // 0-14%: 0 LEDs, 14-28%: 1 LED, ... 85-100%: 7 LEDs
                    if (nn_o_prob_pct >= 85)      out_to_led[6:0] = 7'b1111111;
                    else if (nn_o_prob_pct >= 71) out_to_led[6:0] = 7'b0111111;
                    else if (nn_o_prob_pct >= 57) out_to_led[6:0] = 7'b0011111;
                    else if (nn_o_prob_pct >= 43) out_to_led[6:0] = 7'b0001111;
                    else if (nn_o_prob_pct >= 29) out_to_led[6:0] = 7'b0000111;
                    else if (nn_o_prob_pct >= 15) out_to_led[6:0] = 7'b0000011;
                    else                          out_to_led[6:0] = 7'b0000001;
                end else begin
                    // submit 버튼이 안 눌려있으면 LED off
                    out_to_led = 8'b00000000;
                end
            end
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
