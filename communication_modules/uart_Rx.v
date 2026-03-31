module uart_rx (
    input clk,            // 100MHz
    input rst_n,          // Reset
    input rx,             // Physical RX pin (Connect to Arduino TX)
    output reg [7:0] data_out, // The byte received
    output reg rx_done    // High for 1 cycle when byte is ready
);

    // 100MHz / 115200 Baud = 868 ticks
    parameter CLK_TICKS = 868;
    parameter HALF_TICKS = 434; // To sample in the middle of the bit

    localparam IDLE  = 2'b00;
    localparam START = 2'b01;
    localparam DATA  = 2'b10;
    localparam STOP  = 2'b11;

    reg [1:0]  state = IDLE;
    reg [15:0] count = 0;
    reg [2:0]  bit_index = 0;
    reg [7:0]  rx_buffer = 0;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            rx_done <= 0;
            count <= 0;
        end else begin
            rx_done <= 0; // Default pulse low

            case (state)
                IDLE: begin
                    if (rx == 1'b0) begin // Start bit detected
                        if (count < HALF_TICKS) begin
                            count <= count + 1;
                        end else begin
                            count <= 0;
                            state <= START;
                        end
                    end else begin
                        count <= 0;
                    end
                end

                START: begin
                    if (count < CLK_TICKS - 1) begin
                        count <= count + 1;
                    end else begin
                        count <= 0;
                        state <= DATA;
                        bit_index <= 0;
                    end
                end

                DATA: begin
                    if (count < CLK_TICKS - 1) begin
                        count <= count + 1;
                    end else begin
                        count <= 0;
                        rx_buffer[bit_index] <= rx; // Sample the bit
                        if (bit_index < 7) begin
                            bit_index <= bit_index + 1;
                        end else begin
                            state <= STOP;
                        end
                    end
                end

                STOP: begin
                    if (count < CLK_TICKS - 1) begin
                        count <= count + 1;
                    end else begin
                        count <= 0;
                        data_out <= rx_buffer;
                        rx_done  <= 1'b1; // Trigger "Done" for 1 cycle
                        state    <= IDLE;
                    end
                end
            endcase
        end
    end
endmodule