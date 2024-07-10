module uart_reader (
    input  wire           clk,
    input  wire           rx_i,
    output reg [138879:0] coef,
    output reg [423:0]    bias,
    output reg [3135:0]   img,
    output wire           rx_done_tick_o
);

    wire [3:0]            uart_dout;
    wire                  uart_done;
    reg [15:0]           bit_counter = 0;
    reg [138879:0]       data_buffer  = {138880{1'b0}};
    reg [423:0]          data_buffer1 = {424{1'b0}};
    reg [3135:0]         data_buffer2 = {3136{1'b0}};
    reg                  reading_done = 1'b0;

    uart_rx uart_rx_inst (
        .clk(clk),
        .rx_i(rx_i),
        .dout_o(uart_dout),
        .rx_done_tick_o(uart_done)
    );
	
	top top_inst (
		.clock(clk),
		.start(reading_done),
		.coef(coef),
		.bias(bias),
		.img(img),
		.done(rx_done_tick_o)
    );

    always @(posedge clk) begin
        if (uart_done) begin
            if (bit_counter < 34720) begin
                data_buffer[bit_counter +: 4] <= uart_dout;
                bit_counter <= bit_counter + 4;
            end else if (bit_counter >= 34720 && bit_counter < 34826) begin
                data_buffer1[bit_counter - 34720 +: 4] <= uart_dout;
                bit_counter <= bit_counter + 4;
            end else if (bit_counter >= 34826 && bit_counter < 35610) begin
                data_buffer2[bit_counter - 34826 +: 4] <= uart_dout;
                bit_counter <= bit_counter + 4;
            end else begin
                reading_done <= 1'b1;
            end
        end
    end

    always @(posedge clk) begin
        coef <= data_buffer;
        bias <= data_buffer1;
        img  <= data_buffer2;
    end

endmodule

module uart_rx (
    input  wire           clk,
    input  wire           rx_i,
    output reg [3:0]      dout_o,
    output reg            rx_done_tick_o
);
    // UART receiver implementation
    parameter c_clkfreq = 100_000_000;
    parameter c_baudrate = 115_200;

    // UART receiver logic goes here

endmodule

module top (
    input  wire           clock,
    input  wire           start,
    input  wire [138879:0] coef,
    input  wire [423:0]   bias,
    input  wire [3135:0]  img,
    output reg            done
);
    // Top module implementation

endmodule
