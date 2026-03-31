module top_module (
    input clk,
    input reset_n,
    input arduino_rx_pin ,
    input [255:0] key ,
    output reg [127:0] cipher_text,
    output wire uart_physical_pin
);
    // Instantiate the key expansion module
    
    wire [1919:0] expanded_key_flat;
    wire key_ready;
    
    key_expansion key_expansion_inst (
        .key(key),
        .clk(clk),
        .expanded_key(expanded_key_flat),
        .ready(key_ready),
        .reset_n(reset_n)
    );

    wire [127:0] expanded_key [0:14];
    genvar l;
    generate
        for (l = 0; l < 15; l = l+ 1) begin : unpack_key
            assign expanded_key[l] = expanded_key_flat[l*128 +: 128];
        end
    endgenerate

    // --- 2. UART Receiver (Arduino -> FPGA) ---
    wire [7:0] arduino_byte;
    wire byte_ready;
    reg [127:0] rx_data_block;
    reg [3:0] rx_count = 0;
    reg start_aes = 0;


    uart_rx receiver (
        .clk(clk),
        .rst_n(reset_n),
        .rx(arduino_rx_pin),
        .data_out(arduino_byte),
        .rx_done(byte_ready)
    );

    // Collect 16 bytes into one 128-bit block
    always @(posedge clk) begin
        start_aes <= 1'b0;
        if (byte_ready) begin
            rx_data_block <= {rx_data_block[119:0], arduino_byte};
            if (rx_count == 15) begin
                rx_count <= 0;
                start_aes <= 1'b1; // Trigger AES pipeline
            end else begin
                rx_count <= rx_count + 1;
            end
        end
    end

    reg [127:0] state_reg [0:13];
    wire [127:0] round_out [1:13];
    reg [14:0] valid_sr;

    generate
        for (l = 1; l < 14; l = l + 1) begin : aes_pipeline
            aes_round round_inst (
                .in(state_reg[l-1]),
                .key(expanded_key[l]),
                .out(round_out[l])
            );
        end
    endgenerate


    

    
    
    
    
    integer k;
    integer j;
    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            
            cipher_text <= 0;
            
            for(k=0;k<14;k=k+1) begin
                state_reg[k] <= 0;
            end
            valid_sr <= 0;

        end else if(key_ready) begin
            
            state_reg[0] <= rx_data_block ^ expanded_key[0];


            
            for (j = 1; j < 14; j = j + 1) begin
                state_reg[j] <= round_out[j];
            end

            cipher_text <= final_ark_out;
            valid_sr <= {valid_sr[12:0],start_aes};
            

            
        end
    end

    ///final round 
    wire [127:0] sb_out, sr_out, final_ark_out;
    sub_bytes   final_sb (.in(state_reg[13]), .out(sb_out));
    shift_rows  final_sr (.in(sb_out),        .out(sr_out));
    assign final_ark_out = sr_out ^ expanded_key[14];


    // --- 4. UART Transmitter (FPGA -> Mac) ---
    reg [7:0] tx_byte;
    reg tx_start;
    wire tx_busy;
    reg [127:0] tx_buffer;
    integer tx_byte_count = 0;
    wire aes_out_valid = valid_sr[13];

    uart_tx transmitter (
        .clk(clk),
        .rst_n(reset_n),
        .data_in(tx_byte),
        .start_tx(tx_start),
        .tx(uart_physical_pin),
        .busy(tx_busy)
    );

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            tx_byte_count <= 0;
            tx_start <= 0;
        end else begin
            // Capture AES output when valid
            if (aes_out_valid && tx_byte_count == 0) begin
                tx_buffer <= final_ark_out;
                tx_byte_count <= 1;
            end

            // Send 16 bytes sequentially
            if (tx_byte_count >= 1 && tx_byte_count <= 16 && !tx_busy && !tx_start) begin
                tx_byte <= tx_buffer[(16 - tx_byte_count) * 8 +: 8];
                tx_start <= 1'b1;
            end else begin
                tx_start <= 1'b0;
                if (tx_byte_count >= 1 && !tx_busy && tx_start == 0) begin
                    if (tx_byte_count < 16)
                        tx_byte_count <= tx_byte_count + 1;
                    else
                        tx_byte_count <= 0; // Finished all 16 bytes
                end
            end
        end
    end



endmodule

module aes_round(
    input [127:0] in,
    input [127:0] key,
    output [127:0] out 
     );

    wire [127:0] sb_out ;
    wire [127:0] sr_out ;
    wire [127:0] mc_out ;
    wire [127:0] ark_out ;

    sub_bytes instance1(.in(in) , .out(sb_out));
    shift_rows instance2(.in(sb_out) , .out(sr_out));
    mix_columns instance3(.in(sr_out) , .out(mc_out));
    add_round_key instance4(.in(mc_out) , .key(key) , .out(ark_out));
    assign out = ark_out;

endmodule




module uart_rx (
    input clk,            // 100MHz
    input rst_n,          // Reset
    input rx,             // Physical RX pin (Connect to Arduino TX)
    output reg [7:0] data_out, // The byte received
    output reg rx_done    // High for 1 cycle when byte is ready
);

    // 100MHz / 115200 Baud = 868 ticks
    parameter CLK_TICKS = 868;
    parameter HALF_TICKS = 434; // To sample in the middle of the bit

    localparam IDLE  = 2'b00;
    localparam START = 2'b01;
    localparam DATA  = 2'b10;
    localparam STOP  = 2'b11;

    reg [1:0]  state = IDLE;
    reg [15:0] count = 0;
    reg [2:0]  bit_index = 0;
    reg [7:0]  rx_buffer = 0;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            rx_done <= 0;
            count <= 0;
        end else begin
            rx_done <= 0; // Default pulse low

            case (state)
                IDLE: begin
                    if (rx == 1'b0) begin // Start bit detected
                        if (count < HALF_TICKS) begin
                            count <= count + 1;
                        end else begin
                            count <= 0;
                            state <= START;
                        end
                    end else begin
                        count <= 0;
                    end
                end

                START: begin
                    if (count < CLK_TICKS - 1) begin
                        count <= count + 1;
                    end else begin
                        count <= 0;
                        state <= DATA;
                        bit_index <= 0;
                    end
                end

                DATA: begin
                    if (count < CLK_TICKS - 1) begin
                        count <= count + 1;
                    end else begin
                        count <= 0;
                        rx_buffer[bit_index] <= rx; // Sample the bit
                        if (bit_index < 7) begin
                            bit_index <= bit_index + 1;
                        end else begin
                            state <= STOP;
                        end
                    end
                end

                STOP: begin
                    if (count < CLK_TICKS - 1) begin
                        count <= count + 1;
                    end else begin
                        count <= 0;
                        data_out <= rx_buffer;
                        rx_done  <= 1'b1; // Trigger "Done" for 1 cycle
                        state    <= IDLE;
                    end
                end
            endcase
        end
    end
endmodule



module uart_tx (
    input clk,           // 100MHz from Basys 3
    input rst_n,         // Active low reset
    input [7:0] data_in, // The byte to send (e.g., 8'h41 for 'A')
    input start_tx,      // Pulse high to start transmission
    output reg tx,       // Connect to Pin A18 in XDC
    output reg busy      // High when sending, Low when ready
);

    // 1. Baud Rate Timing
    // 100MHz / 115200 Baud = 868.05
    parameter CLK_TICKS = 868;

    // 2. State Machine Definitions
    localparam IDLE  = 2'b00;
    localparam START = 2'b01;
    localparam DATA  = 2'b10;
    localparam STOP  = 2'b11;

    reg [1:0]  state      = IDLE;
    reg [15:0] baud_count = 0;
    reg [2:0]  bit_index  = 0; // Tracks which of the 8 bits we are sending
    reg [7:0]  tx_data    = 0; // Local buffer for data_in

    // 3. The Transmitter Logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state      <= IDLE;
            tx         <= 1'b1; // UART line is high when idle
            busy       <= 1'b0;
            baud_count <= 0;
        end else begin
            case (state)
                IDLE: begin
                    tx   <= 1'b1; // Keep line high
                    busy <= 1'b0;
                    baud_count <= 0;
                    if (start_tx) begin
                        tx_data <= data_in; // "Freeze" the input data
                        state   <= START;
                        busy    <= 1'b1;
                    end
                end

                START: begin
                    tx <= 1'b0; // Start Bit is always 0
                    if (baud_count < CLK_TICKS - 1) begin
                        baud_count <= baud_count + 1;
                    end else begin
                        baud_count <= 0;
                        state      <= DATA;
                        bit_index  <= 0;
                    end
                end

                DATA: begin
                    tx <= tx_data[bit_index]; // Send bits LSB first
                    if (baud_count < CLK_TICKS - 1) begin
                        baud_count <= baud_count + 1;
                    end else begin
                        baud_count <= 0;
                        if (bit_index < 7) begin
                            bit_index <= bit_index + 1;
                        end else begin
                            state <= STOP;
                        end
                    end
                end

                STOP: begin
                    tx <= 1'b1; // Stop Bit is always 1
                    if (baud_count < CLK_TICKS - 1) begin
                        baud_count <= baud_count + 1;
                    end else begin
                        baud_count <= 0;
                        state      <= IDLE;
                        busy       <= 1'b0;
                    end
                end
            endcase
        end
    end
endmodule


module add_round_key(input[127:0] in ,input [127:0] key,output [127:0] out );
    //can use nthe normal always@ block also
    assign out = in ^ key ;
endmodule


module key_expansion(input [255:0]key,input clk,input reset_n,output reg [1919:0] expanded_key , output reg ready);
    reg [1919:0] internal_key ;
    reg [31:0] sub_word_input;
    reg [31:0] temp_word;
    wire [31:0] sub_word_output;
    

    
        s_box instance1(.in(sub_word_input[7:0]),.out(sub_word_output[7:0]));
        s_box instance2(.in(sub_word_input[15:8]),.out(sub_word_output[15:8]));
        s_box instance3(.in(sub_word_input[23:16]),.out(sub_word_output[23:16]));
        s_box instance4(.in(sub_word_input[31:24]),.out(sub_word_output[31:24]));
   

    integer counter = 0;

    // assign sub_word_input = (counter % 8 == 0) ? {internal_key[(counter-1)*32 +:32][23:0], internal_key[(counter-1)*32 +:32][31:24]} : // RotWord
    //                         (counter % 8 == 4) ? internal_key[(counter-1)*32 +:32]                           : // SubWord only
    //                         32'h0;

    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            internal_key <= 0;
            ready <= 0;
            expanded_key <= 0;
            counter <= 0;
            sub_word_input <= 0;
            temp_word <= 0;
        end else begin
            if(counter >= 1) begin
                temp_word <= internal_key[(counter-1)*32 +:32];
                sub_word_input <= (counter % 8 == 0) ? {temp_word[23:0], temp_word[31:24]} : // RotWord
                                  (counter % 8 == 4) ? temp_word                           : // SubWord only
                                  32'h0;
            end
            if(counter<8)begin
                internal_key[counter * 32 +: 32] <= key[counter * 32 +: 32];
                counter <= counter+1;
            end

            if(counter < 60) begin
                if(counter%8==0) begin
                   
                    internal_key[counter*32 +:32] <= internal_key[(counter-8)*32 +:32]^sub_word_output^{get_rcon(counter/8), 24'h0};
                end else if(counter%8==4) begin
                    
                    internal_key[counter*32 +:32] <= internal_key[(counter-8)*32 +:32]^sub_word_output;
                end else begin
                    internal_key[counter*32 +:32] <= internal_key[(counter-8)*32 +:32]^internal_key[(counter-1)*32 +:32];
                end
                counter <= counter + 1;
            end else begin
                ready <= 1'b1;
                expanded_key <= internal_key;

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



module sub_bytes(input [127:0] in  , output [127:0] out );
    wire [7:0] s [0:15];
    wire [7:0] r [0:15];

    genvar k;
    generate
        for (k=0; k<16; k=k+1) assign s[k] = in[127-8*k : 120-8*k];
    endgenerate
    
    genvar i;
    generate
        for(i=0 ; i <16 ; i=i+1) begin
            s_box instance1(.in(s[i]) , .out(r[i]));
        end
            
    endgenerate

    generate
        for (k=0; k<16; k=k+1) assign out[127-8*k : 120-8*k] = r[k];
    endgenerate
        
endmodule 

module s_box (
    input  [7:0] in,
    output reg [7:0] out
);

always @(*) begin
    case (in)
        8'h00: out = 8'h63; 8'h01: out = 8'h7c; 8'h02: out = 8'h77; 8'h03: out = 8'h7b;
        8'h04: out = 8'hf2; 8'h05: out = 8'h6b; 8'h06: out = 8'h6f; 8'h07: out = 8'hc5;
        8'h08: out = 8'h30; 8'h09: out = 8'h01; 8'h0a: out = 8'h67; 8'h0b: out = 8'h2b;
        8'h0c: out = 8'hfe; 8'h0d: out = 8'hd7; 8'h0e: out = 8'hab; 8'h0f: out = 8'h76;

        8'h10: out = 8'hca; 8'h11: out = 8'h82; 8'h12: out = 8'hc9; 8'h13: out = 8'h7d;
        8'h14: out = 8'hfa; 8'h15: out = 8'h59; 8'h16: out = 8'h47; 8'h17: out = 8'hf0;
        8'h18: out = 8'had; 8'h19: out = 8'hd4; 8'h1a: out = 8'ha2; 8'h1b: out = 8'haf;
        8'h1c: out = 8'h9c; 8'h1d: out = 8'ha4; 8'h1e: out = 8'h72; 8'h1f: out = 8'hc0;

        8'h20: out = 8'hb7; 8'h21: out = 8'hfd; 8'h22: out = 8'h93; 8'h23: out = 8'h26;
        8'h24: out = 8'h36; 8'h25: out = 8'h3f; 8'h26: out = 8'hf7; 8'h27: out = 8'hcc;
        8'h28: out = 8'h34; 8'h29: out = 8'ha5; 8'h2a: out = 8'he5; 8'h2b: out = 8'hf1;
        8'h2c: out = 8'h71; 8'h2d: out = 8'hd8; 8'h2e: out = 8'h31; 8'h2f: out = 8'h15;

        8'h30: out = 8'h04; 8'h31: out = 8'hc7; 8'h32: out = 8'h23; 8'h33: out = 8'hc3;
        8'h34: out = 8'h18; 8'h35: out = 8'h96; 8'h36: out = 8'h05; 8'h37: out = 8'h9a;
        8'h38: out = 8'h07; 8'h39: out = 8'h12; 8'h3a: out = 8'h80; 8'h3b: out = 8'he2;
        8'h3c: out = 8'heb; 8'h3d: out = 8'h27; 8'h3e: out = 8'hb2; 8'h3f: out = 8'h75;

        8'h40: out = 8'h09; 8'h41: out = 8'h83; 8'h42: out = 8'h2c; 8'h43: out = 8'h1a;
        8'h44: out = 8'h1b; 8'h45: out = 8'h6e; 8'h46: out = 8'h5a; 8'h47: out = 8'ha0;
        8'h48: out = 8'h52; 8'h49: out = 8'h3b; 8'h4a: out = 8'hd6; 8'h4b: out = 8'hb3;
        8'h4c: out = 8'h29; 8'h4d: out = 8'he3; 8'h4e: out = 8'h2f; 8'h4f: out = 8'h84;

        8'h50: out = 8'h53; 8'h51: out = 8'hd1; 8'h52: out = 8'h00; 8'h53: out = 8'hed;
        8'h54: out = 8'h20; 8'h55: out = 8'hfc; 8'h56: out = 8'hb1; 8'h57: out = 8'h5b;
        8'h58: out = 8'h6a; 8'h59: out = 8'hcb; 8'h5a: out = 8'hbe; 8'h5b: out = 8'h39;
        8'h5c: out = 8'h4a; 8'h5d: out = 8'h4c; 8'h5e: out = 8'h58; 8'h5f: out = 8'hcf;

        8'h60: out = 8'hd0; 8'h61: out = 8'hef; 8'h62: out = 8'haa; 8'h63: out = 8'hfb;
        8'h64: out = 8'h43; 8'h65: out = 8'h4d; 8'h66: out = 8'h33; 8'h67: out = 8'h85;
        8'h68: out = 8'h45; 8'h69: out = 8'hf9; 8'h6a: out = 8'h02; 8'h6b: out = 8'h7f;
        8'h6c: out = 8'h50; 8'h6d: out = 8'h3c; 8'h6e: out = 8'h9f; 8'h6f: out = 8'ha8;

        8'h70: out = 8'h51; 8'h71: out = 8'ha3; 8'h72: out = 8'h40; 8'h73: out = 8'h8f;
        8'h74: out = 8'h92; 8'h75: out = 8'h9d; 8'h76: out = 8'h38; 8'h77: out = 8'hf5;
        8'h78: out = 8'hbc; 8'h79: out = 8'hb6; 8'h7a: out = 8'hda; 8'h7b: out = 8'h21;
        8'h7c: out = 8'h10; 8'h7d: out = 8'hff; 8'h7e: out = 8'hf3; 8'h7f: out = 8'hd2;

        8'h80: out = 8'hcd; 8'h81: out = 8'h0c; 8'h82: out = 8'h13; 8'h83: out = 8'hec;
        8'h84: out = 8'h5f; 8'h85: out = 8'h97; 8'h86: out = 8'h44; 8'h87: out = 8'h17;
        8'h88: out = 8'hc4; 8'h89: out = 8'ha7; 8'h8a: out = 8'h7e; 8'h8b: out = 8'h3d;
        8'h8c: out = 8'h64; 8'h8d: out = 8'h5d; 8'h8e: out = 8'h19; 8'h8f: out = 8'h73;

        8'h90: out = 8'h60; 8'h91: out = 8'h81; 8'h92: out = 8'h4f; 8'h93: out = 8'hdc;
        8'h94: out = 8'h22; 8'h95: out = 8'h2a; 8'h96: out = 8'h90; 8'h97: out = 8'h88;
        8'h98: out = 8'h46; 8'h99: out = 8'hee; 8'h9a: out = 8'hb8; 8'h9b: out = 8'h14;
        8'h9c: out = 8'hde; 8'h9d: out = 8'h5e; 8'h9e: out = 8'h0b; 8'h9f: out = 8'hdb;

        8'ha0: out = 8'he0; 8'ha1: out = 8'h32; 8'ha2: out = 8'h3a; 8'ha3: out = 8'h0a;
        8'ha4: out = 8'h49; 8'ha5: out = 8'h06; 8'ha6: out = 8'h24; 8'ha7: out = 8'h5c;
        8'ha8: out = 8'hc2; 8'ha9: out = 8'hd3; 8'haa: out = 8'hac; 8'hab: out = 8'h62;
        8'hac: out = 8'h91; 8'had: out = 8'h95; 8'hae: out = 8'he4; 8'haf: out = 8'h79;

        8'hb0: out = 8'he7; 8'hb1: out = 8'hc8; 8'hb2: out = 8'h37; 8'hb3: out = 8'h6d;
        8'hb4: out = 8'h8d; 8'hb5: out = 8'hd5; 8'hb6: out = 8'h4e; 8'hb7: out = 8'ha9;
        8'hb8: out = 8'h6c; 8'hb9: out = 8'h56; 8'hba: out = 8'hf4; 8'hbb: out = 8'hea;
        8'hbc: out = 8'h65; 8'hbd: out = 8'h7a; 8'hbe: out = 8'hae; 8'hbf: out = 8'h08;

        8'hc0: out = 8'hba; 8'hc1: out = 8'h78; 8'hc2: out = 8'h25; 8'hc3: out = 8'h2e;
        8'hc4: out = 8'h1c; 8'hc5: out = 8'ha6; 8'hc6: out = 8'hb4; 8'hc7: out = 8'hc6;
        8'hc8: out = 8'he8; 8'hc9: out = 8'hdd; 8'hca: out = 8'h74; 8'hcb: out = 8'h1f;
        8'hcc: out = 8'h4b; 8'hcd: out = 8'hbd; 8'hce: out = 8'h8b; 8'hcf: out = 8'h8a;

        8'hd0: out = 8'h70; 8'hd1: out = 8'h3e; 8'hd2: out = 8'hb5; 8'hd3: out = 8'h66;
        8'hd4: out = 8'h48; 8'hd5: out = 8'h03; 8'hd6: out = 8'hf6; 8'hd7: out = 8'h0e;
        8'hd8: out = 8'h61; 8'hd9: out = 8'h35; 8'hda: out = 8'h57; 8'hdb: out = 8'hb9;
        8'hdc: out = 8'h86; 8'hdd: out = 8'hc1; 8'hde: out = 8'h1d; 8'hdf: out = 8'h9e;

        8'he0: out = 8'he1; 8'he1: out = 8'hf8; 8'he2: out = 8'h98; 8'he3: out = 8'h11;
        8'he4: out = 8'h69; 8'he5: out = 8'hd9; 8'he6: out = 8'h8e; 8'he7: out = 8'h94;
        8'he8: out = 8'h9b; 8'he9: out = 8'h1e; 8'hea: out = 8'h87; 8'heb: out = 8'he9;
        8'hec: out = 8'hce; 8'hed: out = 8'h55; 8'hee: out = 8'h28; 8'hef: out = 8'hdf;

        8'hf0: out = 8'h8c; 8'hf1: out = 8'ha1; 8'hf2: out = 8'h89; 8'hf3: out = 8'h0d;
        8'hf4: out = 8'hbf; 8'hf5: out = 8'he6; 8'hf6: out = 8'h42; 8'hf7: out = 8'h68;
        8'hf8: out = 8'h41; 8'hf9: out = 8'h99; 8'hfa: out = 8'h2d; 8'hfb: out = 8'h0f;
        8'hfc: out = 8'hb0; 8'hfd: out = 8'h54; 8'hfe: out = 8'hbb; 8'hff: out = 8'h16;

        default: out = 8'h00;
    endcase
end

endmodule
