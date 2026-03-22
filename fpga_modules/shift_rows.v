module shift_rows(input [127:0] in , output [127:0] out);
    
    wire [7:0] s [0:15];
    wire [7:0] r [0:15];

    genvar k;
    generate
        for (k=0; k<16; k=k+1) assign s[k] = in[127-8*k : 120-8*k];
    endgenerate

    assign r[0] = s[0];
    assign r[4] = s[4];
    assign r[8] = s[8];
    assign r[12] = s[12];

    assign r[1] = s[5];
    assign r[5] = s[9];
    assign r[9] = s[13];
    assign r[13] = s[1];

    assign r[2] = s[10];
    assign r[6] = s[14];
    assign r[10] = s[2];
    assign r[14] = s[6];

    assign r[3] = s[15];
    assign r[7] = s[3];
    assign r[11] = s[7];
    assign r[15] = s[11];

    
    generate
        for (k=0; k<16; k=k+1) assign out[127-8*k : 120-8*k] =  r[k];
    endgenerate


endmodule