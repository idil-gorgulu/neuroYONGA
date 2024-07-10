module uart_rx #(
    parameter integer c_clkfreq = 100_000_000,
    parameter integer c_baudrate = 115_200
)(
    input  wire           clk,
    input  wire           rx_i,
    output reg [3:0]      dout_o,
    output reg            rx_done_tick_o
);

    localparam integer c_bittimerlim = c_clkfreq / c_baudrate;
    localparam [1:0]
        S_IDLE  = 2'b00,
        S_START = 2'b01,
        S_DATA  = 2'b10,
        S_STOP  = 2'b11;

    reg [1:0]            state = S_IDLE;
    reg [15:0]           bittimer = 0;
    reg [1:0]            bitcntr = 0;
    reg [3:0]            shreg = 4'b0000;

    always @(posedge clk) begin
        case (state)
            S_IDLE: begin
                rx_done_tick_o <= 1'b0;
                bittimer <= 0;
                if (rx_i == 1'b0) begin
                    state <= S_START;
                end
            end
            
            S_START: begin
                if (bittimer == c_bittimerlim / 2 - 1) begin
                    state <= S_DATA;
                    bittimer <= 0;
                end else begin
                    bittimer <= bittimer + 1;
                end
            end
            
            S_DATA: begin
                if (bittimer == c_bittimerlim - 1) begin
                    if (bitcntr == 3) begin
                        state <= S_STOP;
                        bitcntr <= 0;
                    end else begin
                        bitcntr <= bitcntr + 1;
                    end
                    shreg <= {rx_i, shreg[3:1]};
                    bittimer <= 0;
                end else begin
                    bittimer <= bittimer + 1;
                end
            end
            
            S_STOP: begin
                if (bittimer == c_bittimerlim - 1) begin
                    state <= S_IDLE;
                    bittimer <= 0;
                    rx_done_tick_o <= 1'b1;
                end else begin
                    bittimer <= bittimer + 1;
                end
            end
            
            default: state <= S_IDLE;
        endcase
    end

    always @(posedge clk) begin
        dout_o <= shreg;
    end

endmodule
