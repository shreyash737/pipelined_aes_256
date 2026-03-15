module top_module (
    input clk,
    input rst_n,
    input [7:0] plain_text [15:0],
    input [31:0] key [0:7],
    output reg [7:0] cipher_text [15:0]
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




    aes_round aes_instance(
        .in(state[i-1]),
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
                 state[i] <= stage_out ;
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

module aes_round(
    input [7:0] in [15:0],
    input [7:0] key [15:0],
    output [7:0] out [15:0]
     );

    wire [7:0] sb_out [15:0];
    wire [7:0] sr_out [15:0];
    wire [7:0] mc_out [15:0];
    wire [7:0] ark_out [15:0];

    sub_bytes instance1(.in(in) , .out(sb_out));
    shift_rows instance2(.in(sb_out) , .out(sr_out));
    mix_columns instance3(.in(sr_out) , .out(mc_out));
    add_round_key instance4(.in(mc_out) , .key(key) , .out(ark_out));
    assign out = ark_out;





endmodule


module add_round_key(input[7:0] in [15:0] ,input [7:0] key [15:0],output [7:0] out [15:0]);
    genvar i;
    generate
        for(i=0 ;i < 16 ;i++) begin
            assign out[i] = in[i]^key[i];
        end
    endgenerate
endmodule

module mix_columns(input [7:0]in [15:0] , output [7:0] out [15:0]);
    
    
    //creating function ofr xtime 
    function [7:0] xtime(input [7:0] in );
        begin 
            xtime = in[7] ? ({in[6:0],1'b0} ^ 8'h1b) : ({in[6:0],1'b0});
        end
    endfunction

  
    //function for 3xtime 
    
    function [7:0] xtime3(input [7:0] in );
        begin
            xtime3 = xtime(in) ^ in ; 
        end
    endfunction

    //using xtime for multyplying by 2 and 3xtime for 3

    genvar i;
    generate
        for (i=0;i<16; i = i+4) begin 
        assign out[i] = xtime(in[i]) ^ xtime3(in[i+1]) ^  in[i+2] ^  in[i+3] ;
        assign out[i+1] = in[i]^ xtime(in[i+1]) ^  xtime3(in[i+2]) ^  in[i+3] ;
        assign out[i+2] = in[i] ^ in[i+1] ^  xtime(in[i+2]) ^  xtime3(in[i+3]) ;
        assign out[i+3] = xtime3(in[i]) ^in[i+1] ^  in[i+2] ^  xtime(in[i+3]) ;
        end
        
    endgenerate
            /// i was gonnna wirte for each element but after wathing similarities i w=decided to use loop
    
        // out[i] = xtime[in[i]] ^ xtime[in[i+1]] ^  xtime[in[i+2]] ^  xtime[in[i+3]] ;
        // out[i+1] = xtime[in[i]] ^ xtime[in[i+1]] ^  xtime[in[i+2]] ^  xtime[in[i+3]] ;
        // out[i+2] = xtime[in[i]] ^ xtime[in[i+1]] ^  xtime[in[i+2]] ^  xtime[in[i+3]] ;
        // out[i+3] = xtime[in[i]] ^ xtime[in[i+1]] ^  xtime[in[i+2]] ^  xtime[in[i+3]] ;

  

endmodule

module shift_rows(input [7:0] in [15:0], output [7:0] out [15:0]);

    assign out[0] = in[0];
    assign out[4] = in[4];
    assign out[8] = in[8];
    assign out[12] = in[12];

    assign out[1] = in[5];
    assign out[5] = in[9];
    assign out[9] = in[13];
    assign out[13] = in[1];

    assign out[2] = in[10];
    assign out[6] = in[14];
    assign out[10] = in[2];
    assign out[14] = in[6];

    assign out[3] = in[15];
    assign out[7] = in[3];
    assign out[11] = in[7];
    assign out[15] = in[11];


endmodule

module sub_bytes(input [7:0] in [15:0] , output [7:0] out [15:0]);
    
     s_box instance1(in[0], out[0]);
     s_box instance2(in[1], out[1]);
     s_box instance3(in[2], out[2]);
     s_box instance4(in[3], out[3]);

     s_box instance5(in[4], out[4]);
     s_box instance6(in[5], out[5]);
     s_box instance7(in[6], out[6]);
     s_box instance8(in[7], out[7]);

     s_box instance9(in[8], out[8]);
     s_box instance10(in[9], out[9]);
     s_box instance11(in[10], out[10]);
     s_box instance12(in[11], out[11]);

     s_box instance13(in[12], out[12]);
     s_box instance14(in[13], out[13]);
     s_box instance15(in[14], out[14]);
     s_box instance16(in[15], out[15]);
         
   
endmodule

module s_box (
    input  wire [7:0] in,
    output reg [7:0] out
);

always @(*) begin
    case (in)
        8'h00: out = 8'h63; 8'h01: out = 8'h7c; 8'h02: out = 8'h77; 8'h03: out = 8'h7b;
        8'h04: out = 8'hf2; 8'h05: out = 8'h6b; 8'h06: out = 8'h6f; 8'h07: out = 8'hc5;
        8'h08: out = 8'h30; 8'h09: out = 8'h01; 8'h0a: out = 8'h67; 8'h0b: out = 8'h2b;
        8'h0c: out = 8'hfe; 8'h0d: out = 8'hd7; 8'h0e: out = 8'hab; 8'h0f: out = 8'h76;

        8'h10: out = 8'hca; 8'h11: out = 8'h82; 8'h12: out = 8'hc9; 8'h13: out = 8'h7d;
        8'h14: out = 8'hfa; 8'h15: out = 8'h59; 8'h16: out = 8'h47; 8'h17: out = 8'hf0;
        8'h18: out = 8'had; 8'h19: out = 8'hd4; 8'h1a: out = 8'ha2; 8'h1b: out = 8'haf;
        8'h1c: out = 8'h9c; 8'h1d: out = 8'ha4; 8'h1e: out = 8'h72; 8'h1f: out = 8'hc0;

        8'h20: out = 8'hb7; 8'h21: out = 8'hfd; 8'h22: out = 8'h93; 8'h23: out = 8'h26;
        8'h24: out = 8'h36; 8'h25: out = 8'h3f; 8'h26: out = 8'hf7; 8'h27: out = 8'hcc;
        8'h28: out = 8'h34; 8'h29: out = 8'ha5; 8'h2a: out = 8'he5; 8'h2b: out = 8'hf1;
        8'h2c: out = 8'h71; 8'h2d: out = 8'hd8; 8'h2e: out = 8'h31; 8'h2f: out = 8'h15;

        8'h30: out = 8'h04; 8'h31: out = 8'hc7; 8'h32: out = 8'h23; 8'h33: out = 8'hc3;
        8'h34: out = 8'h18; 8'h35: out = 8'h96; 8'h36: out = 8'h05; 8'h37: out = 8'h9a;
        8'h38: out = 8'h07; 8'h39: out = 8'h12; 8'h3a: out = 8'h80; 8'h3b: out = 8'he2;
        8'h3c: out = 8'heb; 8'h3d: out = 8'h27; 8'h3e: out = 8'hb2; 8'h3f: out = 8'h75;

        8'h40: out = 8'h09; 8'h41: out = 8'h83; 8'h42: out = 8'h2c; 8'h43: out = 8'h1a;
        8'h44: out = 8'h1b; 8'h45: out = 8'h6e; 8'h46: out = 8'h5a; 8'h47: out = 8'ha0;
        8'h48: out = 8'h52; 8'h49: out = 8'h3b; 8'h4a: out = 8'hd6; 8'h4b: out = 8'hb3;
        8'h4c: out = 8'h29; 8'h4d: out = 8'he3; 8'h4e: out = 8'h2f; 8'h4f: out = 8'h84;

        8'h50: out = 8'h53; 8'h51: out = 8'hd1; 8'h52: out = 8'h00; 8'h53: out = 8'hed;
        8'h54: out = 8'h20; 8'h55: out = 8'hfc; 8'h56: out = 8'hb1; 8'h57: out = 8'h5b;
        8'h58: out = 8'h6a; 8'h59: out = 8'hcb; 8'h5a: out = 8'hbe; 8'h5b: out = 8'h39;
        8'h5c: out = 8'h4a; 8'h5d: out = 8'h4c; 8'h5e: out = 8'h58; 8'h5f: out = 8'hcf;

        8'h60: out = 8'hd0; 8'h61: out = 8'hef; 8'h62: out = 8'haa; 8'h63: out = 8'hfb;
        8'h64: out = 8'h43; 8'h65: out = 8'h4d; 8'h66: out = 8'h33; 8'h67: out = 8'h85;
        8'h68: out = 8'h45; 8'h69: out = 8'hf9; 8'h6a: out = 8'h02; 8'h6b: out = 8'h7f;
        8'h6c: out = 8'h50; 8'h6d: out = 8'h3c; 8'h6e: out = 8'h9f; 8'h6f: out = 8'ha8;

        8'h70: out = 8'h51; 8'h71: out = 8'ha3; 8'h72: out = 8'h40; 8'h73: out = 8'h8f;
        8'h74: out = 8'h92; 8'h75: out = 8'h9d; 8'h76: out = 8'h38; 8'h77: out = 8'hf5;
        8'h78: out = 8'hbc; 8'h79: out = 8'hb6; 8'h7a: out = 8'hda; 8'h7b: out = 8'h21;
        8'h7c: out = 8'h10; 8'h7d: out = 8'hff; 8'h7e: out = 8'hf3; 8'h7f: out = 8'hd2;

        8'h80: out = 8'hcd; 8'h81: out = 8'h0c; 8'h82: out = 8'h13; 8'h83: out = 8'hec;
        8'h84: out = 8'h5f; 8'h85: out = 8'h97; 8'h86: out = 8'h44; 8'h87: out = 8'h17;
        8'h88: out = 8'hc4; 8'h89: out = 8'ha7; 8'h8a: out = 8'h7e; 8'h8b: out = 8'h3d;
        8'h8c: out = 8'h64; 8'h8d: out = 8'h5d; 8'h8e: out = 8'h19; 8'h8f: out = 8'h73;

        8'h90: out = 8'h60; 8'h91: out = 8'h81; 8'h92: out = 8'h4f; 8'h93: out = 8'hdc;
        8'h94: out = 8'h22; 8'h95: out = 8'h2a; 8'h96: out = 8'h90; 8'h97: out = 8'h88;
        8'h98: out = 8'h46; 8'h99: out = 8'hee; 8'h9a: out = 8'hb8; 8'h9b: out = 8'h14;
        8'h9c: out = 8'hde; 8'h9d: out = 8'h5e; 8'h9e: out = 8'h0b; 8'h9f: out = 8'hdb;

        8'ha0: out = 8'he0; 8'ha1: out = 8'h32; 8'ha2: out = 8'h3a; 8'ha3: out = 8'h0a;
        8'ha4: out = 8'h49; 8'ha5: out = 8'h06; 8'ha6: out = 8'h24; 8'ha7: out = 8'h5c;
        8'ha8: out = 8'hc2; 8'ha9: out = 8'hd3; 8'haa: out = 8'hac; 8'hab: out = 8'h62;
        8'hac: out = 8'h91; 8'had: out = 8'h95; 8'hae: out = 8'he4; 8'haf: out = 8'h79;

        8'hb0: out = 8'he7; 8'hb1: out = 8'hc8; 8'hb2: out = 8'h37; 8'hb3: out = 8'h6d;
        8'hb4: out = 8'h8d; 8'hb5: out = 8'hd5; 8'hb6: out = 8'h4e; 8'hb7: out = 8'ha9;
        8'hb8: out = 8'h6c; 8'hb9: out = 8'h56; 8'hba: out = 8'hf4; 8'hbb: out = 8'hea;
        8'hbc: out = 8'h65; 8'hbd: out = 8'h7a; 8'hbe: out = 8'hae; 8'hbf: out = 8'h08;

        8'hc0: out = 8'hba; 8'hc1: out = 8'h78; 8'hc2: out = 8'h25; 8'hc3: out = 8'h2e;
        8'hc4: out = 8'h1c; 8'hc5: out = 8'ha6; 8'hc6: out = 8'hb4; 8'hc7: out = 8'hc6;
        8'hc8: out = 8'he8; 8'hc9: out = 8'hdd; 8'hca: out = 8'h74; 8'hcb: out = 8'h1f;
        8'hcc: out = 8'h4b; 8'hcd: out = 8'hbd; 8'hce: out = 8'h8b; 8'hcf: out = 8'h8a;

        8'hd0: out = 8'h70; 8'hd1: out = 8'h3e; 8'hd2: out = 8'hb5; 8'hd3: out = 8'h66;
        8'hd4: out = 8'h48; 8'hd5: out = 8'h03; 8'hd6: out = 8'hf6; 8'hd7: out = 8'h0e;
        8'hd8: out = 8'h61; 8'hd9: out = 8'h35; 8'hda: out = 8'h57; 8'hdb: out = 8'hb9;
        8'hdc: out = 8'h86; 8'hdd: out = 8'hc1; 8'hde: out = 8'h1d; 8'hdf: out = 8'h9e;

        8'he0: out = 8'he1; 8'he1: out = 8'hf8; 8'he2: out = 8'h98; 8'he3: out = 8'h11;
        8'he4: out = 8'h69; 8'he5: out = 8'hd9; 8'he6: out = 8'h8e; 8'he7: out = 8'h94;
        8'he8: out = 8'h9b; 8'he9: out = 8'h1e; 8'hea: out = 8'h87; 8'heb: out = 8'he9;
        8'hec: out = 8'hce; 8'hed: out = 8'h55; 8'hee: out = 8'h28; 8'hef: out = 8'hdf;

        8'hf0: out = 8'h8c; 8'hf1: out = 8'ha1; 8'hf2: out = 8'h89; 8'hf3: out = 8'h0d;
        8'hf4: out = 8'hbf; 8'hf5: out = 8'he6; 8'hf6: out = 8'h42; 8'hf7: out = 8'h68;
        8'hf8: out = 8'h41; 8'hf9: out = 8'h99; 8'hfa: out = 8'h2d; 8'hfb: out = 8'h0f;
        8'hfc: out = 8'hb0; 8'hfd: out = 8'h54; 8'hfe: out = 8'hbb; 8'hff: out = 8'h16;

        default: out = 8'h00;
    endcase
end

endmodule





module key_expansion(input [31:0] key [0:7] , output reg [31:0] expanded_key [0:59]);
    function [7:0] get_rcon(input [3:0] round_idx); // Give 'i' a width (4 bits for 14 rounds)
    begin
        case(round_idx)
            4'd1:  get_rcon = 8'h01;
            4'd2:  get_rcon = 8'h02;
            4'd3:  get_rcon = 8'h04;
            4'd4:  get_rcon = 8'h08;
            4'd5:  get_rcon = 8'h10;
            4'd6:  get_rcon = 8'h20;
            4'd7:  get_rcon = 8'h40;
            4'd8:  get_rcon = 8'h80;
            4'd9:  get_rcon = 8'h1b; 
            4'd10: get_rcon = 8'h36;
            default: get_rcon = 8'h00; 
        endcase
    end
    endfunction

    function [31:0] rcon (input [31:0] in , input [7:0] rc);
    rcon = in ^ {rc,8'h00,8'h00,8'h00}; 
    endfunction

    function [31:0] rot_word (input [31:0] in );
     rot_word = {in[23:0],in[31:24]};
    endfunction

    function [31:0] sub_word (input [31:0] in);
    begin
     sub_word[7:0] = s_box(in[7:0]);
     sub_word[15:8] = s_box(in[15:8]);
     sub_word[23:16] = s_box(in[23:16]);
     sub_word[31:24] = s_box(in[31:24]);
    end
    endfunction


    function [7:0] s_box (input [7:0]in ) ;
    
    begin
        case (in)
        8'h00: s_box = 8'h63; 8'h01: s_box = 8'h7c; 8'h02: s_box = 8'h77; 8'h03: s_box = 8'h7b;
        8'h04: s_box = 8'hf2; 8'h05: s_box = 8'h6b; 8'h06: s_box = 8'h6f; 8'h07: s_box = 8'hc5;
        8'h08: s_box = 8'h30; 8'h09: s_box = 8'h01; 8'h0a: s_box = 8'h67; 8'h0b: s_box = 8'h2b;
        8'h0c: s_box = 8'hfe; 8'h0d: s_box = 8'hd7; 8'h0e: s_box = 8'hab; 8'h0f: s_box = 8'h76;

        8'h10: s_box = 8'hca; 8'h11: s_box = 8'h82; 8'h12: s_box = 8'hc9; 8'h13: s_box = 8'h7d;
        8'h14: s_box = 8'hfa; 8'h15: s_box = 8'h59; 8'h16: s_box = 8'h47; 8'h17: s_box = 8'hf0;
        8'h18: s_box = 8'had; 8'h19: s_box = 8'hd4; 8'h1a: s_box = 8'ha2; 8'h1b: s_box = 8'haf;
        8'h1c: s_box = 8'h9c; 8'h1d: s_box = 8'ha4; 8'h1e: s_box = 8'h72; 8'h1f: s_box = 8'hc0;

        8'h20: s_box = 8'hb7; 8'h21: s_box = 8'hfd; 8'h22: s_box = 8'h93; 8'h23: s_box = 8'h26;
        8'h24: s_box = 8'h36; 8'h25: s_box = 8'h3f; 8'h26: s_box = 8'hf7; 8'h27: s_box = 8'hcc;
        8'h28: s_box = 8'h34; 8'h29: s_box = 8'ha5; 8'h2a: s_box = 8'he5; 8'h2b: s_box = 8'hf1;
        8'h2c: s_box = 8'h71; 8'h2d: s_box = 8'hd8; 8'h2e: s_box = 8'h31; 8'h2f: s_box = 8'h15;

        8'h30: s_box = 8'h04; 8'h31: s_box = 8'hc7; 8'h32: s_box = 8'h23; 8'h33: s_box = 8'hc3;
        8'h34: s_box = 8'h18; 8'h35: s_box = 8'h96; 8'h36: s_box = 8'h05; 8'h37: s_box = 8'h9a;
        8'h38: s_box = 8'h07; 8'h39: s_box = 8'h12; 8'h3a: s_box = 8'h80; 8'h3b: s_box = 8'he2;
        8'h3c: s_box = 8'heb; 8'h3d: s_box = 8'h27; 8'h3e: s_box = 8'hb2; 8'h3f: s_box = 8'h75;

        8'h40: s_box = 8'h09; 8'h41: s_box = 8'h83; 8'h42: s_box = 8'h2c; 8'h43: s_box = 8'h1a;
        8'h44: s_box = 8'h1b; 8'h45: s_box = 8'h6e; 8'h46: s_box = 8'h5a; 8'h47: s_box = 8'ha0;
        8'h48: s_box = 8'h52; 8'h49: s_box = 8'h3b; 8'h4a: s_box = 8'hd6; 8'h4b: s_box = 8'hb3;
        8'h4c: s_box = 8'h29; 8'h4d: s_box = 8'he3; 8'h4e: s_box = 8'h2f; 8'h4f: s_box = 8'h84;

        8'h50: s_box = 8'h53; 8'h51: s_box = 8'hd1; 8'h52: s_box = 8'h00; 8'h53: s_box = 8'hed;
        8'h54: s_box = 8'h20; 8'h55: s_box = 8'hfc; 8'h56: s_box = 8'hb1; 8'h57: s_box = 8'h5b;
        8'h58: s_box = 8'h6a; 8'h59: s_box = 8'hcb; 8'h5a: s_box = 8'hbe; 8'h5b: s_box = 8'h39;
        8'h5c: s_box = 8'h4a; 8'h5d: s_box = 8'h4c; 8'h5e: s_box = 8'h58; 8'h5f: s_box = 8'hcf;

        8'h60: s_box = 8'hd0; 8'h61: s_box = 8'hef; 8'h62: s_box = 8'haa; 8'h63: s_box = 8'hfb;
        8'h64: s_box = 8'h43; 8'h65: s_box = 8'h4d; 8'h66: s_box = 8'h33; 8'h67: s_box = 8'h85;
        8'h68: s_box = 8'h45; 8'h69: s_box = 8'hf9; 8'h6a: s_box = 8'h02; 8'h6b: s_box = 8'h7f;
        8'h6c: s_box = 8'h50; 8'h6d: s_box = 8'h3c; 8'h6e: s_box = 8'h9f; 8'h6f: s_box = 8'ha8;

        8'h70: s_box = 8'h51; 8'h71: s_box = 8'ha3; 8'h72: s_box = 8'h40; 8'h73: s_box = 8'h8f;
        8'h74: s_box = 8'h92; 8'h75: s_box = 8'h9d; 8'h76: s_box = 8'h38; 8'h77: s_box = 8'hf5;
        8'h78: s_box = 8'hbc; 8'h79: s_box = 8'hb6; 8'h7a: s_box = 8'hda; 8'h7b: s_box = 8'h21;
        8'h7c: s_box = 8'h10; 8'h7d: s_box = 8'hff; 8'h7e: s_box = 8'hf3; 8'h7f: s_box = 8'hd2;

        8'h80: s_box = 8'hcd; 8'h81: s_box = 8'h0c; 8'h82: s_box = 8'h13; 8'h83: s_box = 8'hec;
        8'h84: s_box = 8'h5f; 8'h85: s_box = 8'h97; 8'h86: s_box = 8'h44; 8'h87: s_box = 8'h17;
        8'h88: s_box = 8'hc4; 8'h89: s_box = 8'ha7; 8'h8a: s_box = 8'h7e; 8'h8b: s_box = 8'h3d;
        8'h8c: s_box = 8'h64; 8'h8d: s_box = 8'h5d; 8'h8e: s_box = 8'h19; 8'h8f: s_box = 8'h73;

        8'h90: s_box = 8'h60; 8'h91: s_box = 8'h81; 8'h92: s_box = 8'h4f; 8'h93: s_box = 8'hdc;
        8'h94: s_box = 8'h22; 8'h95: s_box = 8'h2a; 8'h96: s_box = 8'h90; 8'h97: s_box = 8'h88;
        8'h98: s_box = 8'h46; 8'h99: s_box = 8'hee; 8'h9a: s_box = 8'hb8; 8'h9b: s_box = 8'h14;
        8'h9c: s_box = 8'hde; 8'h9d: s_box = 8'h5e; 8'h9e: s_box = 8'h0b; 8'h9f: s_box = 8'hdb;

        8'ha0: s_box = 8'he0; 8'ha1: s_box = 8'h32; 8'ha2: s_box = 8'h3a; 8'ha3: s_box = 8'h0a;
        8'ha4: s_box = 8'h49; 8'ha5: s_box = 8'h06; 8'ha6: s_box = 8'h24; 8'ha7: s_box = 8'h5c;
        8'ha8: s_box = 8'hc2; 8'ha9: s_box = 8'hd3; 8'haa: s_box = 8'hac; 8'hab: s_box = 8'h62;
        8'hac: s_box = 8'h91; 8'had: s_box = 8'h95; 8'hae: s_box = 8'he4; 8'haf: s_box = 8'h79;

        8'hb0: s_box = 8'he7; 8'hb1: s_box = 8'hc8; 8'hb2: s_box = 8'h37; 8'hb3: s_box = 8'h6d;
        8'hb4: s_box = 8'h8d; 8'hb5: s_box = 8'hd5; 8'hb6: s_box = 8'h4e; 8'hb7: s_box = 8'ha9;
        8'hb8: s_box = 8'h6c; 8'hb9: s_box = 8'h56; 8'hba: s_box = 8'hf4; 8'hbb: s_box = 8'hea;
        8'hbc: s_box = 8'h65; 8'hbd: s_box = 8'h7a; 8'hbe: s_box = 8'hae; 8'hbf: s_box = 8'h08;

        8'hc0: s_box = 8'hba; 8'hc1: s_box = 8'h78; 8'hc2: s_box = 8'h25; 8'hc3: s_box = 8'h2e;
        8'hc4: s_box = 8'h1c; 8'hc5: s_box = 8'ha6; 8'hc6: s_box = 8'hb4; 8'hc7: s_box = 8'hc6;
        8'hc8: s_box = 8'he8; 8'hc9: s_box = 8'hdd; 8'hca: s_box = 8'h74; 8'hcb: s_box = 8'h1f;
        8'hcc: s_box = 8'h4b; 8'hcd: s_box = 8'hbd; 8'hce: s_box = 8'h8b; 8'hcf: s_box = 8'h8a;

        8'hd0: s_box = 8'h70; 8'hd1: s_box = 8'h3e; 8'hd2: s_box = 8'hb5; 8'hd3: s_box = 8'h66;
        8'hd4: s_box = 8'h48; 8'hd5: s_box = 8'h03; 8'hd6: s_box = 8'hf6; 8'hd7: s_box = 8'h0e;
        8'hd8: s_box = 8'h61; 8'hd9: s_box = 8'h35; 8'hda: s_box = 8'h57; 8'hdb: s_box = 8'hb9;
        8'hdc: s_box = 8'h86; 8'hdd: s_box = 8'hc1; 8'hde: s_box = 8'h1d; 8'hdf: s_box = 8'h9e;

        8'he0: s_box = 8'he1; 8'he1: s_box = 8'hf8; 8'he2: s_box = 8'h98; 8'he3: s_box = 8'h11;
        8'he4: s_box = 8'h69; 8'he5: s_box = 8'hd9; 8'he6: s_box = 8'h8e; 8'he7: s_box = 8'h94;
        8'he8: s_box = 8'h9b; 8'he9: s_box = 8'h1e; 8'hea: s_box = 8'h87; 8'heb: s_box = 8'he9;
        8'hec: s_box = 8'hce; 8'hed: s_box = 8'h55; 8'hee: s_box = 8'h28; 8'hef: s_box = 8'hdf;

        8'hf0: s_box = 8'h8c; 8'hf1: s_box = 8'ha1; 8'hf2: s_box = 8'h89; 8'hf3: s_box = 8'h0d;
        8'hf4: s_box = 8'hbf; 8'hf5: s_box = 8'he6; 8'hf6: s_box = 8'h42; 8'hf7: s_box = 8'h68;
        8'hf8: s_box = 8'h41; 8'hf9: s_box = 8'h99; 8'hfa: s_box = 8'h2d; 8'hfb: s_box = 8'h0f;
        8'hfc: s_box = 8'hb0; 8'hfd: s_box = 8'h54; 8'hfe: s_box = 8'hbb; 8'hff: s_box = 8'h16;

        default: s_box = 8'h00;
        endcase
    end
    
    endfunction



     integer  i ;
    
   always @(*) begin
        
        for(i=0;i<8;i++) begin
           
            out[i] = in[i];
           
        end

        for(i=8;i<60;i++) begin
            if (i%8==0) begin
                out[i] = out[i-8]^rcon(sub_word(rot_word(out[i-1])),get_rcon(i/8));

            end else if(i%8==4) begin
                out[i] = out[i-8]^sub_word(out[i-1]);

            end else begin
                out[i] = out[i-8]^out[i-1];

            end
           
        end
   end
endmodule
