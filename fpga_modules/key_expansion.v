


module key_expansion(input [255:0] key_in ,input clk ,input reset_n, output reg [1919:0] expanded_key_out);
    wire [31:0] key [0:7];
    reg [31:0] expanded_key [0:59];
    wire [31:0] s_word[0:59];
 

    genvar i ;

    generate
        for (i=0;i < 8;i=i+1) begin
            assign  key [i] = key_in[((i+1)*32-1):(i*32)]

        end
    endgenerate

    generate
        for(i=8;i<60;i=i+1)begin
            if(i%8==0) begin
            wire [7:0] rot_wordout;
            assign rot_wordout = rot_word(expanded_key[i-1])

            s_box instance1(rot_wordout,s_word[i])

            end else if(i%8==4)
            s_box instance2(expanded_key[i-1],s_word[i])
        end

    endgenerate

   
        
    

   


   integer  i=0  ;
   wire [7:0] s_word;
   always @(posedge clk negedge rest_n) begin
        if(!reset_n) begin
            expanded_key_out <= {1920{1'b0}}
        end else begin

        if(count<8) begin
           expanded_key[i] <= in[i];
        end
           
        

        if(count<60) begin
            if (i%8==0) begin
                expanded_key[i] <= expanded_key[i-8]^rcon(s_word[i],get_rcon(i/8));   

                end else if(i%8==4) begin
                
                expanded_key[i] <= expanded_key[i-8]^s_word[i];  

                end else begin

                expanded_key[i] <= expanded_key[i-8]^expanded_key[i-1];
                end
           
        end

        count <= count+1;

        end
        
        
   end

   generate 
    for (i=0;i < 60) begin
            assign  expanded_key_out[((i+1)*32-1):(i*32)] = expanded_key[i];
        end
   endgenerate

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
endmodule

