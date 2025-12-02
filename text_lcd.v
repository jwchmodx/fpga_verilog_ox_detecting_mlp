`timescale 1ns/1ps

module text_lcd # (
   parameter DELAY      = 3'b000,
   parameter FUNC_SET   = 3'b001,
   parameter ENTRY_MODE = 3'b010,
   parameter DISP_ONOFF = 3'b011,
   parameter LINE_1     = 3'b100,
   parameter LINE_2     = 3'b101,
   parameter DELAY_T    = 3'b110,
   parameter DISP_CLEAR = 3'b111
) (
   input  clk,
   input  rst,
   output lcd_e,
   output reg lcd_rw,
   output reg lcd_rs,
   output reg [7:0] lcd_data
);

   reg [2:0] state;
   integer cnt;
   integer cnt_clk_100Hz;
   reg     clk_100Hz;

   always @(posedge clk or negedge rst) begin
      if (~rst) begin
         cnt_clk_100Hz = 0;
         clk_100Hz = 1'b0;
      end else if (cnt_clk_100Hz >= 500000) begin
         cnt_clk_100Hz = 0;
         clk_100Hz = ~clk_100Hz;
      end else begin
         cnt_clk_100Hz = cnt_clk_100Hz + 1;
      end
   end

   always @(posedge clk_100Hz or negedge rst) begin
      if (~rst) state = DELAY;
      else begin   
         case (state)
            DELAY:       if(cnt==70)  state = FUNC_SET;
            FUNC_SET:    if(cnt==30)  state = DISP_ONOFF;
            DISP_ONOFF:  if(cnt==30)  state = ENTRY_MODE;
            ENTRY_MODE:  if(cnt==30)  state = LINE_1;
            LINE_1:      if(cnt==20)  state = LINE_2;
            LINE_2:      if(cnt==20)  state = DELAY_T;
            DELAY_T:     if(cnt==400) state = DISP_CLEAR;
            DISP_CLEAR:  if(cnt==200) state = LINE_1;
            default:                  state = DELAY;
         endcase
      end
   end

   always @(posedge clk_100Hz or negedge rst) begin
      if(~rst) cnt=0;
      else begin   
         case(state)
            DELAY:       if(cnt>=70)  cnt=0;  else cnt=cnt+1;
            FUNC_SET:    if(cnt>=30)  cnt=0;  else cnt=cnt+1;
            DISP_ONOFF:  if(cnt>=30)  cnt=0;  else cnt=cnt+1;
            ENTRY_MODE:  if(cnt>=30)  cnt=0;  else cnt=cnt+1;
            LINE_1:      if(cnt>=20)  cnt=0;  else cnt=cnt+1;
            LINE_2:      if(cnt>=20)  cnt=0;  else cnt=cnt+1;
            DELAY_T:     if(cnt>=220) cnt=0;  else cnt=cnt+1;
            DISP_CLEAR:  if(cnt>=200) cnt=0;  else cnt=cnt+1;
            default:                  cnt=0;
         endcase
      end
   end

   always @(posedge clk_100Hz or negedge rst) begin
      if(~rst) begin          lcd_rw = 1'b1; lcd_rs = 1'b1; lcd_data = 8'h00;
      end else begin
         case(state)
            FUNC_SET:   begin lcd_rw = 1'b0; lcd_rs = 1'b0; lcd_data = 8'h38; end
            DISP_ONOFF: begin lcd_rw = 1'b0; lcd_rs = 1'b0; lcd_data = 8'h0c; end
            ENTRY_MODE: begin lcd_rw = 1'b0; lcd_rs = 1'b0; lcd_data = 8'h06; end
            LINE_1:     begin lcd_rw = 1'b0;
               // TO-DO
               case(cnt)
                  0:                   begin lcd_rs = 1'b0; lcd_data = 8'h80; end // address
                  1:                   begin lcd_rs = 1'b1; lcd_data = 8'h44; end // D
                  2:                   begin lcd_rs = 1'b1; lcd_data = 8'h69; end // i
                  3:                   begin lcd_rs = 1'b1; lcd_data = 8'h67; end // g
                  4:                   begin lcd_rs = 1'b1; lcd_data = 8'h69; end // i
                  5:                   begin lcd_rs = 1'b1; lcd_data = 8'h74; end // t
                  6:                   begin lcd_rs = 1'b1; lcd_data = 8'h61; end // a
                  7:                   begin lcd_rs = 1'b1; lcd_data = 8'h6c; end // l
                  8:                   begin lcd_rs = 1'b1; lcd_data = 8'h20; end //
                  9:                   begin lcd_rs = 1'b1; lcd_data = 8'h64; end // d
                  10:                  begin lcd_rs = 1'b1; lcd_data = 8'h65; end // e
                  11:                  begin lcd_rs = 1'b1; lcd_data = 8'h73; end // s
                  12:                  begin lcd_rs = 1'b1; lcd_data = 8'h69; end // i
                  13:                  begin lcd_rs = 1'b1; lcd_data = 8'h67; end // g
                  14:                  begin lcd_rs = 1'b1; lcd_data = 8'h6e; end // n
                  15:                  begin lcd_rs = 1'b1; lcd_data = 8'h3a; end // :
                  16:                  begin lcd_rs = 1'b1; lcd_data = 8'h20; end //
                  default:             begin lcd_rs = 1'b1; lcd_data = 8'h20; end //
               endcase
            end
            LINE_2:     begin lcd_rw <= 1'b0;
               // TO-DO
               case(cnt)
                  0:                   begin lcd_rs = 1'b0; lcd_data = 8'hc0; end // address
                  1:                   begin lcd_rs = 1'b1; lcd_data = 8'h48; end // H
                  2:                   begin lcd_rs = 1'b1; lcd_data = 8'h65; end // e
                  3:                   begin lcd_rs = 1'b1; lcd_data = 8'h6c; end // l
                  4:                   begin lcd_rs = 1'b1; lcd_data = 8'h6c; end // l
                  5:                   begin lcd_rs = 1'b1; lcd_data = 8'h6f; end // o
                  6:                   begin lcd_rs = 1'b1; lcd_data = 8'h20; end //
                  7:                   begin lcd_rs = 1'b1; lcd_data = 8'h77; end // w
                  8:                   begin lcd_rs = 1'b1; lcd_data = 8'h6f; end // o
                  9:                   begin lcd_rs = 1'b1; lcd_data = 8'h72; end // r
                  10:                  begin lcd_rs = 1'b1; lcd_data = 8'h6c; end // l
                  11:                  begin lcd_rs = 1'b1; lcd_data = 8'h64; end // d
                  12:                  begin lcd_rs = 1'b1; lcd_data = 8'h21; end // !
                  13:                  begin lcd_rs = 1'b1; lcd_data = 8'h20; end // 
                  14:                  begin lcd_rs = 1'b1; lcd_data = 8'h20; end // 
                  15:                  begin lcd_rs = 1'b1; lcd_data = 8'h20; end // 
                  16:                  begin lcd_rs = 1'b1; lcd_data = 8'h20; end // 
                  default:             begin lcd_rs = 1'b1; lcd_data = 8'h20; end //
               endcase
            end
            DELAY_T:    begin lcd_rw = 1'b0; lcd_rs = 1'b0; lcd_data = 8'h02; end
            DISP_CLEAR: begin lcd_rw = 1'b0; lcd_rs = 1'b0; lcd_data = 8'h01; end
            default:    begin lcd_rw = 1'b1; lcd_rs = 1'b1; lcd_data = 8'h00; end
         endcase
      end
   end

   assign lcd_e = clk_100Hz;

endmodule