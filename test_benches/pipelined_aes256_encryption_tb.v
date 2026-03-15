`timescale 1ns / 1ps

module tb_top;
    // Signals
    reg clk;
    reg rst_n;
    reg [7:0] tb_plain_text [15:0];
    reg [31:0] tb_key [0:7];
    wire [7:0] tb_cipher_text [15:0];

    // Instantiate Top Module
    top_module uut (
        .clk(clk),
        .rst_n(rst_n),
        .plain_text(tb_plain_text),
        .key(tb_key),
        .cipher_text(tb_cipher_text)
    );

    // Clock Generation (100MHz)
    always #5 clk = ~clk;

    integer i;

    initial begin
        // Initialize
        clk = 0;
        rst_n = 0;
        
        // Load Test Key (256-bit)
        tb_key[0] = 32'h00010203; tb_key[1] = 32'h04050607;
        tb_key[2] = 32'h08090a0b; tb_key[3] = 32'h0c0d0e0f;
        tb_key[4] = 32'h10111213; tb_key[5] = 32'h14151617;
        tb_key[6] = 32'h18191a1b; tb_key[7] = 32'h1c1d1e1f;

        // Load Test Plaintext
        {tb_plain_text[0],  tb_plain_text[1],  tb_plain_text[2],  tb_plain_text[3]}  = 32'h00112233;
        {tb_plain_text[4],  tb_plain_text[5],  tb_plain_text[6],  tb_plain_text[7]}  = 32'h44556677;
        {tb_plain_text[8],  tb_plain_text[9],  tb_plain_text[10], tb_plain_text[11]} = 32'h8899aabb;
        {tb_plain_text[12], tb_plain_text[13], tb_plain_text[14], tb_plain_text[15]} = 32'hccddeeff;

        // Reset Pulse
        #20 rst_n = 1;

        // Wait for Pipeline Latency (15 Cycles)
        repeat (16) @(posedge clk);

        // Display Results
        $display("--- AES-256 Pipeline Result ---");
        $write("Ciphertext: ");
        for (i = 0; i < 16; i = i + 1) begin
            $write("%h ", tb_cipher_text[i]);
        end
        $display("\nExpected:   8e a2 b7 ca 51 67 45 bf ea fc 49 90 4b 49 60 89");
        
        #20;
        $finish;
    end

    // Waveform Dump
    initial begin
        $dumpfile("aes_pipeline.vcd");
        $dumpvars(0, tb_top);
    end

endmodule