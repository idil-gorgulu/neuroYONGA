module top (
    input wire clock,
    input wire start,           // Start signal for convolution
    input wire [138879:0] coef,
    input wire [423:0] bias,
    input wire [3135:0] img,    // 28x28 image, assuming 16-bit per pixel
    output wire done            // Convolution done signal
);

    // Internal signals
    wire [43263:0] layer1_output;
    wire [19199:0] layer2_output;
    wire layer1_start, layer2_start;

    assign layer1_start = (layer1_start_wire == 1) ? 1 : 0;
    assign layer2_start = (layer2_start_wire == 1) ? 1 : 0;

    // Instantiate Convolution component
    Convolution layer1 (
        .clock(clock),
        .start(start),
        .coef(coef[1151:0]),
        .bias(bias[127:0]),
        .img(img),
        .new_img(layer1_output),
        .done(layer1_start)
    );

    // Instantiate Convolution1 component
    Convolution1 layer2 (
        .clock(clock),
        .start(layer1_start),
        .coef(coef[74879:1152]),
        .bias(bias[383:128]),
        .img(layer1_output),
        .new_img(layer2_output),
        .done(layer2_start)
    );

    // Instantiate dense component
    dense layer3 (
        .clock(clock),
        .start(layer2_start),
        .coef(coef[138879:74880]),
        .bias(bias[423:384]),
        .img(layer2_output),
        .done(done)
    );

endmodule

module Convolution (
    input wire clock,
    input wire start,
    input wire [1151:0] coef,   // 3x3x32 x 4-bit
    input wire [127:0] bias,    // 4-bit 32 kernels
    input wire [3135:0] img,    // 28x28 x 4-bit
    output wire [43263:0] new_img, // 13x13x32 x 8-bit
    output wire done            // Convolution done signal
);

    // Convolution logic here

endmodule

module Convolution1 (
    input wire clock,
    input wire start,
    input wire [73727:0] coef,       // 3x3x32x64 x 4-bit
    input wire [255:0] bias,
    input wire [43263:0] img,        // 28x28 image, assuming 16-bit per pixel
    output wire [19199:0] new_img,   // 26x26x32x16 output image, assuming 16-bit per pixel
    output wire done                 // Convolution done signal
);

    // Convolution1 logic here

endmodule

module dense (
    input wire clock,
    input wire start,
    input wire [63999:0] coef,       // 1600x10 x 4-bit
    input wire [39:0] bias,          // 10 x 4-bit
    input wire [19199:0] img,        // 28x28 image, assuming 16-bit per pixel
    output wire done                 // Convolution done signal
);

    // Dense logic here

endmodule
