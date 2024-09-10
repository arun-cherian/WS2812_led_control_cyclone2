
module UART(
    input clk,
    input ser_in,
	 input wire start_tx,
	 input wire[7:0] fifo_byte,
    output ser_out1,
    output ser_out2,
	 output reg [7:0] Rx_data_buff = 8'hFF,
	 output wire wen,
	 output reg baud_clk
);

assign wen= (state==4'b0010)&&(next_for_fifo);
/* synthesis keep */
reg [7:0] Rx_data;

initial begin
    baud_count <= 0;
    Rx_data <= 0;
	 ser_main <= 0;
end


reg [8:0] baud_count;

always @(posedge clk) begin
    if (baud_count >= 8'd25) begin
        baud_clk <= ~baud_clk;
        baud_count <= 0;
    end
	 else begin
    baud_count <= baud_count + 1'b1;
	 end
end

reg [2:0] bit_spacing;
reg [2:0] bit_spacing2;

always @(posedge baud_clk) begin
    if (state == 0)begin
        bit_spacing <= 0;
		  end
    else begin
        bit_spacing <= bit_spacing + 1;
    end
end

always @(posedge baud_clk) begin
        bit_spacing2 <= bit_spacing2 + 1;
end

reg[2:0] bit_spacing2_shadow;
reg[2:0] bit_spacing_shadow;
always@(posedge clk) begin
bit_spacing2_shadow<=bit_spacing2;
bit_spacing_shadow<=bit_spacing;
end

wire next_for_fifo=(bit_spacing ==0)&&(bit_spacing_shadow==7);
wire next_bit = (bit_spacing == 5)&&(bit_spacing_shadow==4);
wire next_bit2 = (bit_spacing2 == 7)&&(bit_spacing2_shadow==6);



reg [1:0] Sync_ser;
always @(posedge clk) Sync_ser <= {ser_in, Sync_ser[1]};

reg [1:0] sync_count;
reg ser_main;
always @(posedge clk) begin
    if (Sync_ser[0] && sync_count != 2'b11)
        sync_count <= sync_count + 1;
    else if (~Sync_ser[0] && sync_count != 2'b00)
        sync_count <= sync_count - 1;

    if (sync_count == 2'b11)
        ser_main <= 1;
    else if (sync_count == 2'b00)
        ser_main <= 0;
end

reg [3:0] state;
always @(posedge clk) begin
    case (state) 
        4'b0000: if (~ser_main)state <= 4'b0001;
		  4'b0001: if (next_bit)state  <= 4'b1000;
        4'b1000: if (next_bit) state <= 4'b1001;
        4'b1001: if (next_bit) state <= 4'b1010;
        4'b1010: if (next_bit) state <= 4'b1011;
        4'b1011: if (next_bit) state <= 4'b1100;
        4'b1100: if (next_bit) state <= 4'b1101;
        4'b1101: if (next_bit) state <= 4'b1110;
        4'b1110: if (next_bit) state <= 4'b1111;
        4'b1111: if (next_bit) state <= 4'b0010;
		  4'b0010: if (ser_main) state <= 4'b0000;
        default: state <= 4'b0000;
    endcase    
end

always @(posedge clk) begin
    if (state[3] && next_bit && baud_clk)
        Rx_data <= {ser_main, Rx_data[7:1]};
	 if(state<=4'b0010)Rx_data_buff<=Rx_data;
end    

// Transmitter logic

(* preserve *) reg [7:0] TxD_data2 = 8'hFF;
reg [2:0] count_baud;
reg [3:0] state_tx;
always @(posedge clk) begin
    case (state_tx)
        4'b0011: if (start_tx) state_tx <= 4'b0100; // start
		  4'b0100: if (next_bit2) state_tx <= 4'b0101; // start_variable
		  4'b0101: if (next_bit2) state_tx <= 4'b1000; // start_real
        4'b1000: if (next_bit2) state_tx <= 4'b1001; // bit 0
        4'b1001: if (next_bit2) state_tx <= 4'b1010; // bit 1
        4'b1010: if (next_bit2) state_tx <= 4'b1011; // bit 2
        4'b1011: if (next_bit2) state_tx <= 4'b1100; // bit 3
        4'b1100: if (next_bit2) state_tx <= 4'b1101; // bit 4
        4'b1101: if (next_bit2) state_tx <= 4'b1110; // bit 5
        4'b1110: if (next_bit2) state_tx <= 4'b1111; // bit 6
        4'b1111: if (next_bit2) state_tx <= 4'b0001; // bit 7
        4'b0001: if (next_bit2) state_tx <= 4'b0010; // stop1
        4'b0010: if (next_bit2) state_tx <= 4'b0011; // stop2
        default: if (next_bit2) state_tx <= 4'b0011;
    endcase
end

reg muxbit1;
reg muxbit2;

always @(state_tx[2:0]) begin
    case (state_tx[2:0])
        0: muxbit1 <= fifo_byte[0];
        1: muxbit1 <= fifo_byte[1];
        2: muxbit1 <= fifo_byte[2];
        3: muxbit1 <= fifo_byte[3];
        4: muxbit1 <= fifo_byte[4];
        5: muxbit1 <= fifo_byte[5];
        6: muxbit1 <= fifo_byte[6];
        7: muxbit1 <= fifo_byte[7];
    endcase
end

/*always @(state_tx[2:0]) begin
    case (state_tx[2:0])
        0: muxbit2 <= TxD_data2[0];
        1: muxbit2 <= TxD_data2[1];
        2: muxbit2 <= TxD_data2[2];
        3: muxbit2 <= TxD_data2[3];
        4: muxbit2 <= TxD_data2[4];
        5: muxbit2 <= TxD_data2[5];
        6: muxbit2 <= TxD_data2[6];
        7: muxbit2 <= TxD_data2[7];
    endcase
end*/

always @(state_tx[2:0]) begin
    case (state_tx[2:0])
        0: muxbit2 <=1;
        1: muxbit2 <=0;
        2: muxbit2 <=0;
        3: muxbit2 <=0;
        4: muxbit2 <=0;
        5: muxbit2 <=0;
        6: muxbit2 <=1;
        7: muxbit2 <=1;
    endcase
end

// Combine start, data, and stop bits together
assign ser_out1 = (state_tx < 5) | (state_tx[3] & muxbit1);    
assign ser_out2 = (state_tx < 5) | (state_tx[3] & muxbit2);    


endmodule


