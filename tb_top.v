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
        // Test 1: LED Sequential Lighting Test
        // ----------------------------------------
        $display("\n[Test 1] LED Sequential Lighting Test");
        // Wait to observe LED changes
        // In real hardware, 2000000 clock cycles needed, but reduced for simulation
        repeat(100) @(posedge clk);  // Reduced for faster simulation
        $display("  LED State: %b", out_to_led);
        
        // ----------------------------------------
        // Test 2: Button Input Test (A, B, C, D)
        // ----------------------------------------
        $display("\n[Test 2] Button Input Test");
        $display("  Mapping: A=0, B=4, C=8, D=C");
        
        // Button A test (bit[0] -> displays '0')
        $display("  Button A press (bit[0] -> should display '0')");
        btn_a = 1;
        repeat(50) @(posedge clk);
        $display("    SEG_DATA: %h at %0t ns", out_to_seg_data, $time);
        repeat(50) @(posedge clk);
        btn_a = 0;
        repeat(200) @(posedge clk);
        
        // Button B test (bit[4] -> displays '4')
        $display("  Button B press (bit[4] -> should display '4')");
        btn_b = 1;
        repeat(50) @(posedge clk);
        $display("    SEG_DATA: %h at %0t ns", out_to_seg_data, $time);
        repeat(50) @(posedge clk);
        btn_b = 0;
        repeat(200) @(posedge clk);
        
        // Button C test (bit[8] -> displays '8')
        $display("  Button C press (bit[8] -> should display '8')");
        btn_c = 1;
        repeat(50) @(posedge clk);
        $display("    SEG_DATA: %h at %0t ns", out_to_seg_data, $time);
        repeat(50) @(posedge clk);
        btn_c = 0;
        repeat(200) @(posedge clk);
        
        // Button D test (bit[12] -> displays 'C')
        $display("  Button D press (bit[12] -> should display 'C')");
        btn_d = 1;
        repeat(50) @(posedge clk);
        $display("    SEG_DATA: %h at %0t ns", out_to_seg_data, $time);
        repeat(50) @(posedge clk);
        btn_d = 0;
        repeat(200) @(posedge clk);
        
        // ----------------------------------------
        // Test 3: Keypad Input Test (All keys)
        // ----------------------------------------
        $display("\n[Test 3] Keypad Input Test");
        $display("  Mapping: 1=1, 2=2, 3=3, 4=5, 5=6, 6=7, 7=9, 8=A, 9=B, *=D, 0=E, #=F");
        
        // Key '1' (bit[1] -> displays '1')
        $display("  Key '1' press (bit[1] -> should display '1')");
        press_keypad_key(4'b0100, 3'b100);
        repeat(1000) @(posedge clk);
        $display("    SEG_DATA: %h at %0t ns", out_to_seg_data, $time);
        
        // Key '2' (bit[2] -> displays '2')
        $display("  Key '2' press (bit[2] -> should display '2')");
        press_keypad_key(4'b0100, 3'b010);
        repeat(1000) @(posedge clk);
        $display("    SEG_DATA: %h at %0t ns", out_to_seg_data, $time);
        
        // Key '3' (bit[3] -> displays '3')
        $display("  Key '3' press (bit[3] -> should display '3')");
        press_keypad_key(4'b0100, 3'b001);
        repeat(1000) @(posedge clk);
        $display("    SEG_DATA: %h at %0t ns", out_to_seg_data, $time);
        
        // Key '4' (bit[5] -> displays '5')
        $display("  Key '4' press (bit[5] -> should display '5')");
        press_keypad_key(4'b0010, 3'b100);
        repeat(1000) @(posedge clk);
        $display("    SEG_DATA: %h at %0t ns", out_to_seg_data, $time);
        
        // Key '5' (bit[6] -> displays '6')
        $display("  Key '5' press (bit[6] -> should display '6')");
        press_keypad_key(4'b0010, 3'b010);
        repeat(1000) @(posedge clk);
        $display("    SEG_DATA: %h at %0t ns", out_to_seg_data, $time);
        
        // Key '6' (bit[7] -> displays '7')
        $display("  Key '6' press (bit[7] -> should display '7')");
        press_keypad_key(4'b0010, 3'b001);
        repeat(1000) @(posedge clk);
        $display("    SEG_DATA: %h at %0t ns", out_to_seg_data, $time);
        
        // Key '7' (bit[9] -> displays '9')
        $display("  Key '7' press (bit[9] -> should display '9')");
        press_keypad_key(4'b0001, 3'b100);
        repeat(1000) @(posedge clk);
        $display("    SEG_DATA: %h at %0t ns", out_to_seg_data, $time);
        
        // Key '8' (bit[10] -> displays 'A')
        $display("  Key '8' press (bit[10] -> should display 'A')");
        press_keypad_key(4'b0001, 3'b010);
        repeat(1000) @(posedge clk);
        $display("    SEG_DATA: %h at %0t ns", out_to_seg_data, $time);
        
        // Key '9' (bit[11] -> displays 'B')
        $display("  Key '9' press (bit[11] -> should display 'B')");
        press_keypad_key(4'b0001, 3'b001);
        repeat(1000) @(posedge clk);
        $display("    SEG_DATA: %h at %0t ns", out_to_seg_data, $time);
        
        // Key '*' (bit[13] -> displays 'D')
        $display("  Key '*' press (bit[13] -> should display 'D')");
        press_keypad_key(4'b1000, 3'b100);
        repeat(1000) @(posedge clk);
        $display("    SEG_DATA: %h at %0t ns", out_to_seg_data, $time);
        
        // Key '0' (bit[14] -> displays 'E')
        $display("  Key '0' press (bit[14] -> should display 'E')");
        press_keypad_key(4'b1000, 3'b010);
        repeat(1000) @(posedge clk);
        $display("    SEG_DATA: %h at %0t ns", out_to_seg_data, $time);
        
        // Key '#' (bit[15] -> displays 'F')
        $display("  Key '#' press (bit[15] -> should display 'F')");
        press_keypad_key(4'b1000, 3'b001);
        repeat(1000) @(posedge clk);
        $display("    SEG_DATA: %h at %0t ns", out_to_seg_data, $time);
        
        // ----------------------------------------
        // Test 4: LCD Output Test
        // ----------------------------------------
        $display("\n[Test 4] LCD Output Test");
        repeat(100) @(posedge clk);
        $display("  LCD_E: %b, LCD_RW: %b, LCD_RS: %b, LCD_DATA: %h", 
                 lcd_e, lcd_rw, lcd_rs, lcd_data);
        
        // ----------------------------------------
        // Test 5: Additional Operation Observation
        // ----------------------------------------
        $display("\n[Test 5] Additional Operation Observation");
        repeat(1000) @(posedge clk);  // Reduced for faster simulation
        
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
    
    // Debug: Monitor internal signals with more detail
    always @(DUT.w_value) begin
        if (DUT.w_value != 12'h000)
            $display("[DEBUG %0t ns] Keypad w_value: %h (binary: %b), out_to_keypad: %b, in_from_keypad: %b", 
                     $time, DUT.w_value, DUT.w_value, out_to_keypad, in_from_keypad);
    end
    
    always @(DUT.w_valid) begin
        if (DUT.w_valid)
            $display("[DEBUG %0t ns] Keypad w_valid: %b, w_value: %h, out_to_keypad: %b, in_from_keypad: %b", 
                     $time, DUT.w_valid, DUT.w_value, out_to_keypad, in_from_keypad);
    end
    
    always @(DUT.w_combined_value) begin
        if (DUT.w_combined_value != 16'h0000)
            $display("[DEBUG %0t ns] w_combined_value: %h (binary: %b)", $time, DUT.w_combined_value, DUT.w_combined_value);
    end
    
    always @(DUT.w_combined_valid) begin
        $display("[DEBUG %0t ns] w_combined_valid: %b", $time, DUT.w_combined_valid);
    end
    
    // Keypad scan output monitoring (commented out to prevent excessive output)
    // always @(out_to_keypad) begin
    //     $display("[%0t ns] KEYPAD_SCAN: %b", $time, out_to_keypad);
    // end
    
    // Task: Keypad press synchronized with row scan
    task press_keypad_key;
        input [3:0] target_row;
        input [2:0] target_column;
        integer timeout;
        integer i;
        integer detected;
        begin
            $display("    [TASK] Waiting for row %b to press col %b", target_row, target_column);
            
            // Wait for the target row to be scanned
            timeout = 0;
            while (out_to_keypad != target_row && timeout < 10000) begin
                @(posedge clk);
                timeout = timeout + 1;
            end
            
            if (timeout < 10000) begin
                // Hold key for multiple cycles to ensure detection
                detected = 0;
                for (i = 0; i < 5000 && detected == 0; i = i + 1) begin
                    if (out_to_keypad == target_row)
                        in_from_keypad = target_column;
                    else
                        in_from_keypad = 3'b111;
                    @(posedge clk);
                    
                    // Check if detected
                    if (DUT.w_valid == 1'b1) begin
                        $display("    [TASK] Detected w_value=%h at row=%b, %0t", 
                                 DUT.w_value, out_to_keypad, $time);
                        detected = 1;
                    end
                end
            end else begin
                $display("    [ERROR] Timeout waiting for row %b", target_row);
            end
            
            // Release key
            in_from_keypad = 3'b111;
            
            // Wait for valid to clear
            wait(DUT.w_valid == 1'b0);
            repeat(100) @(posedge clk);
        end
    endtask

endmodule

