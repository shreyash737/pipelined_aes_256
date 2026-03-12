function [31:0] rcon (input [31:0] in , input [7:0] rc);
    rcon = in ^ {rc,8'h00,8'h00,8'h00}; 
endfunction