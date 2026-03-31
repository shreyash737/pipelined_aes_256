module top_module (
    input clk,
    input reset_n,
    input arduino_rx_pin ,
    input [255:0] key ,
    output reg [127:0] cipher_text,
    output reg uart_physical_pin
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