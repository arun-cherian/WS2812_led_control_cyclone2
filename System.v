module System(
    input clk,
	 //input push,
    input ser_in,
    output ser_data,
	 //output ser_out,
	 output wire[7:0] data_out,
	 output wire[7:0] data_in,
	 output wire[7:0] fifo_byte,
	 output wire [7:0] Rx_data_buff
);
wire wen;
wire [7:0] sub_wire3;
wire [7:0] address;
wire [7:0] data_out_mem;
wire wren;
reg [1:0] Sync_ser;
wire baud_clk;
wire start_tx;
//always @(posedge clk) Sync_ser <= {rclk, Sync_ser[1]};

//reg [5:0] sync_count;
//reg ser_main;
/*always @(posedge clk) begin
    if (Sync_ser[0] && sync_count != 6'b11)
        sync_count <= sync_count + 1;
    else if (~Sync_ser[0] && sync_count != 6'b00)
        sync_count <= sync_count - 1;

    if (sync_count == 6'b11)
        ser_main <= 1;
    else if (sync_count == 6'b00)
        ser_main <= 0;
end*/

		

// Instantiate the new_led module
new_led led_instance (
	 .address1(address),
    .clk(clk),
    .ser_data(ser_data),
	 .wden(wren),
	 .fifo_byte(sub_wire3),
	 .start_tx(start_tx),
	 .data_in(data_out_mem),
	 .buff_empty(sub_wire4)
);

// Instantiate the UART module
UART uart_instance (
    .clk(clk),
    .ser_in(ser_in),
	 .Rx_data_buff(Rx_data_buff),
	 .baud_clk(baud_clk),
	 .wen(wen),
	 .fifo_byte(sub_wire3),
	 .start_tx(start_tx),
	 //.ser_out1(ser_out)
);

fifo fifo_instance (
	.data(Rx_data_buff),
	.rdclk(clk),
	.rdreq(wren),
	.wrclk(clk),
	.wrreq(wen),
	.q(data_out),
	.wrusedw (sub_wire3)
);
ram ram_instance (
	.address(address),
	.clock(clk),
	.data(data_out),
	.wren(wren),
	.q(data_out_mem));


endmodule
