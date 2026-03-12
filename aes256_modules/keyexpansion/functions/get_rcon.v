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