`timescale 1ns / 1ps
module Convolution1(
    input clock,
    input start,
    input [73727:0] coef,
    input [255:0] bias,
    input [43263:0] img,
    output reg [19199:0] new_img,
    output reg done
);

// State parameters
localparam DESERIAL = 0, DESERIAL_KRNL = 1, DESERIAL_BIAS = 2, CONV = 3, IDLE = 4, POOLING = 5, SERIAL = 6, FINISH = 7;
reg [2:0] state = DESERIAL;

// Type definitions
reg signed [7:0] image [12:0][12:0][31:0];
reg signed [3:0] krnl [2:0][2:0][31:0][63:0];
reg signed [3:0] biases [63:0];
reg signed [11:0] outputs [10:0][10:0][63:0];
reg signed [11:0] feature [4:0][4:0][63:0];

// Counter variables
integer i_counter = 0, j_counter = 0, k_counter = 0;
integer krnl_index = 0, c = 0;
integer kx_counter = 0, ky_counter = 0, kz_counter = 0, kt_counter = 0;
integer z_counter = 0, z = 0, bias_counter = 0;
integer x_counter = 0, y_counter = 0;
integer ds_counter = 0, p = 0, d = 0;
integer x = 0, y = 0, z = 0;

// Temporary variables
reg signed [3:0] temp_coeff;
reg signed [11:0] sumvar = 12'd0, ixk = 12'd0;
reg signed [11:0] max_pool_val;
reg ok = 0;

// ReLU and Max functions
function signed [11:0] relu(input signed [11:0] x);
    begin
        if (x > 0)
            relu = x;
        else
            relu = 12'd0;
    end
endfunction

function signed [11:0] max(input signed [11:0] a, input signed [11:0] b);
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
            DESERIAL: begin
                image[i_counter][j_counter][k_counter] = $signed(img[ds_counter * 8 +: 8]);
                ds_counter = ds_counter + 1;
                if (k_counter == 31) begin
                    k_counter = 0;
                    if (j_counter == 12) begin
                        j_counter = 0;
                        if (i_counter == 12) begin
                            i_counter = 0;
                            state = DESERIAL_KRNL;
                            done = 1'b0;
                        end
                        i_counter = i_counter + 1;
                    end
                    j_counter = j_counter + 1;
                end
                k_counter = k_counter + 1;
            end

            DESERIAL_KRNL: begin
                temp_coeff = $signed(coef[p * 4 +: 4]);
                p = p + 1;
                krnl[kx_counter][ky_counter][kz_counter][kt_counter] = temp_coeff;
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
                                state = DESERIAL_BIAS;
                            end
                            kx_counter = kx_counter + 1;
                        end
                        ky_counter = ky_counter + 1;
                    end
                    kz_counter = kz_counter + 1;
                end
                kt_counter = kt_counter + 1;
            end

            DESERIAL_BIAS: begin
                biases[z_counter] = $signed(bias[z_counter * 4 +: 4]);
                z_counter = z_counter + 1;
                if (z_counter == 64) begin
                    z_counter = 0;
                    state = CONV;
                end
            end

            CONV: begin
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
                            outputs[i_counter][j_counter][kt_counter] = relu(sumvar);
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
                                        if (ok == 1'b1) begin
                                            state = POOLING;
                                        end
                                        if (kt_counter == 0) begin
                                            ok = 1'b1;
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end

            POOLING: begin
                max_pool_val = max(max(outputs[x * 2][y * 2][z], outputs[x * 2 + 1][y * 2][z]), max(outputs[x * 2][y * 2 + 1][z], outputs[x * 2 + 1][y * 2 + 1][z]));
                feature[x][y][z] = max_pool_val;
                y = y + 1;
                if (y == 5) begin
                    y = 0;
                    x = x + 1;
                    if (x == 5) begin
                        x = 0;
                        z = z + 1;
                        if (z == 64) begin
                            z = 0;
                            state = SERIAL;
                        end
                    end
                end
            end

            SERIAL: begin
                new_img[d * 12 +: 12] = $unsigned(feature[x][y][z]);
                d = d + 1;
                if (z == 63) begin
                    z = 0;
                    if (y == 4) begin
                        y = 0;
                        if (x == 4) begin
                            state = FINISH;
                        end
                        x = x + 1;
                    end
                    y = y + 1;
                end
                z = z + 1;
            end

            default: begin
                done = 1'b1;
            end
        endcase;
    end
end

endmodule
