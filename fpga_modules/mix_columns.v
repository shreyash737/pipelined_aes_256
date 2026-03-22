module mix_columns(input [127:0]in, output [127:0] out);
   
    wire [7:0] s [0:15];
    genvar k;
    generate
        for (k=0; k<16; k=k+1) assign s[k] = in[127-8*k : 120-8*k];
    endgenerate
    
    
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
        assign out[i] = xtime(s[i]) ^ xtime3(s[i+1]) ^  s[i+2] ^  s[i+3] ;
        assign out[i+1] = s[i]^ xtime(s[i+1]) ^  xtime3(s[i+2]) ^  s[i+3] ;
        assign out[i+2] = s[i] ^ s[i+1] ^  xtime(s[i+2]) ^  xtime3(s[i+3]) ;
        assign out[i+3] = xtime3(s[i]) ^s[i+1] ^  s[i+2] ^  xtime(s[i+3]) ;
        end
        
    endgenerate
            /// i was gonnna wirte for each element but after wathing similarities i w=decided to use loop
    
        // out[i] = xtime[in[i]] ^ xtime[in[i+1]] ^  xtime[in[i+2]] ^  xtime[in[i+3]] ;
        // out[i+1] = xtime[in[i]] ^ xtime[in[i+1]] ^  xtime[in[i+2]] ^  xtime[in[i+3]] ;
        // out[i+2] = xtime[in[i]] ^ xtime[in[i+1]] ^  xtime[in[i+2]] ^  xtime[in[i+3]] ;
        // out[i+3] = xtime[in[i]] ^ xtime[in[i+1]] ^  xtime[in[i+2]] ^  xtime[in[i+3]] ;

  

endmodule

// module xtime(input [7:0] in , output [7:0] out );
//     //multiplying by 2
//     always @(*) begin
//         if(in[0]==0) : out = {in[6:0] , 1'b0};
//         else : out  = {in[6:0],1'b0} + 8'he1B;
//     end
// endmodule

// module 3xtime(input [7:0] in , output [7:0] out );
//     wire [7:0] out_1;
//     xtime instance1(in,out_1);
//     always@(*) begin
//         out = out_1 ^ in;
//     end
// endmodule

