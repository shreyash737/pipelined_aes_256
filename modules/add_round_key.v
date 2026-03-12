module add_round_key(input[7:0] in [15:0] ,input [7:0] key [15:0],output [7:0] out [15:0]);
    genvar i;
    generate
        for(i=0 ;i < 16 ;i++) begin
            assign out[i] = in[i]^key[i];
        end
    endgenerate
endmodule