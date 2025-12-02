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
    reg btn_train;                    // Train button
    
    // Output signals (declared as wire)
    wire [3:0] out_to_keypad;
    wire [7:0] out_to_led;
    wire [7:0] out_to_seg_data;
    wire [7:0] out_to_seg_en;
    wire lcd_e;
    wire lcd_rw;
    wire lcd_rs;
    wire [7:0] lcd_data;
    
    // Accuracy tracking (global)
    integer accuracy_before_O, accuracy_before_X, accuracy_before_total;
    integer accuracy_after_O, accuracy_after_X, accuracy_after_total;

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
        .btn_train(btn_train),
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
        btn_train = 0;   // Train button not pressed
        in_from_keypad = 3'b111;  // No key pressed
        
        // Initialize accuracy tracking
        accuracy_before_O = 0;
        accuracy_before_X = 0;
        accuracy_before_total = 0;
        accuracy_after_O = 0;
        accuracy_after_X = 0;
        accuracy_after_total = 0;
        
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
        // Pre-Training Test (Before Learning)
        // ----------------------------------------
        $display("\n========================================");
        $display("  Test 1: BEFORE Training");
        $display("========================================");
        test_predefined_patterns(1'b0);  // 0 = before training
        
        // ----------------------------------------
        // Training Test
        // ----------------------------------------
        $display("\n========================================");
        $display("  Test 2: Training Neural Network");
        $display("========================================");
        test_training();
        
        // ----------------------------------------
        // Post-Training Test (After Learning)
        // ----------------------------------------
        $display("\n========================================");
        $display("  Test 3: AFTER Training");
        $display("========================================");
        test_predefined_patterns(1'b1);  // 1 = after training
        
        // ----------------------------------------
        // Test End & Summary
        // ----------------------------------------
        $display("\n\n");
        $display("============================================================");
        $display("         TRAINING EFFECTIVENESS SUMMARY");
        $display("============================================================");
        $display("");
        $display("  +-------------+---------+---------+--------------+");
        $display("  |   Metric    | BEFORE  |  AFTER  | Improvement  |");
        $display("  +-------------+---------+---------+--------------+");
        $display("  | O Patterns  |  %2d/10  |  %2d/10  |    %+3d%%     |", 
                 accuracy_before_O, accuracy_after_O, 
                 (accuracy_after_O - accuracy_before_O) * 10);
        $display("  | X Patterns  |  %2d/10  |  %2d/10  |    %+3d%%     |", 
                 accuracy_before_X, accuracy_after_X, 
                 (accuracy_after_X - accuracy_before_X) * 10);
        $display("  | Total       |  %2d/20  |  %2d/20  |    %+3d%%     |", 
                 accuracy_before_total, accuracy_after_total, 
                 (accuracy_after_total - accuracy_before_total) * 5);
        $display("  +-------------+---------+---------+--------------+");
        $display("");
        $display("  Test Duration: %0t ns", $time);
        $display("  Training Status: %s", DUT.training_done ? "COMPLETED" : "FAILED");
        $display("\n============================================================\n");
        
        #1000;
        $finish;
    end

    // =========================================
    // Monitoring (Main Signal Change Detection)
    // =========================================
    
    // Training progress monitoring
    always @(DUT.current_epoch) begin
        if (DUT.training_active)
            $display("[%0t ns] Epoch: %0d", $time, DUT.current_epoch);
    end
    
    always @(DUT.training_done) begin
        if (DUT.training_done)
            $display("[%0t ns] TRAINING COMPLETE!", $time);
    end
    
    // LED change monitoring (with neural network result interpretation)
    always @(out_to_led) begin
        if (DUT.training_active) begin
            // During training, don't spam LED changes
        end else if (DUT.training_done) begin
            $display("[%0t ns] LED: Training Done - All LEDs ON", $time);
        end else if (DUT.nn_result_valid) begin
            $display("[%0t ns] LED Change (NN Result): %b [LED[7]=%s, Confidence=%0d%%]", 
                     $time, out_to_led, out_to_led[7] ? "O" : "X", DUT.nn_o_prob_pct);
        end
    end
    
    // 7-segment data change monitoring (commented out to reduce spam)
    // always @(out_to_seg_data) begin
    //     if (out_to_seg_data != 8'h00)
    //         $display("[%0t ns] SEG_DATA Change: %h (binary: %b)", $time, out_to_seg_data, out_to_seg_data);
    // end
    
    // Monitor input accumulation (only in inference mode)
    always @(DUT.INPUT_MGR.input_count) begin
        if (!DUT.training_active && DUT.INPUT_MGR.input_count > 0)
            $display("[%0t ns] Input count: %d, Current display: %b", 
                     $time, DUT.INPUT_MGR.input_count, DUT.current_display);
    end
    
    // Keypad scan output monitoring (commented out to prevent excessive output)
    // always @(out_to_keypad) begin
    //     $display("[%0t ns] KEYPAD_SCAN: %b", $time, out_to_keypad);
    // end
    
    // Task: Test training mode
    task test_training;
        integer wait_cycles;
        begin
            $display("\n  Starting training...");
            $display("  Press train button...");
            
            // Press train button
            btn_train = 1;
            repeat(100) @(posedge clk);
            btn_train = 0;
            
            $display("  Training started. Waiting for completion...");
            
            // Wait for training to complete (monitor training_active signal)
            wait_cycles = 0;
            while (DUT.training_active || !DUT.training_done) begin
                @(posedge clk);
                wait_cycles = wait_cycles + 1;
                
                // Print epoch progress every 5k cycles
                if (wait_cycles % 5000 == 0) begin
                    $display("    [%0t] Training... Epoch: %0d, Sample: %0d", 
                             $time, DUT.current_epoch, DUT.current_sample);
                end
                
                // Timeout after 5M cycles (safety)
                if (wait_cycles > 5000000) begin
                    $display("  ERROR: Training timeout!");
                    $finish;
                end
            end
            
            $display("\n  ========================================");
            $display("  Training Complete!");
            $display("  Total cycles: %0d", wait_cycles);
            $display("  Total time: %0t ns", $time);
            $display("  ========================================\n");
            
            // Wait a bit after training
            repeat(10000) @(posedge clk);
        end
    endtask
    
    // Task: Test with predefined O and X patterns
    task test_predefined_patterns;
        input is_after_training;  // 0=before, 1=after
        integer i;
        integer correct_O, correct_X, total_correct;
        reg [15:0] test_O [0:9];
        reg [15:0] test_X [0:9];
        reg is_correct;
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
            
            $display("=== Testing O Patterns (Expected: O) ===");
            for (i = 0; i < 10; i = i + 1) begin
                test_single_pattern(test_O[i], 1'b1, is_correct);  // 1=O is expected
                if (is_correct) correct_O = correct_O + 1;
            end
            
            $display("\n=== Testing X Patterns (Expected: X) ===");
            for (i = 0; i < 10; i = i + 1) begin
                test_single_pattern(test_X[i], 1'b0, is_correct);  // 0=X is expected
                if (is_correct) correct_X = correct_X + 1;
            end
            
            // Calculate total
            total_correct = correct_O + correct_X;
            
            // Store results in global variables
            if (is_after_training) begin
                accuracy_after_O = correct_O;
                accuracy_after_X = correct_X;
                accuracy_after_total = total_correct;
            end else begin
                accuracy_before_O = correct_O;
                accuracy_before_X = correct_X;
                accuracy_before_total = total_correct;
            end
            
            // Display accuracy
            $display("\n========================================");
            $display("=== Classification Results ===");
            $display("========================================");
            $display("  O patterns: %0d/10 correct (%.1f%%)", correct_O, correct_O * 10.0);
            $display("  X patterns: %0d/10 correct (%.1f%%)", correct_X, correct_X * 10.0);
            $display("  Total: %0d/20 correct (%.1f%%)", total_correct, total_correct * 5.0);
            $display("========================================\n");
        end
    endtask
    
    // Task: Test single pattern
    task test_single_pattern;
        input [15:0] pattern;
        input expected_O;  // 1 if expecting O, 0 if expecting X
        output is_correct; // Output: whether prediction was correct
        reg result;
        begin
            // Directly inject pattern into input_manager's combined_input_flags
            force DUT.INPUT_MGR.combined_input_flags = pattern;
            
            // Trigger neural network computation
            btn_submit = 1;
            repeat(100) @(posedge clk);
            
            // Capture result before any changes
            result = DUT.nn_y;
            is_correct = (result == expected_O);
            
            // Display results (simple format)
            $display("  %04h: Expected=%s, Got=%s, Prob=%0d%% [%s]", 
                     pattern, 
                     expected_O ? "O" : "X", 
                     result ? "O" : "X", 
                     DUT.nn_o_prob_pct,
                     is_correct ? "OK" : "FAIL");
            
            // Release submit and force
            btn_submit = 0;
            release DUT.INPUT_MGR.combined_input_flags;
            repeat(50) @(posedge clk);  // Reduced wait time
        end
    endtask

endmodule

