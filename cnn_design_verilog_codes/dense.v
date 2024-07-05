module dense (
    input wire clock,
    input wire start,
    input wire [63999:0] coef,       // 1600x10 x 4-bit
    input wire [39:0] bias,          // 10 x 4-bit
    input wire [19199:0] img,        // 28x28 image, assuming 16-bit per pixel
    output reg done                  // Convolution done signal
);

    // Internal type definitions
    typedef reg signed [3:0] bias_array [0:9];
    typedef reg signed [3:0] weight_matrix [0:1599][0:9];
    typedef reg signed [11:0] image_array [0:1599];
    typedef reg signed [63:0] output_array [0:9];

    // Signal declarations
    bias_array biases;
    weight_matrix weights;
    image_array image;
    output_array outputs;

    // Sigmoid lookup table
    // Sigmoid lookup table
	typedef reg signed [15:0] sigmoid_lut_type [0:255];
	sigmoid_lut_type sigmoid_lut = '{
		16'sd589, 16'sd607, 16'sd626, 16'sd646, 16'sd666, 16'sd687, 16'sd708, 16'sd730, 16'sd753, 16'sd777, 16'sd801, 16'sd826, 16'sd851, 16'sd878,
		16'sd905, 16'sd933, 16'sd962, 16'sd992, 16'sd1022, 16'sd1054, 16'sd1086, 16'sd1120, 16'sd1154, 16'sd1190, 16'sd1226, 16'sd1264, 16'sd1302, 16'sd1342,
		16'sd1383, 16'sd1425, 16'sd1469, 16'sd1513, 16'sd1559, 16'sd1607, 16'sd1655, 16'sd1705, 16'sd1757, 16'sd1810, 16'sd1864, 16'sd1920, 16'sd1978, 16'sd2037,
		16'sd2097, 16'sd2160, 16'sd2224, 16'sd2290, 16'sd2358, 16'sd2427, 16'sd2499, 16'sd2572, 16'sd2648, 16'sd2725, 16'sd2804, 16'sd2886, 16'sd2969, 16'sd3055,
		16'sd3143, 16'sd3234, 16'sd3326, 16'sd3421, 16'sd3519, 16'sd3618, 16'sd3721, 16'sd3825, 16'sd3933, 16'sd4042, 16'sd4155, 16'sd4270, 16'sd4388, 16'sd4509,
		16'sd4632, 16'sd4758, 16'sd4887, 16'sd5019, 16'sd5154, 16'sd5292, 16'sd5432, 16'sd5576, 16'sd5723, 16'sd5873, 16'sd6025, 16'sd6181, 16'sd6340, 16'sd6502,
		16'sd6667, 16'sd6835, 16'sd7006, 16'sd7181, 16'sd7358, 16'sd7539, 16'sd7723, 16'sd7909, 16'sd8099, 16'sd8292, 16'sd8488, 16'sd8686, 16'sd8888, 16'sd9093,
		16'sd9300, 16'sd9511, 16'sd9724, 16'sd9940, 16'sd10158, 16'sd10380, 16'sd10603, 16'sd10830, 16'sd11058, 16'sd11289, 16'sd11523, 16'sd11758, 16'sd11996, 16'sd12235,
		16'sd12477, 16'sd12720, 16'sd12965, 16'sd13211, 16'sd13460, 16'sd13709, 16'sd13960, 16'sd14212, 16'sd14465, 16'sd14719, 16'sd14973, 16'sd15229, 16'sd15485, 16'sd15741,
		16'sd15998, 16'sd16255, 16'sd16512, 16'sd16769, 16'sd17026, 16'sd17282, 16'sd17538, 16'sd17794, 16'sd18048, 16'sd18302, 16'sd18555, 16'sd18807, 16'sd19058, 16'sd19307,
		16'sd19556, 16'sd19802, 16'sd20047, 16'sd20290, 16'sd20532, 16'sd20771, 16'sd21009, 16'sd21244, 16'sd21478, 16'sd21709, 16'sd21937, 16'sd22164, 16'sd22387, 16'sd22609,
		16'sd22827, 16'sd23043, 16'sd23256, 16'sd23467, 16'sd23674, 16'sd23879, 16'sd24081, 16'sd24279, 16'sd24475, 16'sd24668, 16'sd24858, 16'sd25044, 16'sd25228, 16'sd25409,
		16'sd25586, 16'sd25761, 16'sd25932, 16'sd26100, 16'sd26265, 16'sd26427, 16'sd26586, 16'sd26742, 16'sd26894, 16'sd27044, 16'sd27191, 16'sd27335, 16'sd27475, 16'sd27613,
		16'sd27748, 16'sd27880, 16'sd28009, 16'sd28135, 16'sd28258, 16'sd28379, 16'sd28497, 16'sd28612, 16'sd28725, 16'sd28834, 16'sd28942, 16'sd29046, 16'sd29149, 16'sd29248,
		16'sd29346, 16'sd29441, 16'sd29533, 16'sd29624, 16'sd29712, 16'sd29798, 16'sd29881, 16'sd29963, 16'sd30042, 16'sd30119, 16'sd30195, 16'sd30268, 16'sd30340, 16'sd30409,
		16'sd30477, 16'sd30543, 16'sd30607, 16'sd30670, 16'sd30730, 16'sd30789, 16'sd30847, 16'sd30903, 16'sd30957, 16'sd31010, 16'sd31062, 16'sd31112, 16'sd31160, 16'sd31208,
		16'sd31254, 16'sd31298, 16'sd31342, 16'sd31384, 16'sd31425, 16'sd31465, 16'sd31503, 16'sd31541, 16'sd31577, 16'sd31613, 16'sd31647, 16'sd31681, 16'sd31713, 16'sd31745,
		16'sd31775, 16'sd31805, 16'sd31834, 16'sd31862, 16'sd31889, 16'sd31916, 16'sd31941, 16'sd31966, 16'sd31990, 16'sd32014, 16'sd32037, 16'sd32059, 16'sd32080, 16'sd32101,
		16'sd32121, 16'sd32141, 16'sd32160, 16'sd32178, 16'sd32195, 16'sd32213, 16'sd32229, 16'sd32245, 16'sd32261, 16'sd32276, 16'sd32291, 16'sd32305, 16'sd32319, 16'sd32332,
		16'sd32345, 16'sd32358, 16'sd32370, 16'sd32382, 16'sd32394, 16'sd32406, 16'sd32417, 16'sd32428, 16'sd32439, 16'sd32449, 16'sd32460, 16'sd32470, 16'sd32480, 16'sd32490,
		16'sd32499, 16'sd32509, 16'sd32518, 16'sd32527, 16'sd32536, 16'sd32544, 16'sd32553, 16'sd32561, 16'sd32569, 16'sd32577, 16'sd32585, 16'sd32593, 16'sd32600, 16'sd32608
	};


    function signed [15:0] sigmoid;
        input signed [63:0] x;
        integer index;
        begin
            index = x[31:24];  // Use most significant 8 bits as index
            sigmoid = sigmoid_lut[index];
        end
    endfunction

    typedef enum reg [2:0] {deserial_input, deserial_weights, deserial_biases, conv, sigmoid, finish} layer_state;
    reg layer_state state = deserial_input;

    // Flow process
    always @(posedge clock) begin
        if (start == 1) begin
            integer i, j, y, x;
            reg signed [3:0] temp_coeff;
            reg signed [63:0] sumvar;
            reg signed [15:0] ixk;
            reg ok;
            
            case (state)
                deserial_input: begin
                    image[i] <= $signed(img[i * 12 +: 12]);
                    i = i + 1;
                    if (i == 1600) begin
                        state = deserial_weights;
                        i = 0;
                    end
                end

                deserial_weights: begin
                    temp_coeff = $signed(coef[y * 4 +: 4]);
                    weights[j][x] <= temp_coeff;
                    y = y + 1;
                    if (x == 9) begin
                        x = 0;
                        if (j == 1599) begin
                            j = 0;
                            state = deserial_biases;
                        end else begin
                            j = j + 1;
                        end
                    end else begin
                        x = x + 1;
                    end
                end

                deserial_biases: begin
                    biases[i] <= $signed(bias[i * 4 +: 4]);
                    i = i + 1;
                    if (i == 10) begin
                        i = 0;
                        state = conv;
                        sumvar = 64'h0000000000000000 + biases[x];
                    end
                end

                conv: begin
                    ixk = image[j] * weights[j][x];
                    sumvar = sumvar + ixk;
                    j = j + 1;
                    if (j == 1600) begin
                        outputs[x] <= sigmoid(sumvar);
                        j = 0;
                        x = x + 1;
                        if (x == 10) begin
                            x = 0;
                            state = finish;
                        end
                        sumvar = 64'h0000000000000000 + biases[x];
                    end
                end

                default: done = 1;
            endcase
        end
    end
endmodule
