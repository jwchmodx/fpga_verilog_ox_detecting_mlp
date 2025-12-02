`timescale 1ns / 1ps

module tb_top;

    // =========================================
    // Testbench Signal Declaration
    // =========================================
    
    // Input signals (declared as reg)
    reg clk;
    reg rst;
    reg [2:0] in_from_keypad;
    reg btn_a, btn_b, btn_c, btn_d;  // 4 extra buttons
    reg btn_submit;                   // Submit button
    
    // Output signals (declared as wire)
    wire [3:0] out_to_keypad;
    wire [7:0] out_to_led;
    wire [7:0] out_to_seg_data;
    wire [7:0] out_to_seg_en;
    wire lcd_e;
    wire lcd_rw;
    wire lcd_rs;
    wire [7:0] lcd_data;

    // =========================================
    // DUT (Device Under Test) Instantiation
    // =========================================
    top DUT (
        .clk(clk),
        .rst(rst),
        .in_from_keypad(in_from_keypad),
        .btn_a(btn_a),
        .btn_b(btn_b),
        .btn_c(btn_c),
        .btn_d(btn_d),
        .btn_submit(btn_submit),
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
    // Clock Generation (50MHz = 20ns period)
    // =========================================
    parameter CLK_PERIOD = 20; // 50MHz
    
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // =========================================
    // Test Sequence
    // =========================================
    initial begin
        // Waveform dump (for viewing in simulator)
        $dumpfile("tb_top.vcd");
        $dumpvars(0, tb_top);
        
        // Initialization
        rst = 1;
        btn_a = 0; btn_b = 0; btn_c = 0; btn_d = 0;  // Buttons not pressed
        btn_submit = 0;  // Submit button not pressed
        in_from_keypad = 3'b111;  // No key pressed
        
        // Reset sequence
        #100;
        rst = 0;  // Assert reset (active low)
        #200;
        rst = 1;  // Deassert reset
        #100;
        
        $display("========================================");
        $display("Test Start: %0t ns", $time);
        $display("========================================");
        
        // ----------------------------------------
        // Neural Network Test with Predefined Data
        // ----------------------------------------
        $display("\n[Test] Neural Network O/X Classification");
        test_predefined_patterns();
        
        // ----------------------------------------
        // Test End
        // ----------------------------------------
        $display("\n========================================");
        $display("Test End: %0t ns", $time);
        $display("========================================");
        
        #1000;
        $finish;
    end

    // =========================================
    // Monitoring (Main Signal Change Detection)
    // =========================================
    
    // LED change monitoring (with neural network result interpretation)
    always @(out_to_led) begin
        if (DUT.nn_result_valid) begin
            $display("[%0t ns] LED Change (NN Result): %b [LED[7]=%s, Confidence=%0d%%]", 
                     $time, out_to_led, out_to_led[7] ? "O" : "X", DUT.nn_o_prob_pct);
        end else begin
            $display("[%0t ns] LED Change: %b", $time, out_to_led);
        end
    end
    
    // 7-segment data change monitoring (more detailed)
    always @(out_to_seg_data) begin
        if (out_to_seg_data != 8'h00)
            $display("[%0t ns] SEG_DATA Change: %h (binary: %b)", $time, out_to_seg_data, out_to_seg_data);
    end
    
    // Monitor input accumulation
    always @(DUT.INPUT_MGR.input_count) begin
        if (DUT.INPUT_MGR.input_count > 0)
            $display("[%0t ns] Input count: %d, Current display: %b", 
                     $time, DUT.INPUT_MGR.input_count, DUT.current_display);
    end
    
    // Keypad scan output monitoring (commented out to prevent excessive output)
    // always @(out_to_keypad) begin
    //     $display("[%0t ns] KEYPAD_SCAN: %b", $time, out_to_keypad);
    // end
    
    // Task: Test with predefined O and X patterns
    task test_predefined_patterns;
        integer i;
        integer correct_O, correct_X, total_correct;
        reg [15:0] test_O [0:9];
        reg [15:0] test_X [0:9];
        begin
            // Initialize test data (from tb_ox_mlp.v)
            test_O[0] = 16'b0111110110011111;
            test_O[1] = 16'b1111100110010111;
            test_O[2] = 16'b1111100010011111;
            test_O[3] = 16'b1111100110010101;
            test_O[4] = 16'b1111000110001111;
            test_O[5] = 16'b0111100110001111;
            test_O[6] = 16'b1111100110010010;
            test_O[7] = 16'b0111000110011111;
            test_O[8] = 16'b1101100110010111;
            test_O[9] = 16'b1111100010011101;
            
            test_X[0] = 16'b1001011001101101;
            test_X[1] = 16'b1001010000101001;
            test_X[2] = 16'b0001011001001001;
            test_X[3] = 16'b1001011000101000;
            test_X[4] = 16'b1001011001100001;
            test_X[5] = 16'b1001011001111001;
            test_X[6] = 16'b0101011001101010;
            test_X[7] = 16'b1001001000101101;
            test_X[8] = 16'b0001010000101001;
            test_X[9] = 16'b1001011101101001;
            
            correct_O = 0;
            correct_X = 0;
            
            $display("\n=== Testing O Patterns (Expected: O) ===");
            for (i = 0; i < 10; i = i + 1) begin
                $display("\n[Test O #%0d]", i+1);
                test_single_pattern(test_O[i], 1'b1);  // 1=O is expected
                if (DUT.nn_y == 1'b1) correct_O = correct_O + 1;
            end
            
            $display("\n\n=== Testing X Patterns (Expected: X) ===");
            for (i = 0; i < 10; i = i + 1) begin
                $display("\n[Test X #%0d]", i+1);
                test_single_pattern(test_X[i], 1'b0);  // 0=X is expected
                if (DUT.nn_y == 1'b0) correct_X = correct_X + 1;
            end
            
            // Display accuracy
            total_correct = correct_O + correct_X;
            $display("\n\n========================================");
            $display("=== Classification Results ===");
            $display("========================================");
            $display("  O patterns: %0d/10 correct (%.1f%%)", correct_O, correct_O * 10.0);
            $display("  X patterns: %0d/10 correct (%.1f%%)", correct_X, correct_X * 10.0);
            $display("  Total: %0d/20 correct (%.1f%%)", total_correct, total_correct * 5.0);
            $display("========================================");
        end
    endtask
    
    // Task: Test single pattern
    task test_single_pattern;
        input [15:0] pattern;
        input expected_O;  // 1 if expecting O, 0 if expecting X
        begin
            $display("  Pattern: %b (hex: %04h)", pattern, pattern);
            $display("  Expected: %s", expected_O ? "O" : "X");
            
            // Directly inject pattern into input_manager's combined_input_flags
            force DUT.INPUT_MGR.combined_input_flags = pattern;
            
            // Trigger neural network computation
            btn_submit = 1;
            repeat(100) @(posedge clk);
            
            // Display results
            $display("  Result: %s (Probability: %0d%%)", DUT.nn_y ? "O" : "X", DUT.nn_o_prob_pct);
            $display("  Correct: %s", (DUT.nn_y == expected_O) ? "YES ✓" : "NO ✗");
            $display("  LED: %b [bit7=%s, confidence=%0d%%]", 
                     DUT.out_to_led, DUT.out_to_led[7] ? "O" : "X", DUT.nn_o_prob_pct);
            
            // Release submit and force
            btn_submit = 0;
            release DUT.INPUT_MGR.combined_input_flags;
            repeat(100) @(posedge clk);
        end
    endtask

endmodule

