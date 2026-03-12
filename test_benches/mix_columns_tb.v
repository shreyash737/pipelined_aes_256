`timescale 1ns / 1ps

module mix_columns_tb;
    reg [7:0] tb_in [15:0];
    wire [7:0] tb_out [15:0];

    mix_columns uut (
        .in(tb_in),
        .out(tb_out)
    );

    initial begin
        $dumpfile("mix_columns_waves.vcd");
        $dumpvars(0, mix_columns_tb);

        // Standard AES test vector for one column
        // Input:  02, 01, 01, 03 (represented as hex)
        // Expected Output: 0e, 0b, 0d, 09
        tb_in[0] = 8'h02; tb_in[1] = 8'h01; tb_in[2] = 8'h01; tb_in[3] = 8'h03;
        
        // Fill the rest with zeros for now
        for (int i = 4; i < 16; i++) tb_in[i] = 8'h00;

        #10;

        $display("Testing MixColumns Column 0:");
        $display("In: %h %h %h %h", tb_in[0], tb_in[1], tb_in[2], tb_in[3]);
        $display("Out: %h %h %h %h (Expected: 0e 0b 0d 09)", tb_out[0], tb_out[1], tb_out[2], tb_out[3]);

        #10;
        $finish;
    end
endmodule
