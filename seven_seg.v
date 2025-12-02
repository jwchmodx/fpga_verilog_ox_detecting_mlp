module display_seg (
  input  clk,
  input  rst,
  input  [11:0] scan_data,
  input  valid,
  output reg [7:0] r7,
  output reg [7:0] r6,
  output reg [7:0] r5,
  output reg [7:0] r4,
  output reg [7:0] r3,
  output reg [7:0] r2,
  output reg [7:0] r1,
  output reg [7:0] r0
);

  reg [11:0] stored_data;
  reg [7:0]  r;
  reg [2:0]  digit; 
  
  always@(posedge clk or negedge rst) begin
    if (~rst) begin
      r0 = 8'b0; r1 = 8'b0; r2 = 8'b0; r3 = 8'b0;
      r4 = 8'b0; r5 = 8'b0; r6 = 8'b0; r7 = 8'b0;
      stored_data = 12'b000000000000;
      digit       = 3'b000;
      r           = 8'b0;
    end else begin
      if (valid) stored_data = scan_data;
      // TO-DO start
      case(stored_data)
        12'b000000000001 : r = 8'b01100000; // 1
        12'b000000000010 : r = 8'b11011010; // 2
        12'b000000000100 : r = 8'b11110010; // 3
        12'b000000001000 : r = 8'b01100110; // 4
        12'b000000010000 : r = 8'b10110110; // 5
        12'b000000100000 : r = 8'b10111110; // 6
        12'b000001000000 : r = 8'b11100000; // 7
        12'b000010000000 : r = 8'b11111110; // 8
        12'b000100000000 : r = 8'b11110110; // 9
        12'b010000000000 : r = 8'b11111100; // 0
        12'b001000000000 : r = 8'b01101110; // * -> X
        12'b100000000000 : r = 8'b01101110; // # -> X
      endcase
      case (digit)
        3'b000 : begin r7 = 8'b0; r6 = 8'b0; r5 = 8'b0; r4 = 8'b0; r3 = 8'b0; r2 = 8'b0; r1 = 8'b0; r0 = r;    end
        3'b001 : begin r7 = 8'b0; r6 = 8'b0; r5 = 8'b0; r4 = 8'b0; r3 = 8'b0; r2 = 8'b0; r1 = r;    r0 = 8'b0; end
        3'b010 : begin r7 = 8'b0; r6 = 8'b0; r5 = 8'b0; r4 = 8'b0; r3 = 8'b0; r2 = r;    r1 = 8'b0; r0 = 8'b0; end
        3'b011 : begin r7 = 8'b0; r6 = 8'b0; r5 = 8'b0; r4 = 8'b0; r3 = r;    r2 = 8'b0; r1 = 8'b0; r0 = 8'b0; end
        3'b100 : begin r7 = 8'b0; r6 = 8'b0; r5 = 8'b0; r4 = r;    r3 = 8'b0; r2 = 8'b0; r1 = 8'b0; r0 = 8'b0; end
        3'b101 : begin r7 = 8'b0; r6 = 8'b0; r5 = r;    r4 = 8'b0; r3 = 8'b0; r2 = 8'b0; r1 = 8'b0; r0 = 8'b0; end
        3'b110 : begin r7 = 8'b0; r6 = r;    r5 = 8'b0; r4 = 8'b0; r3 = 8'b0; r2 = 8'b0; r1 = 8'b0; r0 = 8'b0; end
        3'b111 : begin r7 = r;    r6 = 8'b0; r5 = 8'b0; r4 = 8'b0; r3 = 8'b0; r2 = 8'b0; r1 = 8'b0; r0 = 8'b0; end
        default: begin r7 = 8'b0; r6 = 8'b0; r5 = 8'b0; r4 = 8'b0; r3 = 8'b0; r2 = 8'b0; r1 = 8'b0; r0 = 8'b0; end
      endcase
      // TO-DO end
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