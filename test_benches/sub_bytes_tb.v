`timescale 1ns / 1ps

module sub_bytes_tb;

    // Inputs to the module
    reg [7:0] tb_in [15:0];
    // Outputs from the module
    wire [7:0] tb_out [15:0];

    // Instantiate the Unit Under Test (UUT)
    sub_bytes uut (
        .in(tb_in),
        .out(tb_out)
    );

    initial begin
        // 1. Setup VCD file for Surfer
        $dumpfile("sub_bytes_waves.vcd");
        $dumpvars(0, sub_bytes_tb);

        // 2. Apply Test Vector
        // Let's test byte 0 with 8'h00 (should result in 8'h63)
        // Let's test byte 1 with 8'h01 (should result in 8'h7c)
        tb_in[0] = 8'h00; 
        tb_in[1] = 8'h01;
        tb_in[2] = 8'h02;
        // Initialize the rest to zero
        for (int i = 3; i < 16; i++) tb_in[i] = 8'h00;

        #10; // Wait 10 nanoseconds

        // 3. Display results in terminal
        $display("Input [0]: %h -> Output [0]: %h (Expected: 63)", tb_in[0], tb_out[0]);
        $display("Input [1]: %h -> Output [1]: %h (Expected: 7c)", tb_in[1], tb_out[1]);

        #10;
        $finish; // End simulation
    end

endmodule