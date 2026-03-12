`timescale 1ns / 1ps

module shift_rows_tb;
    reg [7:0] tb_in [15:0];
    wire [7:0] tb_out [15:0];

    shift_rows uut (
        .a(tb_in),
        .out(tb_out)
    );

    initial begin
        $dumpfile("shift_rows_waves.vcd");
        $dumpvars(0, shift_rows_tb);

        // Fill input with 00, 01, 02 ... 0F to easily track movement
        for (int i = 0; i < 16; i++) tb_in[i] = i;

        #10;

        // In AES ShiftRows:
        // Row 0 (0,4,8,12) stays: 00, 04, 08, 0c
        // Row 1 (1,5,9,13) shifts 1: 05, 09, 0d, 01
        $display("Input[1]=%h, Input[5]=%h -> Output[1]=%h, Output[13]=%h", 
                  tb_in[1], tb_in[5], tb_out[1], tb_out[13]);
        
        #10;
        $finish;
    end
endmodule