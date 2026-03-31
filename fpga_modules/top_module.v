module top_module (
    input clk,
    input reset_n,
    input [127:0] plain_text ,
    input [255:0] key ,
    output reg [127:0] cipher_text 
);
    // Instantiate the key expansion module
    
    reg  [1919:0] expanded_key_flat;
    reg key_ready;
    key_expansion key_expansion_inst (
        .key(key),
        .clk(clk),
        .expanded_key(expanded_key_flat),
        .ready(key_ready)
        .reset_n(reset_n)
    );

    wire [31:0] expanded_key [0:59];
    genvar k;
    generate
        for (k = 0; k < 60; k = k + 1) begin : unpack_key
            assign expanded_key[k] = expanded_key_flat[k*32 +: 32];
        end
    endgenerate

    reg [127:0] state_pipe [0:14];
    wire [127:0] aes_in;
    wire [127:0] key_in;
    wire [127:0] aes_out;

    integer round = 0;

    assign key_in = {{expanded_key[round+3]},{expanded_key[round+2]},{expanded_key[round+1]},{expanded_key[round]}}

    assign aes_in = state_pipe[round]

    /// aes round insatniate 
    aes_round instance1(.in(aes_in),.key(key_in),.out(aes_out));

    ///for the final round 

    wire [127:0] sb_out ;
    wire [127:0] sr_out ;
    wire [127:0] ark_out ;
    wire [127:0] aes_in_last ;

    assign aes_in_last = state_pipe[14]

    sub_bytes instance1(.in(aes_in_last) , .out(sb_out));
    shift_rows instance2(.in(sb_out) , .out(sr_out));
    add_round_key instance4(.in(sr_out) , .key(key) , .out(ark_out));
    
    
    

    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            key_ready <= 0;
            cipher_text <= 0;
            integer k;
            for(k=0;k<15;k++) begin
                state_pipe[i] <= 0;
            end

        end else if(key_ready) begin
            if(round == 0)begin
                //round 0
                state_pipe[round+1] <= aes_in ^ key_in;
                round = round+1;
            end else if(round <14) begin
                state_pipe[round+1] <= aes_out
                round <= round+1;
            end else begin
                //last round 
                cipher_text <= ark_out;

                

            end
        end
    end

endmodule

module aes_round(
    input [127:0] in,
    input [127:0] key,
    output [127:0] out 
     );

    wire [127:0] sb_out ;
    wire [127:0] sr_out ;
    wire [127:0] mc_out ;
    wire [127:0] ark_out ;

    sub_bytes instance1(.in(in) , .out(sb_out));
    shift_rows instance2(.in(sb_out) , .out(sr_out));
    mix_columns instance3(.in(sr_out) , .out(mc_out));
    add_round_key instance4(.in(mc_out) , .key(key) , .out(ark_out));
    assign out = ark_out;

endmodule