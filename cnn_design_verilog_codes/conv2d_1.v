module Convolution1 (
    input wire clock,
    input wire start,
    input wire [73727:0] coef,       // 3x3x32x64 x 4-bit
    input wire [255:0] bias,
    input wire [43263:0] img,        // 28x28 image, assuming 16-bit per pixel
    output reg [19199:0] new_img,    // 26x26x32x16 output image, assuming 16-bit per pixel
    output reg done                  // Convolution done signal
);

    // Image and kernel types
    typedef reg signed [7:0] input_type [0:12][0:12][0:31];
    typedef reg signed [3:0] kernel_type [0:2][0:2][0:31][0:63];
    typedef reg signed [3:0] bias_type [0:63];
    typedef reg signed [11:0] output_type [0:10][0:10][0:63];
    typedef reg signed [11:0] feature_type [0:4][0:4][0:63];

    // Signal declarations
    input_type image;
    kernel_type krnl;
    bias_type biases;
    output_type output;
    feature_type feature;

    typedef enum reg [2:0] {serial, deserial, deserial_krnl, deserial_bias, conv, idle, pooling, finish} layer_state;
    reg layer_state state = deserial;

    // ReLU function
    function signed [11:0] relu;
        input signed [11:0] x;
        begin
            if (x > 0)
                relu = x;
            else
                relu = 12'h000;
        end
    endfunction

    // Max function
    function signed [11:0] max;
        input signed [11:0] a, b;
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
            integer i_counter, j_counter, k_counter, ds_counter, krnl_index, c, kx_counter, ky_counter, kz_counter, kt_counter;
            integer z_counter, bias_counter, image_counter, x_counter, y_counter, px, py, x, y, a, b, d, p, feature_counter;
            reg signed [11:0] sumvar, ixk, max_pool_val;
            reg signed [3:0] temp_coeff;
            reg ok;

            case (state)
                deserial: begin
                    image[i_counter][j_counter][k_counter] <= $signed({1'b0, img[ds_counter * 8 +: 8]});
                    ds_counter = ds_counter + 1;
                    if (k_counter == 31) begin
                        k_counter = 0;
                        if (j_counter == 12) begin
                            j_counter = 0;
                            if (i_counter == 12) begin
                                i_counter = 0;
                                state = deserial_krnl;
                                done = 0;
                            end else begin
                                i_counter = i_counter + 1;
                            end
                        end else begin
                            j_counter = j_counter + 1;
                        end
                    end else begin
                        k_counter = k_counter + 1;
                    end
                end

                deserial_krnl: begin
                    temp_coeff = $signed(coef[p * 4 +: 4]);
                    p = p + 1;
                    krnl[kx_counter][ky_counter][kz_counter][kt_counter] <= temp_coeff;
                    if (kt_counter == 63) begin
                        kt_counter = 0;
                        if (kz_counter == 31) begin
                            kz_counter = 0;
                            if (ky_counter == 2) begin
                                ky_counter = 0;
                                if (kx_counter == 2) begin
                                    kx_counter = 0;
                                    sumvar = 12'h000 + biases[bias_counter];
                                    krnl_index = 0;
                                    state = deserial_bias;
                                end else begin
                                    kx_counter = kx_counter + 1;
                                end
                            end else begin
                                ky_counter = ky_counter + 1;
                            end
                        end else begin
                            kz_counter = kz_counter + 1;
                        end
                    end else begin
                        kt_counter = kt_counter + 1;
                    end
                end

                deserial_bias: begin
                    biases[z_counter] <= $signed(bias[z_counter * 4 +: 4]);
                    z_counter = z_counter + 1;
                    if (z_counter == 64) begin
                        z_counter = 0;
                        state = conv;
                    end
                end

                conv: begin
                    ixk = image[i_counter + kx_counter][j_counter + ky_counter][kz_counter] * krnl[kx_counter][ky_counter][kz_counter][kt_counter];
                    sumvar = sumvar + ixk;
                    kz_counter = kz_counter + 1;
                    if (kz_counter == 32) begin
                        kz_counter = 0;
                        ky_counter = ky_counter + 1;
                        if (ky_counter == 3) begin
                            ky_counter = 0;
                            kx_counter = kx_counter + 1;
                            if (kx_counter == 3) begin
                                kx_counter = 0;
                                output[i_counter][j_counter][kt_counter] <= relu(sumvar);
                                j_counter = j_counter + 1;
                                sumvar = 12'h000 + biases[kt_counter];
                                if (j_counter == 11) begin
                                    j_counter = 0;
                                    i_counter = i_counter + 1;
                                    if (i_counter == 11) begin
                                        i_counter = 0;
                                        kt_counter = kt_counter + 1;
                                        if (kt_counter == 64) begin
                                            kt_counter = 0;
                                            if (ok == 1)
                                                state = pooling;
                                            if (kt_counter == 0)
                                                ok = 1;
                                        end
                                    end
                                end
                            end
                        end
                    end
                end

                pooling: begin
                    max_pool_val = max(max(output[x * 2][y * 2][z], output[x * 2 + 1][y * 2][z]), max(output[x * 2][y * 2 + 1][z], output[x * 2 + 1][y * 2 + 1][z]));
                    feature[x][y][z] <= max_pool_val;
                    y = y + 1;
                    if (y == 5) begin
                        y = 0;
                        x = x + 1;
                        if (x == 5) begin
                            x = 0;
                            z = z + 1;
                            if (z == 64) begin
                                z = 0;
                                state = serial;
                            end
                        end
                    end
                end

                serial: begin
                    new_img[d * 12 +: 12] <= feature[x][y][z];
                    d = d + 1;
                    if (z == 63) begin
                        z = 0;
                        if (y == 4) begin
                            y = 0;
                            if (x == 4) begin
                                state = finish;
                            end else begin
                                x = x + 1;
                            end
                        end else begin
                            y = y + 1;
                        end
                    end else begin
                        z = z + 1;
                    end
                end

                default: done = 1;
            endcase
        end
    end
endmodule
