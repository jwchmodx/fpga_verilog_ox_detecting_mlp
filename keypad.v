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
	integer cnt_clk_50KHz;
    reg     clk_50KHz;

   // Clock divider: 50MHz -> ~10KHz
   always @(posedge clk or negedge rst) begin
      if (~rst) begin
         cnt_clk_50KHz = 0;
         clk_50KHz = 1'b0;
      end else if (cnt_clk_50KHz >= 2500) begin // Speed up slightly (5000->2500) or keep 5000. Keeping relatively slow is fine.
         cnt_clk_50KHz = 0;
         clk_50KHz = ~clk_50KHz;
      end else begin
         cnt_clk_50KHz = cnt_clk_50KHz + 1;
      end
   end

	always @(posedge clk_50KHz or negedge rst) begin
		if (~rst) begin
			cnt_key       <= 2'b00;
			out_to_keypad <= 4'b0000;
			out           <= 12'b0;
			valid         <= 1'b0;
		end else begin
            // 1. Read Input Phase
            // Check input based on what was driven in the PREVIOUS cycle (current out_to_keypad value)
            valid <= 1'b0;
            out   <= 12'b0;
            
            case (out_to_keypad)
                4'b0100: begin // Row for keys 1,2,3
                    case (in_from_keypad)				 
                         3'b100: begin out <= 12'b000000000001; valid <= 1'b1; end // 1
                         3'b010: begin out <= 12'b000000000010; valid <= 1'b1; end // 2
                         3'b001: begin out <= 12'b000000000100; valid <= 1'b1; end // 3
                        default: valid <= 1'b0;
                    endcase
                end
                4'b0010: begin // Row for keys 4,5,6
                    case (in_from_keypad)
                         3'b100: begin out <= 12'b000000001000; valid <= 1'b1; end // 4
                         3'b010: begin out <= 12'b000000010000; valid <= 1'b1; end // 5
                         3'b001: begin out <= 12'b000000100000; valid <= 1'b1; end // 6
                        default: valid <= 1'b0;
                    endcase
                end
                4'b0001: begin // Row for keys 7,8,9
                    case (in_from_keypad)
                         3'b100: begin out <= 12'b000001000000; valid <= 1'b1; end // 7
                         3'b010: begin out <= 12'b000010000000; valid <= 1'b1; end // 8
                         3'b001: begin out <= 12'b000100000000; valid <= 1'b1; end // 9
                        default: valid <= 1'b0;
                    endcase
                end
                4'b1000: begin // Row for keys *,0,#
                    case (in_from_keypad)
                         3'b100: begin out <= 12'b001000000000; valid <= 1'b1; end // *
                         3'b010: begin out <= 12'b010000000000; valid <= 1'b1; end // 0
                         3'b001: begin out <= 12'b100000000000; valid <= 1'b1; end // #
                        default: valid <= 1'b0;
                    endcase
                end
                default: valid <= 1'b0;
            endcase

            // 2. Drive Output Phase (Prepare for NEXT cycle)
			if(cnt_key == 2'b11) cnt_key <= 2'b00;
			else                 cnt_key <= cnt_key + 1;
            
			case (cnt_key) // Note: This sets up the Row for the NEXT read
				2'b00: out_to_keypad <= 4'b0100; // Next: Scan Row 1 (1,2,3)
				2'b01: out_to_keypad <= 4'b0010; // Next: Scan Row 2 (4,5,6)
				2'b10: out_to_keypad <= 4'b0001; // Next: Scan Row 3 (7,8,9)
				2'b11: out_to_keypad <= 4'b1000; // Next: Scan Row 4 (*,0,#)
			endcase
		end
	end

endmodule
