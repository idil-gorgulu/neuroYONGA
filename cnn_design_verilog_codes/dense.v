`timescale 1ns / 1ps

module dense (
    input wire clk,
    input wire start,
    input wire [63999:0] coef,  // 1600x10 x 4-bit
    input wire [39:0] bias,     // 10 x 4-bit
    input wire [19199:0] img,   // 28x28 image, assuming 16-bit per pixel
    output reg done
);

// Sigmoid lookup table
reg signed [15:0] sigmoid_lut [0:255];
initial begin
    sigmoid_lut[0] = 16'sd589;
    sigmoid_lut[1] = 16'sd607;
    sigmoid_lut[2] = 16'sd626;
    sigmoid_lut[3] = 16'sd646;
    sigmoid_lut[4] = 16'sd666;
    sigmoid_lut[5] = 16'sd687;
    sigmoid_lut[6] = 16'sd708;
    sigmoid_lut[7] = 16'sd730;
    sigmoid_lut[8] = 16'sd753;
    sigmoid_lut[9] = 16'sd777;
    sigmoid_lut[10] = 16'sd801;
    sigmoid_lut[11] = 16'sd826;
    sigmoid_lut[12] = 16'sd851;
    sigmoid_lut[13] = 16'sd878;
    sigmoid_lut[14] = 16'sd905;
    sigmoid_lut[15] = 16'sd933;
    sigmoid_lut[16] = 16'sd962;
    sigmoid_lut[17] = 16'sd992;
    sigmoid_lut[18] = 16'sd1022;
    sigmoid_lut[19] = 16'sd1054;
    sigmoid_lut[20] = 16'sd1086;
    sigmoid_lut[21] = 16'sd1120;
    sigmoid_lut[22] = 16'sd1154;
    sigmoid_lut[23] = 16'sd1190;
    sigmoid_lut[24] = 16'sd1226;
    sigmoid_lut[25] = 16'sd1264;
    sigmoid_lut[26] = 16'sd1302;
    sigmoid_lut[27] = 16'sd1342;
    sigmoid_lut[28] = 16'sd1383;
    sigmoid_lut[29] = 16'sd1425;
    sigmoid_lut[30] = 16'sd1469;
    sigmoid_lut[31] = 16'sd1513;
    sigmoid_lut[32] = 16'sd1559;
    sigmoid_lut[33] = 16'sd1607;
    sigmoid_lut[34] = 16'sd1655;
    sigmoid_lut[35] = 16'sd1705;
    sigmoid_lut[36] = 16'sd1757;
    sigmoid_lut[37] = 16'sd1810;
    sigmoid_lut[38] = 16'sd1864;
    sigmoid_lut[39] = 16'sd1920;
    sigmoid_lut[40] = 16'sd1978;
    sigmoid_lut[41] = 16'sd2037;
    sigmoid_lut[42] = 16'sd2097;
    sigmoid_lut[43] = 16'sd2160;
    sigmoid_lut[44] = 16'sd2224;
    sigmoid_lut[45] = 16'sd2290;
    sigmoid_lut[46] = 16'sd2358;
    sigmoid_lut[47] = 16'sd2427;
    sigmoid_lut[48] = 16'sd2499;
    sigmoid_lut[49] = 16'sd2572;
    sigmoid_lut[50] = 16'sd2648;
    sigmoid_lut[51] = 16'sd2725;
    sigmoid_lut[52] = 16'sd2804;
    sigmoid_lut[53] = 16'sd2886;
    sigmoid_lut[54] = 16'sd2969;
    sigmoid_lut[55] = 16'sd3055;
    sigmoid_lut[56] = 16'sd3143;
    sigmoid_lut[57] = 16'sd3234;
    sigmoid_lut[58] = 16'sd3326;
    sigmoid_lut[59] = 16'sd3421;
    sigmoid_lut[60] = 16'sd3519;
    sigmoid_lut[61] = 16'sd3618;
    sigmoid_lut[62] = 16'sd3721;
    sigmoid_lut[63] = 16'sd3825;
    sigmoid_lut[64] = 16'sd3933;
    sigmoid_lut[65] = 16'sd4042;
    sigmoid_lut[66] = 16'sd4155;
    sigmoid_lut[67] = 16'sd4270;
    sigmoid_lut[68] = 16'sd4388;
    sigmoid_lut[69] = 16'sd4509;
    sigmoid_lut[70] = 16'sd4632;
    sigmoid_lut[71] = 16'sd4758;
    sigmoid_lut[72] = 16'sd4887;
    sigmoid_lut[73] = 16'sd5019;
    sigmoid_lut[74] = 16'sd5154;
    sigmoid_lut[75] = 16'sd5292;
    sigmoid_lut[76] = 16'sd5432;
    sigmoid_lut[77] = 16'sd5576;
    sigmoid_lut[78] = 16'sd5723;
    sigmoid_lut[79] = 16'sd5873;
    sigmoid_lut[80] = 16'sd6025;
    sigmoid_lut[81] = 16'sd6181;
    sigmoid_lut[82] = 16'sd6340;
    sigmoid_lut[83] = 16'sd6502;
    sigmoid_lut[84] = 16'sd6667;
    sigmoid_lut[85] = 16'sd6835;
    sigmoid_lut[86] = 16'sd7006;
    sigmoid_lut[87] = 16'sd7181;
    sigmoid_lut[88] = 16'sd7358;
    sigmoid_lut[89] = 16'sd7539;
    sigmoid_lut[90] = 16'sd7723;
    sigmoid_lut[91] = 16'sd7909;
    sigmoid_lut[92] = 16'sd8099;
    sigmoid_lut[93] = 16'sd8292;
    sigmoid_lut[94] = 16'sd8488;
    sigmoid_lut[95] = 16'sd8686;
    sigmoid_lut[96] = 16'sd8888;
    sigmoid_lut[97] = 16'sd9093;
    sigmoid_lut[98] = 16'sd9300;
    sigmoid_lut[99] = 16'sd9511;
    sigmoid_lut[100] = 16'sd9724;
    sigmoid_lut[101] = 16'sd9940;
    sigmoid_lut[102] = 16'sd10158;
    sigmoid_lut[103] = 16'sd10380;
    sigmoid_lut[104] = 16'sd10603;
    sigmoid_lut[105] = 16'sd10830;
    sigmoid_lut[106] = 16'sd11058;
    sigmoid_lut[107] = 16'sd11289;
    sigmoid_lut[108] = 16'sd11523;
    sigmoid_lut[109] = 16'sd11758;
    sigmoid_lut[110] = 16'sd11996;
    sigmoid_lut[111] = 16'sd12235;
    sigmoid_lut[112] = 16'sd12477;
    sigmoid_lut[113] = 16'sd12720;
    sigmoid_lut[114] = 16'sd12965;
    sigmoid_lut[115] = 16'sd13211;
    sigmoid_lut[116] = 16'sd13460;
    sigmoid_lut[117] = 16'sd13709;
    sigmoid_lut[118] = 16'sd13960;
    sigmoid_lut[119] = 16'sd14212;
    sigmoid_lut[120] = 16'sd14465;
    sigmoid_lut[121] = 16'sd14719;
    sigmoid_lut[122] = 16'sd14973;
    sigmoid_lut[123] = 16'sd15229;
    sigmoid_lut[124] = 16'sd15485;
    sigmoid_lut[125] = 16'sd15741;
    sigmoid_lut[126] = 16'sd15998;
    sigmoid_lut[127] = 16'sd16255;
    sigmoid_lut[128] = 16'sd16512;
    sigmoid_lut[129] = 16'sd16769;
    sigmoid_lut[130] = 16'sd17026;
    sigmoid_lut[131] = 16'sd17282;
    sigmoid_lut[132] = 16'sd17538;
    sigmoid_lut[133] = 16'sd17794;
    sigmoid_lut[134] = 16'sd18048;
    sigmoid_lut[135] = 16'sd18302;
    sigmoid_lut[136] = 16'sd18555;
    sigmoid_lut[137] = 16'sd18807;
    sigmoid_lut[138] = 16'sd19058;
    sigmoid_lut[139] = 16'sd19307;
    sigmoid_lut[140] = 16'sd19556;
    sigmoid_lut[141] = 16'sd19802;
    sigmoid_lut[142] = 16'sd20047;
    sigmoid_lut[143] = 16'sd20290;
    sigmoid_lut[144] = 16'sd20532;
    sigmoid_lut[145] = 16'sd20771;
    sigmoid_lut[146] = 16'sd21009;
    sigmoid_lut[147] = 16'sd21244;
    sigmoid_lut[148] = 16'sd21478;
    sigmoid_lut[149] = 16'sd21709;
    sigmoid_lut[150] = 16'sd21937;
    sigmoid_lut[151] = 16'sd22164;
    sigmoid_lut[152] = 16'sd22387;
    sigmoid_lut[153] = 16'sd22609;
    sigmoid_lut[154] = 16'sd22827;
    sigmoid_lut[155] = 16'sd23043;
    sigmoid_lut[156] = 16'sd23256;
    sigmoid_lut[157] = 16'sd23467;
    sigmoid_lut[158] = 16'sd23674;
    sigmoid_lut[159] = 16'sd23879;
    sigmoid_lut[160] = 16'sd24081;
    sigmoid_lut[161] = 16'sd24279;
    sigmoid_lut[162] = 16'sd24475;
    sigmoid_lut[163] = 16'sd24668;
    sigmoid_lut[164] = 16'sd24858;
    sigmoid_lut[165] = 16'sd25044;
    sigmoid_lut[166] = 16'sd25228;
    sigmoid_lut[167] = 16'sd25409;
    sigmoid_lut[168] = 16'sd25586;
    sigmoid_lut[169] = 16'sd25761;
    sigmoid_lut[170] = 16'sd25932;
    sigmoid_lut[171] = 16'sd26100;
    sigmoid_lut[172] = 16'sd26265;
    sigmoid_lut[173] = 16'sd26427;
    sigmoid_lut[174] = 16'sd26586;
    sigmoid_lut[175] = 16'sd26742;
    sigmoid_lut[176] = 16'sd26894;
    sigmoid_lut[177] = 16'sd27044;
    sigmoid_lut[178] = 16'sd27191;
    sigmoid_lut[179] = 16'sd27335;
    sigmoid_lut[180] = 16'sd27475;
    sigmoid_lut[181] = 16'sd27613;
    sigmoid_lut[182] = 16'sd27748;
    sigmoid_lut[183] = 16'sd27880;
    sigmoid_lut[184] = 16'sd28009;
    sigmoid_lut[185] = 16'sd28135;
    sigmoid_lut[186] = 16'sd28258;
    sigmoid_lut[187] = 16'sd28379;
    sigmoid_lut[188] = 16'sd28497;
    sigmoid_lut[189] = 16'sd28612;
    sigmoid_lut[190] = 16'sd28725;
    sigmoid_lut[191] = 16'sd28834;
    sigmoid_lut[192] = 16'sd28942;
    sigmoid_lut[193] = 16'sd29046;
    sigmoid_lut[194] = 16'sd29149;
    sigmoid_lut[195] = 16'sd29248;
    sigmoid_lut[196] = 16'sd29346;
    sigmoid_lut[197] = 16'sd29441;
    sigmoid_lut[198] = 16'sd29533;
    sigmoid_lut[199] = 16'sd29624;
    sigmoid_lut[200] = 16'sd29712;
    sigmoid_lut[201] = 16'sd29798;
    sigmoid_lut[202] = 16'sd29881;
    sigmoid_lut[203] = 16'sd29963;
    sigmoid_lut[204] = 16'sd30042;
    sigmoid_lut[205] = 16'sd30119;
    sigmoid_lut[206] = 16'sd30195;
    sigmoid_lut[207] = 16'sd30268;
    sigmoid_lut[208] = 16'sd30340;
    sigmoid_lut[209] = 16'sd30409;
    sigmoid_lut[210] = 16'sd30477;
    sigmoid_lut[211] = 16'sd30543;
    sigmoid_lut[212] = 16'sd30607;
    sigmoid_lut[213] = 16'sd30670;
    sigmoid_lut[214] = 16'sd30730;
    sigmoid_lut[215] = 16'sd30789;
    sigmoid_lut[216] = 16'sd30847;
    sigmoid_lut[217] = 16'sd30903;
    sigmoid_lut[218] = 16'sd30957;
    sigmoid_lut[219] = 16'sd31010;
    sigmoid_lut[220] = 16'sd31062;
    sigmoid_lut[221] = 16'sd31112;
    sigmoid_lut[222] = 16'sd31160;
    sigmoid_lut[223] = 16'sd31208;
    sigmoid_lut[224] = 16'sd31254;
    sigmoid_lut[225] = 16'sd31298;
    sigmoid_lut[226] = 16'sd31342;
    sigmoid_lut[227] = 16'sd31384;
    sigmoid_lut[228] = 16'sd31425;
    sigmoid_lut[229] = 16'sd31465;
    sigmoid_lut[230] = 16'sd31503;
    sigmoid_lut[231] = 16'sd31541;
    sigmoid_lut[232] = 16'sd31577;
    sigmoid_lut[233] = 16'sd31613;
    sigmoid_lut[234] = 16'sd31647;
    sigmoid_lut[235] = 16'sd31681;
    sigmoid_lut[236] = 16'sd31713;
    sigmoid_lut[237] = 16'sd31745;
    sigmoid_lut[238] = 16'sd31775;
    sigmoid_lut[239] = 16'sd31805;
    sigmoid_lut[240] = 16'sd31834;
    sigmoid_lut[241] = 16'sd31862;
    sigmoid_lut[242] = 16'sd31889;
    sigmoid_lut[243] = 16'sd31916;
    sigmoid_lut[244] = 16'sd31941;
    sigmoid_lut[245] = 16'sd31966;
    sigmoid_lut[246] = 16'sd31990;
    sigmoid_lut[247] = 16'sd32014;
    sigmoid_lut[248] = 16'sd32037;
    sigmoid_lut[249] = 16'sd32059;
    sigmoid_lut[250] = 16'sd32080;
    sigmoid_lut[251] = 16'sd32101;
    sigmoid_lut[252] = 16'sd32121;
    sigmoid_lut[253] = 16'sd32141;
    sigmoid_lut[254] = 16'sd32160;
    sigmoid_lut[255] = 16'sd32178;
    
end

// States for the FSM
localparam DESERIAL_INPUT = 0, DESERIAL_WEIGHTS = 0, DESERIAL_BIASES = 0, CONV = 0, SIGMOID = 0, FINISH = 0;
reg [2:0] state = DESERIAL_INPUT;

// Array types
reg signed [3:0] biases [0:9];
reg signed [3:0] weights [0:1599][0:9];
reg signed [11:0] image [0:1599];
reg signed [63:0] outputs [0:9];

integer i, j, x, y;
reg signed [3:0] temp_coeff;
reg signed [63:0] sumvar;
reg signed [15:0] ixk;
reg ok = 1'b0;

always @(posedge clk) begin
    if (start == 1'b1) begin
        case (state)
            DESERIAL_INPUT: begin
                image[i] <= $signed($int(img[(i * 12) + 11 -: 12]));
                i = i + 1;
                if (i == 1600) begin
                    state = DESERIAL_WEIGHTS;
                    i = 0;
                end
            end

            DESERIAL_WEIGHTS: begin
                temp_coeff = $signed(coef[(y * 4) + 3 -: 4]);
                weights[j][x] = temp_coeff;
                y = y + 1;
                if (x == 9) begin
                    x = 0;
                    if (j == 1599) begin
                        j = 0;
                        state = DESERIAL_BIASES;
                    end else begin
                        j = j + 1;
                    end
                end else begin
                    x = x + 1;
                end
            end

            DESERIAL_BIASES: begin
                biases[i] = $signed($int(bias[(i * 4) + 3 -: 4]));
                i = i + 1;
                if (i == 10) begin
                    i = 0;
                    state = CONV;
                    sumvar = {biases[x], 60'd0};
                end
            end

            CONV: begin
                ixk = image[j] * weights[j][x];
                sumvar = sumvar + ixk;
                j = j + 1;
                if (j == 1600) begin
                    outputs[x] = {sigmoid(sumvar), 48'd0};
                    j = 0;
                    x = x + 1;
                    if (x == 10) begin
                        x = 0;
                        state = FINISH;
                    end
                    sumvar = {biases[x], 60'd0};
                end
            end

            FINISH: begin
                done = 1'b1;
            end
        endcase
    end
end

// Sigmoid function using a lookup table
function signed [15:0] sigmoid;
    input signed [63:0] x;
    begin
        sigmoid = sigmoid_lut[x[63:56]];
    end
endfunction

endmodule
