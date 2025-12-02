`timescale 1ns/1ps

module tb_mlp_OX_full;

  // ===== 파라미터 =====
  localparam W      = 12;
  localparam FRAC   = 6;
  localparam HSIZE  = 12;   // Hidden layer size
  localparam EPOCHS = 10;   // 학습 epoch 수

  // ===== DUT I/O =====
  reg         clk;
  reg         rst_n;
  reg  [15:0] x;
  reg         learn, is_O;

  wire        y;
  wire [6:0]  o_prob_pct;           // O일 확률 0~100(%)
  wire signed [W+4:0] y_score_out;  // 출력층 raw score
  wire signed [W+9:0] hidden_score; // hidden layer score (합)

  // ===== DUT =====  
  mlp_OX #(.W(W), .N(HSIZE), .FRAC(FRAC)) dut (
    .clk          (clk),
    .rst_n        (rst_n),
    .x            (x),
    .learn        (learn),
    .is_O         (is_O),
    .y            (y),
    .o_prob_pct   (o_prob_pct),
    .y_score_out  (y_score_out),
    .hidden_score (hidden_score)
  );

  // 100 MHz clock
  always #5 clk = ~clk;

  // ===== 학습 데이터 =====
  reg [15:0] train_O [0:99];
  reg [15:0] train_X [0:99];

  // ===== 테스트 데이터 =====
  reg [15:0] test_O [0:9];
  reg [15:0] test_X [0:9];

  // ===== PASS/FAIL 집계 =====
  integer test_pass_count  = 0;
  integer test_total_count = 0;
  integer before_pass_count  = 0;
  integer before_total_count = 0;

  // ===== 초기 데이터 로드 =====
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

    // ---- Test O shapes ----
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

    // ---- Test X shapes ----
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
  end

  // ===== 학습 태스크 =====
  task learn_one(input [15:0] pat, input label);
    begin
      x    = pat;
      is_O = label;

      @(posedge clk); // S1: hidden
      @(posedge clk); // S2: output
      @(posedge clk); // S3: error

      learn = 1'b1; @(posedge clk); // S4: update
      learn = 1'b0;

      @(posedge clk);
    end
  endtask

  // ===== 추론 태스크 (스코어/확률 출력) =====
  task infer_one_and_check(
    input [15:0] pat,
    input expected,
    input integer idx,
    input is_O_tag
  );
    integer p_int;
    real    p_real;   // 0.0 ~ 1.0 실수 확률
    begin
      x = pat;

      @(posedge clk); // S1
      @(posedge clk); // S2 (이 시점에서 y, o_prob_pct, y_score_out, hidden_score, dut.prob_q 유효)

      // QFRAC=6 이므로, prob_q / 64.0 이 실제 확률
      p_int  = dut.prob_q;                             // hier access
      p_real = p_int / (1.0 * (1 << FRAC));            // ex) 40/64 ≈ 0.625

      test_total_count = test_total_count + 1;
      if (y == expected) begin
        test_pass_count = test_pass_count + 1;
        $display("    infer(%c_test_%0d): PASS (y=%0d, O_prob=%0d%%, p=%.3f, y_score=%0d, hidden=%0d)",
                 is_O_tag ? "O" : "X", idx, y, o_prob_pct, p_real, y_score_out, hidden_score);
      end
      else begin
        $display("    infer(%c_test_%0d): FAIL (y=%0d expected=%0d, O_prob=%0d%%, p=%.3f, y_score=%0d, hidden=%0d)",
                 is_O_tag ? "O" : "X", idx, y, expected, o_prob_pct, p_real, y_score_out, hidden_score);
      end
    end
  endtask

  integer i, epoch;

  // ===== 시뮬레이션 플로우 =====
  initial begin
    clk=0; rst_n=0; x=0; learn=0; is_O=0;

    repeat(3) @(posedge clk);
    rst_n = 1;
    repeat(3) @(posedge clk);

    // === 학습 전 정확도 ===
    $display("\n=== [Before Learning] Inference (Test Data) ===");
    for (i = 0; i < 10; i = i + 1)
      infer_one_and_check(test_O[i], 1'b1, i, 1'b1);
    for (i = 0; i < 10; i = i + 1)
      infer_one_and_check(test_X[i], 1'b0, i, 1'b0);

    before_pass_count  = test_pass_count;
    before_total_count = test_total_count;
    $display("  Accuracy (before) : %0d / %0d (%.1f%%)",
             before_pass_count, before_total_count,
             (before_total_count == 0) ? 0.0 :
             100.0 * before_pass_count / before_total_count);

    test_pass_count  = 0;
    test_total_count = 0;

    // === 학습 루프 ===
    $display("\n=== Start Learning %0d epochs ===", EPOCHS);
    for (epoch = 0; epoch < EPOCHS; epoch = epoch + 1) begin
      for (i = 0; i < 100; i = i + 1) learn_one(train_O[i], 1'b1);
      for (i = 0; i < 100; i = i + 1) learn_one(train_X[i], 1'b0);
      $display("  >> epoch %0d/%0d completed", epoch + 1, EPOCHS);
    end

    // === 학습 후 정확도 ===
    $display("\n=== [After Learning] Inference (Test Data) ===");
    for (i = 0; i < 10; i = i + 1)
      infer_one_and_check(test_O[i], 1'b1, i, 1'b1);
    for (i = 0; i < 10; i = i + 1)
      infer_one_and_check(test_X[i], 1'b0, i, 1'b0);

    // === 테스트 정확도 출력 ===
    $display("\n=== [Test Accuracy] ===");
    $display("  Passed %0d / %0d (%.1f%%)", 
             test_pass_count, test_total_count,
             (test_total_count == 0) ? 0.0 :
             100.0 * test_pass_count / test_total_count);

    $display("  Sample weights: w_o[0]=%0d b_o=%0d",
             dut.u_update.w_o[0], dut.u_update.b_o);

    $display("\n=== Done ===");
    #50 $finish;
  end

endmodule
