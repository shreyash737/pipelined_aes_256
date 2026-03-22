module key_expansion(input [255:0]key,input clk,input reset_n,output reg [1919:0] expandedkey , output reg ready);
    reg [31:0] internal_key [0:59] ;
    wire [31:0]sub_word_input;
    wire [31:0] sub_word_output;
    

    genvar i;
    generate
        s_box instance1(.in(sub_word_input[7:0]),.out(sub_word_output[7:0]));
        s_box instance1(.in(sub_word_input[15:8]),.out(sub_word_output[15:7]));
        s_box instance1(.in(sub_word_input[23:16]),.out(sub_word_output[23:16]));
        s_box instance1(.in(sub_word_input[31:24]),.out(sub_word_output[31:24]));
    endgenerate

    integer counter = 0;

    assign sbox_in_word = (count % 8 == 0) ? {w[count-1][23:0], w[count-1][31:24]} : // RotWord
                          (count % 8 == 4) ? w[count-1]                           : // SubWord only
                          32'h0;

    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            internal_key <= 0;
            ready <= 0;
            expandedkey <= 0;
            counter <= 0;
        end else begin
            if(counter<8)begin
                internal_key = key[(counter*8-1):(counter*8)];
                counter = counter+1;
            end

            if(count < 60) begin
                if(counter%8==0) begin
                   
                    internal_key[counter] <= internal_key[counter-8]^sub_word_output^{get_rcon(count/8), 24'h0};
                end else if(counter%8==4) begin
                    
                    internal_key[counter] <= internal_key[counter-8]^sub_word_output;
                end else begin
                    internal_key[counter] <= internal_key[counter-8]^internal_key(coun_ter-1)
                end
                counter = counter + 1;
            end else begin
                ready <= 1'b0;
                integer k;
                for (k = 0; k < 60; k = k + 1) begin
                    expandedkey[k*32 +: 32] <= internal_key[k];
                end

            end


        end
    end

    function [7:0] get_rcon(input [3:0] round_idx);
        case(round_idx)
            4'd1:  get_rcon = 8'h01; 4'd2:  get_rcon = 8'h02;
            4'd3:  get_rcon = 8'h04; 4'd4:  get_rcon = 8'h08;
            4'd5:  get_rcon = 8'h10; 4'd6:  get_rcon = 8'h20;
            4'd7:  get_rcon = 8'h40; 4'd8:  get_rcon = 8'h80;
            4'd9:  get_rcon = 8'h1b; 4'd10: get_rcon = 8'h36;
            default: get_rcon = 8'h00;
        endcase
    endfunction

endmodule