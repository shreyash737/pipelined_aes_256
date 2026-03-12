`timescale 1ns / 1ps

module add_round_key_tb;
    reg [7:0] tb_in [15:0];
    reg [7:0] tb_key [15:0];
    wire [7:0] tb_out [15:0];

    add_round_key uut (
        .in(tb_in),
        .key(tb_key),
        .out(tb_out)
    );

    initial begin
        $dumpfile("add_round_key_waves.vcd");
        $dumpvars(0, add_round_key_tb);

        // Test: AA ^ FF = 55
        for (int i = 0; i < 16; i++) begin
            tb_in[i] = 8'hAA;
            tb_key[i] = 8'hFF;
        end

        #10;
        $display("Input: %h ^ Key: %h -> Output: %h", tb_in[0], tb_key[0], tb_out[0]);
        
        #10;
        $finish;
    end
endmodule