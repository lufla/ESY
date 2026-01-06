`timescale 1ns / 1ps
/*****************************************************************
Info: This module is based on the packet handler from 
https://github.com/chili-chips-ba/openeye-CamSI/tree/main
and has been adapted for this project.
*****************************************************************/
module csi_rx_hdr_ecc (
   input [23:0] data,
   output reg [7:0]  ecc
);

   always@* begin
      ecc[7] = 1'b0;
      ecc[6] = 1'b0;

      ecc[5] = data[10] ^ data[11] ^ data[12] ^ data[13] ^ data[14] ^ data[15]
             ^ data[16] ^ data[17] ^ data[18] ^ data[19] ^ data[21] ^ data[22]
             ^ data[23];

      ecc[4] = data[4]  ^ data[5]  ^ data[6]  ^ data[7]  ^ data[8]  ^ data[9]
             ^ data[16] ^ data[17] ^ data[18] ^ data[19] ^ data[20] ^ data[22]
             ^ data[23];

      ecc[3] = data[1]  ^ data[2]  ^ data[3]  ^ data[7]  ^ data[8]  ^ data[9]
             ^ data[13] ^ data[14] ^ data[15] ^ data[19] ^ data[20] ^ data[21]
             ^ data[23];

      ecc[2] = data[0]  ^ data[2]  ^ data[3]  ^ data[5]  ^ data[6]  ^ data[9]
             ^ data[11] ^ data[12] ^ data[15] ^ data[18] ^ data[20] ^ data[21]
             ^ data[22];

      ecc[1] = data[0]  ^ data[1]  ^ data[3]  ^ data[4]  ^ data[6]  ^ data[8]
             ^ data[10] ^ data[12] ^ data[14] ^ data[17] ^ data[20] ^ data[21]
             ^ data[22] ^ data[23];

      ecc[0] = data[0]  ^ data[1]  ^ data[2]  ^ data[4]  ^ data[5]  ^ data[7]
             ^ data[10] ^ data[11] ^ data[13] ^ data[16] ^ data[20] ^ data[21]
             ^ data[22] ^ data[23];
   end
endmodule

module csi_rx_packet_handler #(
	parameter NUM_LANES = 2
)(
	input clock,
	input reset,
	input enable,
	input [15:0] data,
	input data_valid,
	output sync_wait,					//signal readiness to receive next packet				
	output packet_done,					//reset alignment status after packet
	output [15:0] payload_out,
	output payload_valid,
	output [7:0] good_checksum_cnt,	//for verification only
	output [7:0] bad_checksum_cnt		//for verification only	
);
	reg [2:0] state;
	reg is_hdr;
	reg [31:0] packet_data;
	reg [5:0] packet_type;
	reg [15:0] packet_len;
	reg [15:0] packet_len_q;
	reg [23:0] packet_for_ecc;
	reg long_packet;
	reg valid_packet;
	reg [15:0] bytes_read;
	reg long_packet_reg = 0; //for CRC
	
	wire is_allowed_type;
	//accepted data types can be added here, e.g. packet_type == 6'h2B for RAW10
	assign is_allowed_type = (|{packet_type == 6'h2A});	//2A is RAW8 data
	wire [7:0] expected_ecc;
	always @(*) begin
		is_hdr = ({data_valid, state} == 4'hD);
		packet_type = packet_data[5:0];
		packet_len = packet_data[23:8];
		packet_for_ecc = packet_data[23:0];
		valid_packet = ((packet_data[31:24] == expected_ecc) & is_allowed_type) & (packet_data[7:6] == 2'd0);
		long_packet = (packet_type > 6'h0F) & valid_packet;
	end
	csi_rx_hdr_ecc u_ecc(
		.data(packet_for_ecc),
		.ecc(expected_ecc)
	);
	
	always @(posedge clock or posedge reset) begin
		if (reset == 1'b1) begin
			state <= 3'd0;
			bytes_read <= 1'b0;
			packet_data <= 1'b0;
			packet_len_q <= 1'b0;
			checksum_calc_hold <= 16'd0;
			checksum_rx <= 16'd0;
		end
		else if (enable == 1'b1) begin
			packet_data <= {data, packet_data[31:16]};
			(* full_case, parallel_case *)
			case (state)
				3'd0: state <= 3'd1;
				3'd1: begin
					bytes_read <= 1'b0;
					if (data_valid == 1'b1)
						state <= 3'd6;
				end
				3'd6: begin
					state <= 3'd5;
				end
				3'd5: begin
					packet_len_q <= packet_len;
					if (long_packet == 1'b0)
						state <= 3'd3;
					else
						state <= 3'd7;
				end
				3'd7: state <= 3'd2;
				3'd2:
					if ((bytes_read < (packet_len_q - (16'd1 * NUM_LANES))) && (bytes_read < 16'd8192))
						bytes_read <= bytes_read + (16'd1 * NUM_LANES);
					else
						state <= 3'd3;
				3'd3: begin
					state <= 3'd4;
					if (long_packet_reg) begin
						checksum_calc_hold <= checksum_calc;
						checksum_rx <= packet_data[0+:16]; 
					end
				end
				3'd4: state <= 3'd1;
				default: state <= 3'd0;
			endcase
		end
	end 
	
	assign sync_wait = (state == 3'd1);
	assign payload_out = (state == 3'd2 ? packet_data[0+:16] : {16 {1'b0}});
	assign packet_done = (state == 3'd3);
	assign payload_valid = (state == 3'd2);	
	
	//for CRC handling (not required for data reception)
	reg [15:0] checksum_rx = 0;
	wire lfsr_rst;
	assign lfsr_rst = (state == 3'd4) | reset;
	wire[15:0] checksum_calc;
	reg[15:0] checksum_calc_hold = 0;
	
	reg[7:0] good_checksum_count = 0;
	reg[7:0] bad_checksum_count = 0;
	assign bad_checksum_cnt = bad_checksum_count; // checksum_calc_hold;
	assign good_checksum_cnt = good_checksum_count; //checksum_rx;
	
	lfsr_crc#(
		.LFSR_WIDTH(16),
		.LFSR_POLY(16'h1021),
		.LFSR_INIT(16'hFFFF),
		.LFSR_CONFIG("GALOIS"),
		.REVERSE(1),
		.INVERT(0),
		.DATA_WIDTH(16),
		.STYLE("AUTO")
	) crc_inst (
		.clk(clock),
		.rst(lfsr_rst),
		.data_in(payload_out),
		.data_in_valid(payload_valid),
		.crc_out(checksum_calc)
	);
	
	//this should be sufficient to count the nunmber of received packets
	always@(posedge lfsr_rst or posedge reset) begin
		if (reset) begin
			bad_checksum_count <= 0;
			good_checksum_count <= 0;
		end
		else begin
			if (long_packet_reg) begin
				if (checksum_rx != checksum_calc_hold) bad_checksum_count <= bad_checksum_count +1;
				else good_checksum_count <= good_checksum_count +1;
			end
		end
	end
	
    always@(posedge clock or posedge reset) begin
		if (reset == 1'b1) begin
			long_packet_reg <= 0;
		end
		else begin
			if (state == 3'd1) long_packet_reg <= 0; 
			else if (long_packet) long_packet_reg <= 1;
		end
    end
endmodule
