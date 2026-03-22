module top_module (
    input clk,
    input rst_n,
    input [127:0] plain_text ,
    input [31:0] key [0:7],
    output [127:0] cipher_text 
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


    //zeroth round
     wire [7:0] r_key [0:15];

     assign r_key[0] = expanded_key[0] [31:24];
     assign r_key[1] = expanded_key[0] [23:16];
     assign r_key[2] = expanded_key[0] [15:8];
     assign r_key[3] = expanded_key[0] [7:0];


     assign r_key[4] = expanded_key[1] [31:24];
     assign r_key[5] = expanded_key[1] [23:16];
     assign r_key[6] = expanded_key[1] [15:8];
     assign r_key[7] = expanded_key[1] [7:0];

     assign r_key[8] = expanded_key[2] [31:24];
     assign r_key[9] = expanded_key[2] [23:16];
     assign r_key[10] = expanded_key[2] [15:8];
     assign r_key[11] = expanded_key[2] [7:0];


     assign r_key[12] = expanded_key[3] [31:24];
     assign r_key[13] = expanded_key[3] [23:16];
     assign r_key[14] = expanded_key[3] [15:8];
     assign r_key[15] = expanded_key[3] [7:0];

     
     wire [7:0] zero_out [0:15];
     add_round_key adrinstance( .in(plain_text), .key(r_key) , .out(zero_out) );

    
     always @(posedge clk or negedge rst_n ) begin
        if(!rst_n) begin 
            integer j;
            for(j=0;j<16;j++) begin
                state[0][j] <=8'h00;

            end
        end else begin
            state[0] <= zero_out;
        end
        
     end

     ///reamaining rounds rounds 1 to 13
    genvar i ;
    generate
    for (i=1;i<14;i=i+1) begin
    wire [7:0] stage_out[15:0];

    /// key conversion 

    wire [7:0] round_key [0:15];

    assign round_key[0]  = expanded_key[i*4]   [31:24];
    assign round_key[1]  = expanded_key[i*4]   [23:16];
    assign round_key[2]  = expanded_key[i*4]   [15:8];
    assign round_key[3]  = expanded_key[i*4]   [7:0];

    assign round_key[4]  = expanded_key[i*4+1] [31:24];
    assign round_key[5]  = expanded_key[i*4+1] [23:16];
    assign round_key[6]  = expanded_key[i*4+1] [15:8];
    assign round_key[7]  = expanded_key[i*4+1] [7:0];

    assign round_key[8]  = expanded_key[i*4+2] [31:24];
    assign round_key[9]  = expanded_key[i*4+2] [23:16];
    assign round_key[10] = expanded_key[i*4+2] [15:8];
    assign round_key[11] = expanded_key[i*4+2] [7:0];

    assign round_key[12] = expanded_key[i*4+3] [31:24];
    assign round_key[13] = expanded_key[i*4+3] [23:16];
    assign round_key[14] = expanded_key[i*4+3] [15:8];
    assign round_key[15] = expanded_key[i*4+3] [7:0];




    wire [7:0] state_in [0:15];
    genvar j;
    for (j=0; j<16; j=j+1) begin
        assign state_in[j] = state[i-1][j];
    end

    aes_round aes_instance(
         .in(state_in),
         .key(round_key),
         .out(stage_out)
     );


    always @(posedge clk or negedge rst_n) begin
          if(!rst_n) begin
            integer k;
            for(k=0;k<16;k++) begin
                state[i][k] <= 8'h00;
            end
                
         end else begin
                 integer h;
                 for(h=0; h<16 ; h=h+1) begin
                    state[i][h] = stage_out[h];
                 end
        end

    end
   
    end


    
    endgenerate

    ///last round 
    ///key for it 
    wire [7:0] last_round_key [0:15];

    assign last_round_key[0]  = expanded_key[56]   [31:24];
    assign last_round_key[1]  = expanded_key[56]   [23:16];
    assign last_round_key[2]  = expanded_key[56]   [15:8];
    assign last_round_key[3]  = expanded_key[56]   [7:0];

    assign last_round_key[4]  = expanded_key[57] [31:24];
    assign last_round_key[5]  = expanded_key[57] [23:16];
    assign last_round_key[6]  = expanded_key[57] [15:8];
    assign last_round_key[7]  = expanded_key[57] [7:0];

    assign last_round_key[8]  = expanded_key[58] [31:24];
    assign last_round_key[9]  = expanded_key[58] [23:16];
    assign last_round_key[10] = expanded_key[58] [15:8];
    assign last_round_key[11] = expanded_key[58] [7:0];

    assign last_round_key[12] = expanded_key[59] [31:24];
    assign last_round_key[13] = expanded_key[59] [23:16];
    assign last_round_key[14] = expanded_key[59] [15:8];
    assign last_round_key[15] = expanded_key[59] [7:0];


    wire [7:0] sb_out [15:0];
    wire [7:0] sr_out [15:0];
    wire [7:0] ark_out [15:0];

    sub_bytes sub_bytes_instance(.in(state[13]) , .out(sb_out));
    shift_rows shift_rows_instance(.in(sb_out) , .out(sr_out));
    add_round_key add_round_key_instance(.in(sr_out) ,.key(last_round_key), .out(ark_out));

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            integer e;
            for(e=0;e<16;e++) begin
                cipher_text[e] <= 8'h00;
            end
        end else begin
            cipher_text <=ark_out;
        end
    end
    
endmodule