`timescale 1ns / 1ps
module Convolution(
    input clock,
    input start,        // Start signal for convolution
    input [1151:0] coef,// 3x3x32 x 4-bit coefficients
    input [127:0] bias, // 4-bit 32 kernels
    input [3135:0] img, // 28x28 x 4-bit image
    output reg [43263:0] new_img, // 13x13x32 x 8-bit
    output reg done     // Convolution done signal
);

// Parameters for state machine
localparam IDLE = 0, DESERIAL = 1, DESERIAL_KRNL = 2, DESERIAL_BIAS = 3, CONV = 4, POOLING = 5, SERIAL = 6, FINISH = 7;
reg [2:0] state = DESERIAL;

// Image, kernel, and output types, assuming 16-bit signed integers
reg signed [3:0] image [0:27][0:27];
reg signed [7:0] outputs [0:25][0:25];
reg signed [7:0] pool_image [0:12][0:12];
reg signed [3:0] krnl [0:31][0:2][0:2];
reg signed [7:0] feature [0:31][0:12][0:12];
reg signed [3:0] biases [0:31];

// Signal declarations
reg signed [7:0] sum = 8'd0;
integer i_counter = 0, j_counter = 0;
integer krnl_index = 0, kernel_counter = 0; 
integer x_counter = 0, y_counter = 0, kx_counter = 0, ky_counter = 0;
integer x = 0, y = 0, a = 0, b = 0, c = 0, d = 0;
reg ok = 0;
reg signed [7:0] ixk = 8'd0;
reg signed [3:0] temp_coeff;
reg signed [7:0] max_pool_val;

// ReLU function
function signed [7:0] relu;
    input signed [7:0] x;
    begin
        if (x > 0)
            relu = x;
        else
            relu = 8'd0;
    end
endfunction

// Max function
function signed [7:0] max;
    input signed [7:0] a, b;
    begin
        if (a > b)
            max = a;
        else
            max = b;
    end
endfunction

always @(posedge clock) begin
    if (start == 1'b1) begin
        case (state)
            IDLE: begin
                x_counter = 0;
                y_counter = 0;
                kx_counter = 0;
                ky_counter = 0;
                ok = 0;
                x = 0;
                y = 0;
                kernel_counter = kernel_counter + 1;
                if (kernel_counter == 32)
                    state = SERIAL;
                else
                    state = CONV;
            end

            DESERIAL: begin
                image[j_counter][i_counter] = $signed(img[(i_counter + j_counter * 28) * 4 + 3 -: 4]);
                if (i_counter == 27) begin
                    i_counter = 0;
                    if (j_counter == 27) begin
                        j_counter = 0;
                        state = DESERIAL_KRNL;
                        done = 0;
                        sum = biases[kernel_counter]; // Reset sum for next stage
                    end else
                        j_counter = j_counter + 1;
                end else
                    i_counter = i_counter + 1;
            end

            DESERIAL_KRNL: begin
                temp_coeff = $signed(coef[(krnl_index * 9 + ky_counter * 3 + kx_counter) * 4 + 3 -: 4]);
                krnl[krnl_index][ky_counter][kx_counter] = temp_coeff;

                // Update counters for kernel matrix positions
                if (kx_counter == 2) begin
                    kx_counter = 0;
                    if (ky_counter == 2) begin
                        ky_counter = 0;
                        if (krnl_index == 31) begin
                            krnl_index = 0;
                            state = DESERIAL_BIAS;  // Assuming next state is convolution
                        end else
                            krnl_index = krnl_index + 1;
                    end else
                        ky_counter = ky_counter + 1;
                end else
                    kx_counter = kx_counter + 1;
            end

            DESERIAL_BIAS: begin
                biases[i_counter] = $signed(bias[i_counter * 4 + 3 -: 4]);
                i_counter = i_counter + 1;
                if (i_counter == 32) begin
                    i_counter = 0;
                    state = CONV;
                end
            end

            CONV: begin
                ixk = image[y_counter + ky_counter][x_counter + kx_counter] * krnl[kernel_counter][ky_counter][kx_counter];
                sum = sum + ixk;
                kx_counter = (kx_counter + 1) % 3;

                if (kx_counter == 2 && ky_counter == 2) begin // End of kernel loop
                    outputs[y_counter][x_counter] = relu(sum);

                    sum = biases[kernel_counter]; // Reset sum for next pixel computation
                    x_counter = (x_counter + 1) % 26; // Increment x after finishing one complete kernel computation

                    if (x_counter == 25) begin // After max index 25, reset and increment y
                        y_counter = (y_counter + 1) % 26;
                        if (ok == 1) begin
                            state = POOLING;
                        end
                        if (y_counter == 0) begin
                            ok = 1;
                        end
                    end
                end
            end

            POOLING: begin
                max_pool_val = max(max(outputs[x * 2][y * 2], outputs[x * 2 + 1][y * 2]), max(outputs[x * 2][y * 2 + 1], outputs[x * 2 + 1][y * 2 + 1]));

                feature[kernel_counter][x][y] = max_pool_val;

                // Increment indices for pooling
                y = (y + 1) % 13;  // Increment the column index for pooling
                if (y == 0) begin
                    x = (x + 1) % 13;  // Increment the row index when a column completes
                end

                if (x == 12 && y == 12) begin  // Check if last pooling element
                    max_pool_val = max(max(outputs[x * 2][y * 2], outputs[x * 2 + 1][y * 2]), max(outputs[x * 2][y * 2 + 1], outputs[x * 2 + 1][y * 2 + 1]));
                    feature[kernel_counter][x][y] = max_pool_val;
                    state = IDLE;  // Move to idle or another state as needed
                end
            end

            SERIAL: begin
                new_img[d * 8 +: 8] = $unsigned(feature[c][b][a]);
                d = d + 1;
                if (a == 12) begin
                    a = 0;
                    if (b == 12) begin
                        b = 0;
                        if (c == 31) begin
                            state = FINISH;
                        end
                        c = c + 1;
                    end else
                        b = b + 1;
                end else
                    a = a + 1;
            end

            default: begin
                done = 1;
            end
        endcase;
    end
end

endmodule
