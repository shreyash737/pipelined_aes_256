module top_module (
    input clk,
    input reset_n,
    input [127:0] plain_text ,
    input [255:0] key ,
    output reg [127:0] cipher_text,
    output reg out_valid
);
    // Instantiate the key expansion module
    
    wire [1919:0] expanded_key_flat;
    wire key_ready;
    reg [13:0] valid_sr;
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

    reg [127:0] state_reg [0:13];
    wire [127:0] round_out [1:13];

    generate
        for (l = 1; l < 14; l = l + 1) begin : aes_pipeline
            aes_round round_inst (
                .in(state_reg[l-1]),
                .key(expanded_key[l]),
                .out(round_out[l])
            );
        end
    endgenerate


    wire [127:0] sb_out, sr_out, final_ark_out;
    sub_bytes   final_sb (.in(state_reg[13]), .out(sb_out));
    shift_rows  final_sr (.in(sb_out),        .out(sr_out));
    assign final_ark_out = sr_out ^ expanded_key[14];

    
    
    
    
    integer k;
    integer j;
    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            
            cipher_text <= 0;
            
            for(k=0;k<14;k++) begin
                state_reg[k] <= 0;
            end
            out_valid <= 0;
            valid_sr <= 0;

        end else if(key_ready) begin
            state_reg[0] <= plain_text ^ expanded_key[0];

            
            for (j = 1; j < 14; j = j + 1) begin
                state_reg[j] <= round_out[j];
            end

            cipher_text <= final_ark_out;
            valid_sr <= {valid_sr[12:0], key_ready};
            out_valid <= valid_sr[13];

            
        end
    end


    ///uart_tx.   


    reg [7:0] uart_byte_to_send;
    reg uart_start_signal;
    wire uart_is_busy;
    wire uart_physical_pin;

    uart_tx my_uart (
    .clk(clk),
    .rst_n(reset_n),
    .data_in(uart_byte_to_send),
    .start_tx(uart_start_signal),
    .tx(uart_physical_pin),
    .busy(uart_is_busy)
    );

    integer byte_counter = 0;
    reg [127:0] cipher_buffer;

    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            cipher_buffer <= 0;
            uart_start_signal <= 0 ;
            byte_counter <=0;
        end else begin
            if(out_valid && byte_counter==0 ) begin
                cipher_buffer = cipher_text;
                byte_counter = 1;
            end 

            if(byte_counter>0 && byte_counter < 0 && !uart_is_busy && !uart_start_signal) begin
            uart_byte_to_send <= cipher_buffer[(16-byte_counter)*8 +: 8];
            uart_start_signal <= 1;
            end else begin
                uart_start_signal <= 0; 
                if (byte_counter > 0 && !uart_is_busy && uart_start_signal == 0) begin
                
                byte_counter <= byte_counter + 1;
                if (byte_counter == 16) byte_counter <= 0
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