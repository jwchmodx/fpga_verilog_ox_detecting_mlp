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
        // Random Input Sequence Test
        // ----------------------------------------
        $display("\n[Test] Random Input Sequence (10 inputs)");
        test_random_sequence(10);
        
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
    
    // LED change monitoring
    always @(out_to_led) begin
        $display("[%0t ns] LED Change: %b", $time, out_to_led);
    end
    
    // 7-segment data change monitoring (more detailed)
    always @(out_to_seg_data) begin
        if (out_to_seg_data != 8'h00)
            $display("[%0t ns] SEG_DATA Change: %h (binary: %b)", $time, out_to_seg_data, out_to_seg_data);
    end
    
    // Monitor input accumulation
    always @(DUT.input_count) begin
        if (DUT.input_count > 0)
            $display("[%0t ns] Input count: %d, Current display: %b", 
                     $time, DUT.input_count, DUT.current_display);
    end
    
    // Keypad scan output monitoring (commented out to prevent excessive output)
    // always @(out_to_keypad) begin
    //     $display("[%0t ns] KEYPAD_SCAN: %b", $time, out_to_keypad);
    // end
    
    // Task: Press a button (A/B/C/D) with random hold time
    task press_button;
        input [3:0] button_id;  // 0=A, 1=B, 2=C, 3=D
        input integer hold_time_us;  // Hold time in microseconds
        integer hold_cycles;
        begin
            hold_cycles = hold_time_us * 50;  // Convert us to clock cycles (50MHz)
            
            case (button_id)
                0: begin
                    $display("  [%0t] Pressing Button A for %0d us", $time, hold_time_us);
                    btn_a = 1;
                    repeat(hold_cycles) @(posedge clk);
                    btn_a = 0;
                end
                1: begin
                    $display("  [%0t] Pressing Button B for %0d us", $time, hold_time_us);
                    btn_b = 1;
                    repeat(hold_cycles) @(posedge clk);
                    btn_b = 0;
                end
                2: begin
                    $display("  [%0t] Pressing Button C for %0d us", $time, hold_time_us);
                    btn_c = 1;
                    repeat(hold_cycles) @(posedge clk);
                    btn_c = 0;
                end
                3: begin
                    $display("  [%0t] Pressing Button D for %0d us", $time, hold_time_us);
                    btn_d = 1;
                    repeat(hold_cycles) @(posedge clk);
                    btn_d = 0;
                end
            endcase
            
            repeat(1000) @(posedge clk);  // Wait for processing
        end
    endtask
    
    // Task: Press a keypad key with random hold time
    task press_keypad_with_duration;
        input [3:0] target_row;
        input [2:0] target_column;
        input integer hold_time_us;
        integer hold_cycles;
        integer timeout;
        integer i;
        begin
            hold_cycles = hold_time_us * 50;  // Convert us to clock cycles
            $display("  [%0t] Pressing keypad (row=%b, col=%b) for %0d us", 
                     $time, target_row, target_column, hold_time_us);
            
            // Wait for the target row to be scanned
            timeout = 0;
            while (out_to_keypad != target_row && timeout < 10000) begin
                @(posedge clk);
                timeout = timeout + 1;
            end
            
            if (timeout < 10000) begin
                // Hold key for specified duration
                for (i = 0; i < hold_cycles; i = i + 1) begin
                    if (out_to_keypad == target_row)
                        in_from_keypad = target_column;
                    else
                        in_from_keypad = 3'b111;
                    @(posedge clk);
                end
            end
            
            // Release key
            in_from_keypad = 3'b111;
            repeat(1000) @(posedge clk);  // Wait for processing
        end
    endtask
    
    // Task: Test random input sequence
    task test_random_sequence;
        input integer num_inputs;
        integer i, input_type, hold_time;
        integer row, col;
        begin
            $display("\n  Generating %0d random inputs...", num_inputs);
            
            for (i = 0; i < num_inputs; i = i + 1) begin
                // Random input type (0-15 for 16 possible inputs)
                input_type = $urandom % 16;
                // Random hold time between 100us to 1100us (realistic button press)
                hold_time = 100 + ($urandom % 1000);
                
                $display("\n  Input #%0d: Type=%0d", i+1, input_type);
                
                // Determine which button/key to press
                case (input_type)
                    0:  press_button(0, hold_time);  // Button A
                    1:  press_keypad_with_duration(4'b0100, 3'b100, hold_time);  // Key 1
                    2:  press_keypad_with_duration(4'b0100, 3'b010, hold_time);  // Key 2
                    3:  press_keypad_with_duration(4'b0100, 3'b001, hold_time);  // Key 3
                    4:  press_button(1, hold_time);  // Button B
                    5:  press_keypad_with_duration(4'b0010, 3'b100, hold_time);  // Key 4
                    6:  press_keypad_with_duration(4'b0010, 3'b010, hold_time);  // Key 5
                    7:  press_keypad_with_duration(4'b0010, 3'b001, hold_time);  // Key 6
                    8:  press_button(2, hold_time);  // Button C
                    9:  press_keypad_with_duration(4'b0001, 3'b100, hold_time);  // Key 7
                    10: press_keypad_with_duration(4'b0001, 3'b010, hold_time);  // Key 8
                    11: press_keypad_with_duration(4'b0001, 3'b001, hold_time);  // Key 9
                    12: press_button(3, hold_time);  // Button D
                    13: press_keypad_with_duration(4'b1000, 3'b100, hold_time);  // Key *
                    14: press_keypad_with_duration(4'b1000, 3'b010, hold_time);  // Key 0
                    15: press_keypad_with_duration(4'b1000, 3'b001, hold_time);  // Key #
                endcase
            end
            
            // Display final buffer contents
            $display("\n\n=== Final Input Buffer ===");
            $display("  Total inputs captured: %0d", DUT.input_count);
            $display("\n  Individual 16-bit values:");
            for (i = 0; i < DUT.input_count; i = i + 1) begin
                $display("    Buffer[%2d]: %b (hex: %04h, dec: %0d)", 
                         i, DUT.input_buffer[i], DUT.input_buffer[i], DUT.input_buffer[i]);
            end
            
            // Press submit button
            $display("\n  Pressing SUBMIT button...");
            btn_submit = 1;
            repeat(10000) @(posedge clk);  // 200us - wait for combination logic
            
            // Display combined flags stored in DUT (AFTER submit)
            $display("\n  Combined 16-bit flags (stored in top.v):");
            $display("    %b (hex: %04h)", DUT.combined_input_flags, DUT.combined_input_flags);
            $display("    bit[15:0] = [#,0,*,D,9,8,7,C,6,5,4,B,3,2,1,A]");
            
            btn_submit = 0;
            repeat(5000) @(posedge clk);
            
            $display("\n  After submit released - Input count: %d", DUT.input_count);
        end
    endtask

endmodule

