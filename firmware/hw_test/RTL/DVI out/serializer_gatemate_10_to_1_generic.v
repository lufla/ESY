/*
 * serializer_gamtemate_10_to_1_generic_ddr.v
 *
 * Copyright (C) 2022  Gwenhael Goavec-Merou <gwenhael.goavec-merou@trabucayre.com>
 * SPDX-License-Identifier: MIT
 *
 * Edited by Sven Krause 2025
 */

module serializer_gatemate_10_to_1_generic (
	input  wire       ref_clk_i,  // reference clock
	input  wire       fast_clk_i, // must be ref_clk frequency x (n / 2)
	input  wire       rst,
	input  wire [9:0] dat_i,
	output wire       dat_o
);
	//detect ref_clk_i edge 
	reg ref_clk_i_d, ref_clk_i_s;
	reg ref_clk_i_edge;
	
	always @(posedge ref_clk_i)
		ref_clk_i_s <= (rst) ? 1'b0 : !ref_clk_i_s;

	always @(posedge fast_clk_i) begin
		ref_clk_i_d <= ref_clk_i_s;
		ref_clk_i_edge <= ref_clk_i_d ^ ref_clk_i_s;
	end

	reg [4:0] dat_pos_even;
	reg [4:0] dat_pos_odd;
	wire[4:0] evens;
	wire[4:0] odds;
	
	assign evens = {dat_i[8], dat_i[6], dat_i[4], dat_i[2], dat_i[0]};
	assign odds = {dat_i[9], dat_i[7], dat_i[5], dat_i[3], dat_i[1]};
	(*keep*)
	always @(posedge fast_clk_i) begin
		if (ref_clk_i_edge) begin
			dat_pos_even <= evens;
			dat_pos_odd <= odds;
		end
		else begin
			dat_pos_even <= {1'b0, dat_pos_even[4:1]};
			dat_pos_odd <=  {1'b0, dat_pos_odd[4:1]};
		end	
	end
	
	CC_ODDR #(
		.CLK_INV(1'b0)
	) ddr_inst (.CLK(fast_clk_i), .DDR(fast_clk_i),
		.D0(dat_pos_odd[0]), .D1(dat_pos_even[0]),
		.Q(dat_o)
	);

endmodule
