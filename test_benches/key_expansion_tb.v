`timescale 1ns / 1ps

module key_expansion_tb;
    reg [31:0] tb_in [0:7];
    wire [31:0] tb_out [0:59];

    key_expansion uut (
        .in(tb_in),
        .out(tb_out)
    );

    initial begin
        $dumpfile("key_expansion_waves.vcd");
        $dumpvars(0, key_expansion_tb);

        // Test with an all-zero 256-bit key
        for (int i = 0; i < 8; i++) tb_in[i] = 32'h00000000;

        #10;

        // NIST "All Zeros" Key Expansion results:
        // W8 (first generated word) should be 01000000 ^ SubWord(RotWord(W7))
        // Since W7 is 0, Rot(0) is 0, SubWord(0) is 63636363
        // W8 = 00000000 ^ 63636363 ^ 01000000 = 62636363
        $display("Checking AES-256 Key Expansion (All Zeros Key):");
        $display("W[8]: %h (Expected: 62636363)", tb_out[8]);
        $display("W[9]: %h (Expected: 62636363)", tb_out[9]);

        #10;
        $finish;
    end
endmodule