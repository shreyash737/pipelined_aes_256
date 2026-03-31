`timescale 1ns / 1ps

module top_module_tb();

    // 1. Inputs to the Top Module (Regs in TB)
    reg clk;
    reg reset_n;
    reg arduino_rx_pin;
    reg [255:0] key;

    // 2. Outputs from the Top Module (Wires in TB)
    wire uart_physical_pin;

    // 3. Instantiate the Unit Under Test (UUT)
    top_module uut (
        .clk(clk),
        .reset_n(reset_n),
        .arduino_rx_pin(arduino_rx_pin),
        .key(key),
        .uart_physical_pin(uart_physical_pin)
    );

    // 4. Clock Generation (100MHz = 10ns period)
    always #5 clk = ~clk;

    // 5. Task to simulate one UART Byte being sent from Arduino
    // This mimics the 115200 baud timing
    task send_uart_byte;
        input [7:0] data;
        integer i;
        begin
            arduino_rx_pin = 0; // Start Bit
            #(868 * 10);        // Wait for 1 Baud period (868 ticks * 10ns)
            
            for (i = 0; i < 8; i = i + 1) begin
                arduino_rx_pin = data[i]; // Data Bits (LSB first)
                #(868 * 10);
            end
            
            arduino_rx_pin = 1; // Stop Bit
            #(868 * 10);
        end
    endtask

    // 6. The Actual Test Procedure
    initial begin
        // Initialize Inputs
        clk = 0;
        reset_n = 0;
        arduino_rx_pin = 1; // UART Idle is High
        key = 256'h000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f;

        // Reset the system
        #100;
        reset_n = 1;
        #100;

        // Wait for Key Expansion to finish (simulation time)
        #2000;

        // Simulate sending 16 bytes of "Heart Rate Data" from Arduino
        // Let's send 0x01, 0x02, ... 0x10
        send_uart_byte(8'h01);
        send_uart_byte(8'h02);
        send_uart_byte(8'h03);
        send_uart_byte(8'h04);
        send_uart_byte(8'h05);
        send_uart_byte(8'h06);
        send_uart_byte(8'h07);
        send_uart_byte(8'h08);
        send_uart_byte(8'h09);
        send_uart_byte(8'h0A);
        send_uart_byte(8'h0B);
        send_uart_byte(8'h0C);
        send_uart_byte(8'h0D);
        send_uart_byte(8'h0E);
        send_uart_byte(8'h0F);
        send_uart_byte(8'h10);

        // Wait to see the AES pipeline trigger and UART TX start
        #500000; 
        
        $display("Simulation Finished");
        $stop;
    end

endmodule