`timescale 1ns/1ps

//====================================================
// train_controller: 학습 데이터 ROM 및 학습 FSM
//   - 버튼으로 학습 시작
//   - Epoch별로 데이터 순회
//   - 7-segment에 epoch 표시
//====================================================
module train_controller #(
    parameter NUM_EPOCHS = 10,
    parameter NUM_TRAIN_O = 100,
    parameter NUM_TRAIN_X = 100
)(
    input clk,
    input rst_n,
    input btn_train,           // 학습 시작 버튼
    
    // Neural network interface
    output reg [15:0] train_x,     // 학습 입력 데이터
    output reg train_learn,        // 학습 모드 활성화
    output reg train_is_O,         // 레이블 (1=O, 0=X)
    
    // Status outputs
    output reg training_active,    // 학습 중 플래그
    output reg [7:0] current_epoch, // 현재 epoch (0-based)
    output reg [7:0] current_sample, // 현재 샘플 인덱스
    output reg training_done       // 학습 완료 플래그
);

    // ===== 학습 데이터 ROM =====
    reg [15:0] train_O [0:99];
    reg [15:0] train_X [0:99];
    
    initial begin
        // ---- Train O shapes ----
        train_O[0]  = 16'b1111100110011111;
        train_O[1]  = 16'b1111100110011110;
        train_O[2]  = 16'b1111100110011101;
        train_O[3]  = 16'b1111100110011011;
        train_O[4]  = 16'b1111100110001111;
        train_O[5]  = 16'b1111100100011111;
        train_O[6]  = 16'b1111000110011111;
        train_O[7]  = 16'b0111100110011111;
        train_O[8]  = 16'b1111110110011111;
        train_O[9]  = 16'b1111100111011111;
        train_O[10] = 16'b1111100010011111;
        train_O[11] = 16'b1110100110011111;
        train_O[12] = 16'b1111100010011110;
        train_O[13] = 16'b1111100110001110;
        train_O[14] = 16'b1111100110010111;
        train_O[15] = 16'b1111000110010111;
        train_O[16] = 16'b1111100110010011;
        train_O[17] = 16'b1110100110010111;
        train_O[18] = 16'b1111000110001111;
        train_O[19] = 16'b1111000010011111;
        train_O[20] = 16'b1101100110011111;
        train_O[21] = 16'b0111000110011111;
        train_O[22] = 16'b0111100110010111;
        train_O[23] = 16'b0111100100011111;
        train_O[24] = 16'b1111100111011101;
        train_O[25] = 16'b1111100011001111;
        train_O[26] = 16'b1111100110011100;
        train_O[27] = 16'b1111100110000111;
        train_O[28] = 16'b1111100100011011;
        train_O[29] = 16'b1111100110010101;
        train_O[30] = 16'b1111100110001011;
        train_O[31] = 16'b1101100110001111;
        train_O[32] = 16'b1111100011011111;
        train_O[33] = 16'b1111000010010111;
        train_O[34] = 16'b1111000110011001;
        train_O[35] = 16'b1111100111001111;
        train_O[36] = 16'b1111100110111111;
        train_O[37] = 16'b1111100110011010;
        train_O[38] = 16'b1111100100011101;
        train_O[39] = 16'b1110100110011101;
        train_O[40] = 16'b1111100010011101;
        train_O[41] = 16'b1111100010011001;
        train_O[42] = 16'b0111100010011111;
        train_O[43] = 16'b1101100110011101;
        train_O[44] = 16'b1110100110010010;
        train_O[45] = 16'b1111100010011010;
        train_O[46] = 16'b0111100110001111;
        train_O[47] = 16'b1111100000011111;
        train_O[48] = 16'b1110000110011111;
        train_O[49] = 16'b1011100110011111;
        train_O[50] = 16'b1111100100010111;
        train_O[51] = 16'b1111100110010100;
        train_O[52] = 16'b1111100110111101;
        train_O[53] = 16'b1111100110001101;
        train_O[54] = 16'b1111100101011111;
        train_O[55] = 16'b1111100110011111;
        train_O[56] = 16'b1111100010111111;
        train_O[57] = 16'b1111100110000011;
        train_O[58] = 16'b1111100110011000;
        train_O[59] = 16'b1110100110001111;
        train_O[60] = 16'b1110110110011111;
        train_O[61] = 16'b1111100110110111;
        train_O[62] = 16'b1111100100001111;
        train_O[63] = 16'b1111100100011100;
        train_O[64] = 16'b1111000110010011;
        train_O[65] = 16'b1111100010101111;
        train_O[66] = 16'b1101100100011111;
        train_O[67] = 16'b1111100010110111;
        train_O[68] = 16'b0111100110111111;
        train_O[69] = 16'b1111100111001011;
        train_O[70] = 16'b1111100110010010;
        train_O[71] = 16'b1111100110101111;
        train_O[72] = 16'b0111100110011011;
        train_O[73] = 16'b1111100111010111;
        train_O[74] = 16'b1111100000010111;
        train_O[75] = 16'b0111100010011011;
        train_O[76] = 16'b1110100110001101;
        train_O[77] = 16'b1111100110111011;
        train_O[78] = 16'b1111100111101111;
        train_O[79] = 16'b1111100111000111;
        train_O[80] = 16'b1111110110001111;
        train_O[81] = 16'b0111100110000111;
        train_O[82] = 16'b1110100010011111;
        train_O[83] = 16'b1111000010011011;
        train_O[84] = 16'b1110100111001111;
        train_O[85] = 16'b1111100010001111;
        train_O[86] = 16'b1111100100111111;
        train_O[87] = 16'b1101110110011111;
        train_O[88] = 16'b1111100110110011;
        train_O[89] = 16'b1111100000111111;
        train_O[90] = 16'b1111000110001101;
        train_O[91] = 16'b0111100010001111;
        train_O[92] = 16'b1111100100111101;
        train_O[93] = 16'b1110100110011010;
        train_O[94] = 16'b1111100011001110;
        train_O[95] = 16'b1111100110011111;
        train_O[96] = 16'b1111100010000111;
        train_O[97] = 16'b1110000110010111;
        train_O[98] = 16'b1111100111001110;
        train_O[99] = 16'b1111100100011110;

        // ---- Train X shapes ----
        train_X[0]  = 16'b1001011001101001;
        train_X[1]  = 16'b1001011000101001;
        train_X[2]  = 16'b1001001001101001;
        train_X[3]  = 16'b1001011001001001;
        train_X[4]  = 16'b1001011001100001;
        train_X[5]  = 16'b1001011001101011;
        train_X[6]  = 16'b1001001000101001;
        train_X[7]  = 16'b0001001001001000;
        train_X[8]  = 16'b1001001000101101;
        train_X[9]  = 16'b1001011001001001;
        train_X[10] = 16'b1001010000101001;
        train_X[11] = 16'b1101011001101001;
        train_X[12] = 16'b1001011001101101;
        train_X[13] = 16'b0101011001101010;
        train_X[14] = 16'b1001110001101001;
        train_X[15] = 16'b1001011001111001;
        train_X[16] = 16'b1101011001100001;
        train_X[17] = 16'b1001001001100101;
        train_X[18] = 16'b0001011001101001;
        train_X[19] = 16'b1001011001001000;
        train_X[20] = 16'b1001010001001001;
        train_X[21] = 16'b1000011001101000;
        train_X[22] = 16'b1001001000101000;
        train_X[23] = 16'b0001001000101000;
        train_X[24] = 16'b1001011000111001;
        train_X[25] = 16'b1001001101101101;
        train_X[26] = 16'b1011011000101001;
        train_X[27] = 16'b1001011101101001;
        train_X[28] = 16'b0001011001110001;
        train_X[29] = 16'b1101001000101011;
        train_X[30] = 16'b1000011000101001;
        train_X[31] = 16'b1001011000100001;
        train_X[32] = 16'b0000011001101001;
        train_X[33] = 16'b1001000000101001;
        train_X[34] = 16'b1001011000100011;
        train_X[35] = 16'b0001010000101001;
        train_X[36] = 16'b1001010001101001;
        train_X[37] = 16'b1001011000100101;
        train_X[38] = 16'b1001001000101000;
        train_X[39] = 16'b0011011000101001;
        train_X[40] = 16'b1000011000100001;
        train_X[41] = 16'b0001011000001001;
        train_X[42] = 16'b1000010001101001;
        train_X[43] = 16'b1001011000001001;
        train_X[44] = 16'b1001011000100010;
        train_X[45] = 16'b1001011000100100;
        train_X[46] = 16'b1001001000101010;
        train_X[47] = 16'b0001010001100001;
        train_X[48] = 16'b0101011001100001;
        train_X[49] = 16'b1001010001101011;
        train_X[50] = 16'b1001010001001000;
        train_X[51] = 16'b1001011000101101;
        train_X[52] = 16'b1001001001101010;
        train_X[53] = 16'b1000011000101011;
        train_X[54] = 16'b1001011000001101;
        train_X[55] = 16'b1001110000101001;
        train_X[56] = 16'b1001011100101001;
        train_X[57] = 16'b0101011000101001;
        train_X[58] = 16'b1000011001001001;
        train_X[59] = 16'b0001011000101001;
        train_X[60] = 16'b1000011000101000;
        train_X[61] = 16'b1001001000001001;
        train_X[62] = 16'b1000011000100000;
        train_X[63] = 16'b1001011000001000;
        train_X[64] = 16'b1001001001101000;
        train_X[65] = 16'b1001001001101011;
        train_X[66] = 16'b1101011000101001;
        train_X[67] = 16'b1001011000001100;
        train_X[68] = 16'b1001010000101101;
        train_X[69] = 16'b1100011000101011;
        train_X[70] = 16'b1001011000100110;
        train_X[71] = 16'b1001001000100101;
        train_X[72] = 16'b1000010000101001;
        train_X[73] = 16'b0001001000001001;
        train_X[74] = 16'b1001011100100001;
        train_X[75] = 16'b1001011001100100;
        train_X[76] = 16'b1001011000101010;
        train_X[77] = 16'b0001011000001000;
        train_X[78] = 16'b1000011000100011;
        train_X[79] = 16'b1011011000001001;
        train_X[80] = 16'b1001001001100011;
        train_X[81] = 16'b1001011000000101;
        train_X[82] = 16'b1001011001001101;
        train_X[83] = 16'b1001111001101001;
        train_X[84] = 16'b1001011100101000;
        train_X[85] = 16'b1001010000101010;
        train_X[86] = 16'b1001001100101001;
        train_X[87] = 16'b1001001000001101;
        train_X[88] = 16'b1001001001000001;
        train_X[89] = 16'b1001011001001010;
        train_X[90] = 16'b1001011001100110;
        train_X[91] = 16'b1001001100100001;
        train_X[92] = 16'b1000011100101001;
        train_X[93] = 16'b1001011101100001;
        train_X[94] = 16'b1001001000100011;
        train_X[95] = 16'b0101011000100011;
        train_X[96] = 16'b1101010000101001;
        train_X[97] = 16'b1001011000100000;
        train_X[98] = 16'b1001011001100101;
        train_X[99] = 16'b1000011001101011;
    end

    // ===== 학습 FSM =====
    localparam IDLE         = 3'd0;
    localparam TRAIN_O      = 3'd1;
    localparam TRAIN_X      = 3'd2;
    localparam EPOCH_DONE   = 3'd3;
    localparam ALL_DONE     = 3'd4;
    
    reg [2:0] state;
    reg [7:0] epoch_cnt;
    reg [7:0] sample_idx;
    reg btn_train_prev;
    
    // 학습 속도 조절 (클럭 분주)
    reg [15:0] train_delay_cnt;
    localparam TRAIN_DELAY = 16'd50; // 샘플당 대기 시간 (클럭 사이클)
    
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            state <= IDLE;
            train_learn <= 0;
            train_is_O <= 0;
            train_x <= 16'b0;
            training_active <= 0;
            training_done <= 0;
            current_epoch <= 0;
            current_sample <= 0;
            epoch_cnt <= 0;
            sample_idx <= 0;
            btn_train_prev <= 0;
            train_delay_cnt <= 0;
        end else begin
            btn_train_prev <= btn_train;
            
            case (state)
                IDLE: begin
                    training_active <= 0;
                    train_learn <= 0;
                    
                    // 버튼 상승 엣지 감지
                    if (btn_train && !btn_train_prev) begin
                        state <= TRAIN_O;
                        training_active <= 1;
                        training_done <= 0;
                        epoch_cnt <= 0;
                        sample_idx <= 0;
                        current_epoch <= 0;
                        current_sample <= 0;
                    end
                end
                
                TRAIN_O: begin
                    if (train_delay_cnt < TRAIN_DELAY) begin
                        train_delay_cnt <= train_delay_cnt + 1;
                        train_learn <= 1;
                        train_is_O <= 1;
                        train_x <= train_O[sample_idx];
                        current_sample <= sample_idx;
                    end else begin
                        train_delay_cnt <= 0;
                        
                        if (sample_idx < NUM_TRAIN_O - 1) begin
                            sample_idx <= sample_idx + 1;
                        end else begin
                            sample_idx <= 0;
                            state <= TRAIN_X;
                        end
                    end
                end
                
                TRAIN_X: begin
                    if (train_delay_cnt < TRAIN_DELAY) begin
                        train_delay_cnt <= train_delay_cnt + 1;
                        train_learn <= 1;
                        train_is_O <= 0;
                        train_x <= train_X[sample_idx];
                        current_sample <= sample_idx + NUM_TRAIN_O;
                    end else begin
                        train_delay_cnt <= 0;
                        
                        if (sample_idx < NUM_TRAIN_X - 1) begin
                            sample_idx <= sample_idx + 1;
                        end else begin
                            sample_idx <= 0;
                            state <= EPOCH_DONE;
                        end
                    end
                end
                
                EPOCH_DONE: begin
                    train_learn <= 0;
                    current_epoch <= epoch_cnt + 1;
                    
                    if (epoch_cnt < NUM_EPOCHS - 1) begin
                        epoch_cnt <= epoch_cnt + 1;
                        state <= TRAIN_O;
                        // 잠깐 대기
                        train_delay_cnt <= 0;
                    end else begin
                        state <= ALL_DONE;
                    end
                end
                
                ALL_DONE: begin
                    training_active <= 0;
                    training_done <= 1;
                    train_learn <= 0;
                    
                    // 다시 학습 버튼 누르면 재시작 가능
                    if (btn_train && !btn_train_prev) begin
                        state <= IDLE;
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end

endmodule

