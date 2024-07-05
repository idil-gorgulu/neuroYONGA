module Convolution (
    input wire clock,
    input wire start,
    input wire [1151:0] coef,       // 3x3x32 x 4-bit
    input wire [127:0] bias,        // 4-bit 32 kernels
    input wire [3135:0] img,        // 28x28 x 4-bit
    output reg [43263:0] new_img,   // 13x13x32 x 8-bit
    output reg done                 // Convolution done signal
);

    // Image and kernel types
    typedef reg signed [3:0] input_image [0:27][0:27];
    typedef reg signed [7:0] output_image [0:25][0:25];
    typedef reg signed [7:0] pool_image [0:12][0:12];
    typedef reg signed [3:0] coeffs [0:31][0:2][0:2];
    typedef reg signed [7:0] feature_type [0:31][0:12][0:12];
    typedef reg signed [3:0] bias_type [0:31];

    // Signal declarations
    input_image image;
    output_image output;
    reg signed [7:0] sum = 8'h00;
    coeffs krnl;
    feature_type feature;
    bias_type biases;

    typedef enum reg [2:0] {serial, deserial, deserial_krnl, deserial_bias, conv, idle, pooling, finish} layer_state;
    reg layer_state state = deserial;

    // ReLU function
    function signed [7:0] relu;
        input signed [7:0] x;
        begin
            if (x > 0)
                relu = x;
            else
                relu = 8'h00;
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

    // Flow process
    always @(posedge clock) begin
        if (start == 1) begin
            integer i_counter, j_counter, krnl_index, c, x_counter, y_counter, kx_counter, ky_counter, px, py, x, y, a, b, d, kernel_counter;
            reg signed [7:0] sumvar, ixk, max_pool_val;
            reg signed [3:0] temp_coeff;
            reg ok;

            case (state)
                idle: begin
                    x_counter <= 0;
                    y_counter <= 0;
                    kx_counter <= 0;
                    ky_counter <= 0;
                    ok <= 0;
                    x <= 0;
                    y <= 0;
                    kernel_counter <= kernel_counter + 1;
                    if (kernel_counter == 32)
                        state <= serial;
                    else
                        state <= conv;
                end

                deserial: begin
                    image[j_counter][i_counter] <= $signed({1'b0, img[(i_counter + j_counter * 28) * 4 +: 4]});
                    if (i_counter == 27) begin
                        i_counter <= 0;
                        if (j_counter == 27) begin
                            j_counter <= 0;
                            state <= deserial_krnl;
                            done <= 0;
                            sumvar <= 8'h00 + biases[kernel_counter];
                        end else begin
                            j_counter <= j_counter + 1;
                        end
                    end else begin
                        i_counter <= i_counter + 1;
                    end
                end

                deserial_krnl: begin
                    temp_coeff <= $signed(coef[(krnl_index * 9 + ky_counter * 3 + kx_counter) * 4 +: 4]);
                    krnl[krnl_index][ky_counter][kx_counter] <= temp_coeff;
                    if (kx_counter == 2) begin
                        kx_counter <= 0;
                        if (ky_counter == 2) begin
                            ky_counter <= 0;
                            if (krnl_index == 31) begin
                                krnl_index <= 0;
                                state <= deserial_bias;
                            end else begin
                                krnl_index <= krnl_index + 1;
                            end
                        end else begin
                            ky_counter <= ky_counter + 1;
                        end
                    end else begin
                        kx_counter <= kx_counter + 1;
                    end
                end

                deserial_bias: begin
                    biases[i_counter] <= $signed(bias[i_counter * 4 +: 4]);
                    i_counter <= i_counter + 1;
                    if (i_counter == 32) begin
                        i_counter <= 0;
                        state <= conv;
                    end
                end

                conv: begin
                    ixk <= image[y_counter + ky_counter][x_counter + kx_counter] * krnl[kernel_counter][ky_counter][kx_counter];
                    sumvar <= sumvar + ixk;
                    kx_counter <= (kx_counter + 1) % 3;
                    if (kx_counter == 2) begin
                        ky_counter <= (ky_counter + 1) % 3;
                    end
                    if (kx_counter == 2 && ky_counter == 2) begin
                        output[y_counter][x_counter] <= relu(sumvar);
                        sumvar <= 8'h00 + biases[kernel_counter];
                        x_counter <= (x_counter + 1) % 26;
                        if (x_counter == 25) begin
                            y_counter <= (y_counter + 1) % 26;
                            if (ok == 1)
                                state <= pooling;
                            if (y_counter == 0)
                                ok <= 1;
                        end
                    end
                end

                pooling: begin
                    max_pool_val <= max(max(output[x * 2][y * 2], output[x * 2 + 1][y * 2]), max(output[x * 2][y * 2 + 1], output[x * 2 + 1][y * 2 + 1]));
                    feature[kernel_counter][x][y] <= max_pool_val;
                    y <= (y + 1) % 13;
                    if (y == 0)
                        x <= (x + 1) % 13;
                    if (x == 12 && y == 12) begin
                        max_pool_val <= max(max(output[x * 2][y * 2], output[x * 2 + 1][y * 2]), max(output[x * 2][y * 2 + 1], output[x * 2 + 1][y * 2 + 1]));
                        feature[kernel_counter][x][y] <= max_pool_val;
                        state <= idle;
                    end
                end

                serial: begin
                    new_img[d * 8 +: 8] <= feature[c][b][a];
                    d <= d + 1;
                    if (a == 12) begin
                        a <= 0;
                        if (b == 12) begin
                            b <= 0;
                            if (c == 31)
                                state <= finish;
                            c <= c + 1;
                        end else begin
                            b <= b + 1;
                        end
                    end else begin
                        a <= a + 1;
                    end
                end

                default: done <= 1;
            endcase
        end
    end
endmodule
