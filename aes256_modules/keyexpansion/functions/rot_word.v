function [31:0] rot_word (input [31:0] in );
    rot_word = {in[23:0],in[31:24]}
endfunction