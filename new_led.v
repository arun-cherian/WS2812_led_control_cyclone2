
module new_led (
    input clk,
	 input wire[7:0]  data_in,
	 input wire[7:0]  fifo_byte,
	 input wire buff_empty,
    output reg ser_data,
	 output wire[7:0] address1,
	 output reg wden,
	 output reg start_tx
);


reg [7:0] address;
reg [1:0] state;
reg [10:0] split;
reg [32:0] data_count;
reg [23:0] data;
reg [4:0] count;  // Adjusted width to 5 bits to match the maximum value of 24
reg [5:0] byte_count;
reg [5:0] frame_count;
reg [32:0] reset_delay  = 32'd50000000;
reg [7:0] led_num  = 8'd61;
reg [2:0] state_load;




parameter [2:0] LOAD_BIT  = 2'b00;
parameter [2:0] SEND  = 2'b01;
parameter [2:0] RESET = 2'b10;
parameter [2:0] LOAD_BYTE  = 2'b11;



initial begin 
    split <= 0;
    data_count <= 0;
    state <= RESET;
    data <= {8'd0, 8'd0, 8'd0};
    count <= 0;  // Initialize count
	 byte_count<=0;
	 frame_count<=0;
end


assign address1=address;

always @(posedge clk) begin
    case(state)
        RESET: begin 
            ser_data <= 0;
            if (data_count >= reset_delay) begin
                data_count <= 0;
                count <= 0;
                state <= LOAD_BYTE;
                state_load <= 0;
                data <= 0;
                wden <= 0;
            end 
            else begin 
                if (reset_delay - led_num < data_count && data_count < reset_delay) begin
                    wden <= ~wden;
                    if (wden && fifo_byte != 0)
                        address <= address + 1;
                end else begin
                    if (data_count == 2)begin
                        start_tx <= 1;
								address <= 0;
								end
                    else
                        start_tx <= 0;
                    data_count <= data_count + 1'd1;
                end
            end
        end

        LOAD_BIT: begin
            data_count <= 0;
            if (count >= 5'd24) begin
                count <= 0;
                state <= LOAD_BYTE;
                state_load <= 0;
            end else begin
                if (data[count] == 1'b1) begin
                    split <= 10'd40;
                end else begin
                    split <= 10'd21;
                end
                state <= SEND;
                count <= count + 1'd1;
            end
        end

        SEND: begin
            if (data_count < split) begin
                ser_data <= 1'b1;
            end else if (data_count < 10'd60) begin
                ser_data <= 1'b0;
            end else begin
                state <= LOAD_BIT;
            end
            data_count <= data_count + 1'd1;
        end
        
        LOAD_BYTE: begin
            start_tx <= 0;
            ser_data <= 0;
            if (byte_count > 6'd10) begin
                byte_count <= 0;
                state <= RESET;
            end else begin
                case(state_load)
                    4'd0: begin 
                        address <= byte_count; 
                        state_load <= 2; 
                    end
                    4'd2: begin 
                        data <= {data[23:6], data_in};
                        state_load <= 3; 
                    end
                    4'd3: begin 
                        address <= byte_count + 1; 
                        state_load <= 4; 
                    end
                    4'd4: begin 
                        data <= {data[23:16], data_in, data[7:0]};
                        state_load <= 5; 
                    end
                    4'd5: begin 
                        address <= byte_count + 2; 
                        state_load <= 6; 
                    end
                    4'd6: begin 
                        data <= {data_in, data[15:0]};
                        state_load <= 0;             
                        state <= LOAD_BIT;
                        count <= 0;
                        byte_count <= byte_count + 1'd1;
                    end
                    default: state <= RESET;
                endcase
            end
        end

        default: state <= RESET;
    endcase
end
endmodule



			
			
				
				
		
	
