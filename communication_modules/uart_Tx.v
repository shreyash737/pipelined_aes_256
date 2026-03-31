module uart_tx (
    input clk,           // 100MHz from Basys 3
    input rst_n,         // Active low reset
    input [7:0] data_in, // The byte to send (e.g., 8'h41 for 'A')
    input start_tx,      // Pulse high to start transmission
    output reg tx,       // Connect to Pin A18 in XDC
    output reg busy      // High when sending, Low when ready
);

    // 1. Baud Rate Timing
    // 100MHz / 115200 Baud = 868.05
    parameter CLK_TICKS = 868;

    // 2. State Machine Definitions
    localparam IDLE  = 2'b00;
    localparam START = 2'b01;
    localparam DATA  = 2'b10;
    localparam STOP  = 2'b11;

    reg [1:0]  state      = IDLE;
    reg [15:0] baud_count = 0;
    reg [2:0]  bit_index  = 0; // Tracks which of the 8 bits we are sending
    reg [7:0]  tx_data    = 0; // Local buffer for data_in

    // 3. The Transmitter Logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state      <= IDLE;
            tx         <= 1'b1; // UART line is high when idle
            busy       <= 1'b0;
            baud_count <= 0;
        end else begin
            case (state)
                IDLE: begin
                    tx   <= 1'b1; // Keep line high
                    busy <= 1'b0;
                    baud_count <= 0;
                    if (start_tx) begin
                        tx_data <= data_in; // "Freeze" the input data
                        state   <= START;
                        busy    <= 1'b1;
                    end
                end

                START: begin
                    tx <= 1'b0; // Start Bit is always 0
                    if (baud_count < CLK_TICKS - 1) begin
                        baud_count <= baud_count + 1;
                    end else begin
                        baud_count <= 0;
                        state      <= DATA;
                        bit_index  <= 0;
                    end
                end

                DATA: begin
                    tx <= tx_data[bit_index]; // Send bits LSB first
                    if (baud_count < CLK_TICKS - 1) begin
                        baud_count <= baud_count + 1;
                    end else begin
                        baud_count <= 0;
                        if (bit_index < 7) begin
                            bit_index <= bit_index + 1;
                        end else begin
                            state <= STOP;
                        end
                    end
                end

                STOP: begin
                    tx <= 1'b1; // Stop Bit is always 1
                    if (baud_count < CLK_TICKS - 1) begin
                        baud_count <= baud_count + 1;
                    end else begin
                        baud_count <= 0;
                        state      <= IDLE;
                        busy       <= 1'b0;
                    end
                end
            endcase
        end
    end
endmodule