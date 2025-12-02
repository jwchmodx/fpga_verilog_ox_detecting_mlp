`timescale 1ns/1ps

module display_seg (
  input  clk,
  input  rst,
  input  [15:0] scan_data,  // 16 bits: keypad[15:4] + buttons[3:0] or number data
  input  valid,
  input  number_mode,       // 0: one-hot mode, 1: number display mode
  output reg [7:0] r7,
  output reg [7:0] r6,
  output reg [7:0] r5,
  output reg [7:0] r4,
  output reg [7:0] r3,
  output reg [7:0] r2,
  output reg [7:0] r1,
  output reg [7:0] r0
);

  reg [15:0] stored_data;  // 16 bits
  reg [7:0]  r;
  
  // Function to convert digit (0-9) to 7-segment pattern
  function [7:0] digit_to_seg;
    input [3:0] digit;
    begin
      case(digit)
        4'd0: digit_to_seg = 8'b11111100; // 0
        4'd1: digit_to_seg = 8'b01100000; // 1
        4'd2: digit_to_seg = 8'b11011010; // 2
        4'd3: digit_to_seg = 8'b11110010; // 3
        4'd4: digit_to_seg = 8'b01100110; // 4
        4'd5: digit_to_seg = 8'b10110110; // 5
        4'd6: digit_to_seg = 8'b10111110; // 6
        4'd7: digit_to_seg = 8'b11100000; // 7
        4'd8: digit_to_seg = 8'b11111110; // 8
        4'd9: digit_to_seg = 8'b11110110; // 9
        default: digit_to_seg = 8'b00000000;
      endcase
    end
  endfunction
  
  always@(posedge clk or negedge rst) begin
    if (~rst) begin
      r0 = 8'b0; r1 = 8'b0; r2 = 8'b0; r3 = 8'b0;
      r4 = 8'b0; r5 = 8'b0; r6 = 8'b0; r7 = 8'b0;
      stored_data = 16'b0000000000000000;
      r           = 8'b0;
    end else begin
      if (valid) stored_data = scan_data;
      
      if (number_mode) begin
        // Number display mode: scan_data[7:4] = tens, scan_data[3:0] = ones
        r7 = digit_to_seg(stored_data[7:4]);  // Tens digit
        r6 = digit_to_seg(stored_data[3:0]);  // Ones digit
        r5 = 8'b00000000;  // Off
        r4 = 8'b00000000;  // Off
        r3 = 8'b00000000;  // Off
        r2 = 8'b00000000;  // Off
        r1 = 8'b00000000;  // Off
        r0 = 8'b00000000;  // Off
      end else begin
        // One-hot display mode (original behavior)
        // Display: A,1,2,3,B,4,5,6,C,7,8,9,D,*,0,# -> 0~F
        case(stored_data)
          16'b0000000000000001 : r = 8'b11111100; // 0: A (bit[0])
          16'b0000000000000010 : r = 8'b01100000; // 1: 1 (bit[1])
          16'b0000000000000100 : r = 8'b11011010; // 2: 2 (bit[2])
          16'b0000000000001000 : r = 8'b11110010; // 3: 3 (bit[3])
          16'b0000000000010000 : r = 8'b01100110; // 4: B (bit[4])
          16'b0000000000100000 : r = 8'b10110110; // 5: 4 (bit[5])
          16'b0000000001000000 : r = 8'b10111110; // 6: 5 (bit[6])
          16'b0000000010000000 : r = 8'b11100000; // 7: 6 (bit[7])
          16'b0000000100000000 : r = 8'b11111110; // 8: C (bit[8])
          16'b0000001000000000 : r = 8'b11110110; // 9: 7 (bit[9])
          16'b0000010000000000 : r = 8'b11101110; // A: 8 (bit[10])
          16'b0000100000000000 : r = 8'b00111110; // B: 9 (bit[11])
          16'b0001000000000000 : r = 8'b10011100; // C: D (bit[12])
          16'b0010000000000000 : r = 8'b01111010; // D: * (bit[13])
          16'b0100000000000000 : r = 8'b10011110; // E: 0 (bit[14])
          16'b1000000000000000 : r = 8'b10001110; // F: # (bit[15])
          default              : r = 8'b00000000;
        endcase
        
        // Display same value on all digits (for one-hot encoded single key display)
        r0 = r; r1 = r; r2 = r; r3 = r;
        r4 = r; r5 = r; r6 = r; r7 = r;
      end
    end
  end

endmodule



module seg_controller # (
  parameter MAX_CNT_CLK = 1024
) (
  input  clk,
  input  rst,
  input  [7:0] seg_7,
  input  [7:0] seg_6,
  input  [7:0] seg_5,
  input  [7:0] seg_4,
  input  [7:0] seg_3,
  input  [7:0] seg_2,
  input  [7:0] seg_1,
  input  [7:0] seg_0,
  output reg [7:0] seg_en,
  output reg [7:0] seg_data
);

  reg[2:0] scan_loc;
  integer cnt_clk;

  always@(posedge clk or negedge rst) begin
    if(~rst) begin
      seg_en   <= 8'b00000000;
      seg_data <= 8'b00000000;
      scan_loc <= 3'b000;
      cnt_clk  <= 0;
    end else begin
      if (cnt_clk == MAX_CNT_CLK) begin
        cnt_clk = 0;
        if(scan_loc == 3'b111) scan_loc = 3'b000;
        else                   scan_loc = scan_loc + 1'b1;
      end else cnt_clk = cnt_clk + 1;
      case(scan_loc)
        3'd0:    begin seg_en = 8'b11111110; seg_data = seg_0; end
        3'd1:    begin seg_en = 8'b11111101; seg_data = seg_1; end
        3'd2:    begin seg_en = 8'b11111011; seg_data = seg_2; end
        3'd3:    begin seg_en = 8'b11110111; seg_data = seg_3; end
        3'd4:    begin seg_en = 8'b11101111; seg_data = seg_4; end
        3'd5:    begin seg_en = 8'b11011111; seg_data = seg_5; end
        3'd6:    begin seg_en = 8'b10111111; seg_data = seg_6; end
        3'd7:    begin seg_en = 8'b01111111; seg_data = seg_7; end
        default: begin seg_en = 8'b11111111; seg_data = seg_0; end
      endcase
    end
  end

endmodule