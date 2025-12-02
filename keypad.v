`timescale 1ns/1ps


module keypad_scan (
	input  clk,
	input  rst,
	input  [2:0] in_from_keypad, // col
	output reg [3:0] out_to_keypad, // row
	output reg [11:0] out,
	output reg valid
);

	reg [1:0] cnt_key;
	integer cnt_clk;

	integer cnt_clk_50KHz;
   reg     clk_50KHz;

   always @(posedge clk or negedge rst) begin
      if (~rst) begin
         cnt_clk_50KHz = 0;
         clk_50KHz = 1'b0;
      end else if (cnt_clk_50KHz >= 1000) begin
         cnt_clk_50KHz = 0;
         clk_50KHz = ~clk_50KHz;
      end else begin
         cnt_clk_50KHz = cnt_clk_50KHz + 1;
      end
   end

	always @(posedge clk_50KHz or negedge rst) begin
		if (~rst) begin
			cnt_key       = 2'b00;
			out_to_keypad = 4'b0000;
			out           = 12'b000000000000;
			valid         = 1'b0;
		end else begin
			if(cnt_key == 2'b11) cnt_key = 2'b00;
			else                 cnt_key = cnt_key + 1;
			case (cnt_key)
				2'b00: out_to_keypad = 4'b1000;
				2'b01: out_to_keypad = 4'b0100;
				2'b10: out_to_keypad = 4'b0010;
				2'b11: out_to_keypad = 4'b0001;
			endcase
			// Use cnt_key directly instead of out_to_keypad to avoid race condition
			case (cnt_key)
				2'b01:  // out_to_keypad = 4'b0100 (Row for keys 1,2,3)
					case (in_from_keypad)				 
						 3'b100: begin out = 12'b000000000001; valid = 1'b1; end // 1
						 3'b010: begin out = 12'b000000000010; valid = 1'b1; end // 2
						 3'b001: begin out = 12'b000000000100; valid = 1'b1; end // 3
						default:                               valid = 1'b0;
					endcase
				2'b10:  // out_to_keypad = 4'b0010 (Row for keys 4,5,6)
					case (in_from_keypad)
						 3'b100: begin out = 12'b000000001000; valid = 1'b1; end // 4
						 3'b010: begin out = 12'b000000010000; valid = 1'b1; end // 5
						 3'b001: begin out = 12'b000000100000; valid = 1'b1; end // 6
						default:                               valid = 1'b0;
					endcase
				2'b11:  // out_to_keypad = 4'b0001 (Row for keys 7,8,9)
					case (in_from_keypad)
						 3'b100: begin out = 12'b000001000000; valid = 1'b1; end // 7
						 3'b010: begin out = 12'b000010000000; valid = 1'b1; end // 8
						 3'b001: begin out = 12'b000100000000; valid = 1'b1; end // 9
						default:                               valid = 1'b0;
					endcase
				2'b00:  // out_to_keypad = 4'b1000 (Row for keys *,0,#)
					case (in_from_keypad)
						 3'b100: begin out = 12'b001000000000; valid = 1'b1; end // *
						 3'b010: begin out = 12'b010000000000; valid = 1'b1; end // 0
						 3'b001: begin out = 12'b100000000000; valid = 1'b1; end // #
						default:                               valid = 1'b0;
					endcase
				default: valid = 1'b0;
			endcase
		end
	end

endmodule