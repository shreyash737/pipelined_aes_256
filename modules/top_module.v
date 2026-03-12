module top_module (
    input clk,
    input rst_n,
    input [7:0] plain_text [15:0],
    input [31:0] key [0:7],
    output reg [7:0] cipher_text [15:0],
);
    // Instantiate the key expansion module
    wire [31:0] expanded_key [0:59];
    key_expansion key_expansion_inst (
        .key(key),
        .expanded_key(expanded_key)
    );

    //registers 
    reg [7:0] state [0:14][15:0] ;

    // AES rounds

    genvar i = 1;

    generate

        //zeroth round
        

        
    endgenerate



endmodule