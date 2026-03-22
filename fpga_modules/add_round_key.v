module add_round_key(input[127:0] in ,input [127:0] key,output [127:0] out );
    //can use nthe normal always@ block also
    assign out =m in^key ;
endmodule