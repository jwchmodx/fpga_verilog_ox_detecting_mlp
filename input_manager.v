`timescale 1ns/1ps

// Input Manager Module
// Manages accumulation of multiple button/keypad inputs and combines them
module input_manager (
    input  clk,
    input  rst,
    input  [15:0] input_value,      // Current input value (16-bit one-hot)
    input  input_valid,             // Valid signal for new input
    input  btn_submit,              // Submit button to finalize sequence
    output reg [15:0] current_display,      // Current value to display
    output reg display_valid,               // Pulse high when display should update
    output reg [15:0] combined_input_flags, // OR of all inputs after submit
    output reg [3:0] input_count            // Number of inputs stored (for debug)
);

    // Input buffer for accumulating multiple inputs
    reg [15:0] input_buffer [0:15];  // Store up to 16 inputs
    reg input_valid_prev;            // For edge detection
    reg input_submitted;             // Flag indicating submit button pressed
    reg input_processing;            // Flag to prevent multiple captures during long press
    reg [15:0] prev_input_value;     // Previous input value for comparison
    reg [15:0] temp_combined;        // Temporary variable for combining inputs
    integer i;
    
    always @(posedge clk or negedge rst) begin
        if (~rst) begin
            input_count <= 0;
            input_valid_prev <= 0;
            current_display <= 16'b0;
            input_submitted <= 0;
            input_processing <= 0;
            display_valid <= 0;
            prev_input_value <= 16'b0;
            combined_input_flags <= 16'b0;
            for (i = 0; i < 16; i = i + 1) begin
                input_buffer[i] <= 16'b0;
            end
        end else begin
            input_valid_prev <= input_valid;
            display_valid <= 0;  // Default to 0, pulse high when new input
            
            // Detect rising edge of valid signal (button just pressed)
            if (input_valid && !input_valid_prev && !input_processing) begin
                // Only store if value is different from previous input
                if (input_value != prev_input_value && input_count < 16) begin
                    input_buffer[input_count] <= input_value;
                    input_count <= input_count + 1;
                    current_display <= input_value;  // Update display
                    display_valid <= 1;  // Signal display to update
                    prev_input_value <= input_value;  // Remember this value
                end
                input_processing <= 1;  // Start processing
            end
            // Detect falling edge of valid signal (button released)
            else if (!input_valid && input_valid_prev && input_processing) begin
                input_processing <= 0;  // Ready for next input
            end
            
            // Submit button logic - combine all inputs and clear buffer
            if (btn_submit && !input_submitted) begin
                input_submitted <= 1;
                
                // Combine all inputs with OR operation using temporary variable
                temp_combined = 16'b0;
                for (i = 0; i < input_count; i = i + 1) begin
                    temp_combined = temp_combined | input_buffer[i];
                end
                combined_input_flags <= temp_combined;  // Store result
                
                // combined_input_flags now contains OR of all inputs
                // This can be used as neural network input
            end else if (!btn_submit && input_submitted) begin
                // Reset after submit button released
                input_submitted <= 0;
                input_count <= 0;
                current_display <= 16'b0;
                combined_input_flags <= 16'b0;
                for (i = 0; i < 16; i = i + 1) begin
                    input_buffer[i] <= 16'b0;
                end
            end
        end
    end

endmodule

