`timescale 1ns / 1ps

module tb_top;

    // Parameters
    parameter INPUT_FILE_NAME = "C:\\Users\\ismet\\Masaüstü\\1.txt";
    parameter WEIGHT_FILE_NAME = "C:\\Users\\ismet\\Masaüstü\\weights.txt";
    parameter BIAS_FILE_NAME = "C:\\Users\\ismet\\Masaüstü\\biases.txt";

    // Internal signals
    reg clk = 0;
    reg rx = 0;
    reg [3135:0] img;
    reg [138879:0] coef;
    reg done;
    reg p1 = 1;
    reg p2 = 0;
    reg p3 = 0;
    reg p4 = 0;
    reg [423:0] bias;
    localparam c_baud115200 = 8680; // 8.68 us in ns
    localparam clock_period = 10;

    // Instantiate the Unit Under Test (UUT)
    uart_reader UUT (
        .clk(clk),
        .rx_i(rx),
        .coef(coef),
        .bias(bias),
        .img(img),
        .rx_done_tick_o(done)
    );

    // Clock generation
    always begin
        # (clock_period / 2) clk = ~clk;
    end

    // Main testbench process
    
        integer weight_file;
        integer input_file;
        integer bias_file;
        integer i;
        reg [7:0] img_char;
        reg [7:0] weight_char;
        reg [7:0] bias_char;
        reg [3135:0] img_str;
        reg [138879:0] weight_str;
        reg [423:0] bias_str;
    initial begin    
        // Open files
        weight_file = $fopen(WEIGHT_FILE_NAME, "r");
        input_file = $fopen(INPUT_FILE_NAME, "r");
        bias_file = $fopen(BIAS_FILE_NAME, "r");

        // Read and process input image data
        if (p1 == 1) begin
            if (!$feof(input_file)) begin
                for (i = 0; i < 3136; i = i + 1) begin
                    $fscanf(input_file, "%c", img_char);
                    img_str[i] = img_char;
                end
            end
            rx = 0;
            # c_baud115200;
            for (i = 0; i < 3136; i = i + 1) begin
                rx = (img_str[i] == "1") ? 1 : 0;
                # c_baud115200;
            end
            rx = 1;
            # (10 * c_baud115200);
            p1 = 0;
            p2 = 1;
        end

        // Read and process weight data
        if (p2 == 1) begin
            if (!$feof(weight_file)) begin
                for (i = 0; i < 138880; i = i + 1) begin
                    $fscanf(weight_file, "%c", weight_char);
                    weight_str[i] = weight_char;
                end
            end
            rx = 0;
            # c_baud115200;
            for (i = 0; i < 138880; i = i + 1) begin
                rx = (weight_str[i] == "1") ? 1 : 0;
                # c_baud115200;
            end
            rx = 1;
            # (10 * c_baud115200);
            p2 = 0;
            p3 = 1;
        end

        // Read and process bias data
        if (p3 == 1) begin
            if (!$feof(bias_file)) begin
                for (i = 0; i < 424; i = i + 1) begin
                    $fscanf(bias_file, "%c", bias_char);
                    bias_str[i] = bias_char;
                end
            end
            rx = 0;
            # c_baud115200;
            for (i = 0; i < 424; i = i + 1) begin
                rx = (bias_str[i] == "1") ? 1 : 0;
                # c_baud115200;
            end
            rx = 1;
            # (10 * c_baud115200);
            p3 = 0;
            p4 = 1;
        end

        // Wait for the done signal
        wait (done == 1 && p4 == 1);
        p4 = 0;
    end

endmodule
