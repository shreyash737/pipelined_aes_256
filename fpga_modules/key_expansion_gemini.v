module key_expansion(
    input [255:0] key_in,
    input clk,
    input reset_n,
    output reg [1919:0] expanded_key_out,
    output reg ready
);
    // Internal word storage (60 words for AES-256)
    reg [31:0] w [0:59];
    integer count;

    // --- 1. S-BOX HARDWARE INSTANTIATION ---
    // We instantiate 4 S-boxes to process one 32-bit word at a time.
    wire [31:0] sbox_in_word;
    wire [31:0] sbox_out_word;

    genvar j;
    generate
        for (j = 0; j < 4; j = j + 1) begin : sbox_array
            s_box sbox_inst (
                .in(sbox_in_word[j*8 +: 8]), 
                .out(sbox_out_word[j*8 +: 8])
            );
        end
    endgenerate

    // --- 2. INPUT MULTIPLEXER (AES-256 Logic) ---
    // Prepares the word for the S-Boxes based on the current cycle.
    // Indexing count-1 because we process the previous word to get the next one.
    assign sbox_in_word = (count % 8 == 0) ? {w[count-1][23:0], w[count-1][31:24]} : // RotWord
                          (count % 8 == 4) ? w[count-1]                           : // SubWord only
                          32'h0;

    // --- 3. SEQUENTIAL STATE MACHINE ---
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            count <= 0;
            ready <= 0;
            expanded_key_out <= 0;
        end else begin
            if (count < 8) begin
                // Load original 256-bit key (8 words)
                w[count] <= key_in[255 - (count*32) -: 32];
                count <= count + 1;
            end 
            else if (count < 60) begin
                // AES-256 Expansion Math
                if (count % 8 == 0)
                    // XOR with S-Box result AND Rcon
                    w[count] <= w[count-8] ^ sbox_out_word ^ {get_rcon(count/8), 24'h0};
                else if (count % 8 == 4)
                    // XOR with S-Box result ONLY
                    w[count] <= w[count-8] ^ sbox_out_word;
                else
                    // Standard XOR with previous word
                    w[count] <= w[count-8] ^ w[count-1];
                
                count <= count + 1;
            end
            else begin
                // All 60 words generated
                ready <= 1;
                // Pack the array into the flat output bus for the Top Module
                integer k;
                for (k = 0; k < 60; k = k + 1) begin
                    expanded_key_out[k*32 +: 32] <= w[k];
                end
            end
        end
    end

    // Rcon function for round constants
    function [7:0] get_rcon(input [3:0] round_idx);
        case(round_idx)
            4'd1:  get_rcon = 8'h01; 4'd2:  get_rcon = 8'h02;
            4'd3:  get_rcon = 8'h04; 4'd4:  get_rcon = 8'h08;
            4'd5:  get_rcon = 8'h10; 4'd6:  get_rcon = 8'h20;
            4'd7:  get_rcon = 8'h40; 4'd8:  get_rcon = 8'h80;
            4'd9:  get_rcon = 8'h1b; 4'd10: get_rcon = 8'h36;
            default: get_rcon = 8'h00;
        endcase
    endfunction

endmodule