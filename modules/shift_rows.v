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