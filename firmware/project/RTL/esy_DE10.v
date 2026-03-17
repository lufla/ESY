`timescale 1ns/1ps


module esy_DE10 (
	input csi_clk,
	input clk,
	input rst_n,
	input [15:0] data_in,
	input data_avail,
	
	output ext_clk,
	output [31:0] data_out,
	output data_valid
	);

	wire clk125;
	wire rst_n_n;
	
	assign rst_n_n = ~rst_n;
	
	CC_PLL #(
		.REF_CLK(25.0),
		.OUT_CLK(125.0),
		.LOW_JITTER(1),
		.LOCK_REQ(0),
		.CLK270_DOUB(0),
		.CLK180_DOUB(0)
	) pll_inst (
		.CLK_REF(clk),
		.USR_CLK_REF(1'b0),
		.CLK_FEEDBACK(1'b0),
		.USR_LOCKED_STDY_RST(rst_n_n),
		.USR_PLL_LOCKED_STDY(),
		.USR_PLL_LOCKED(),
		.CLK0(clk125),
		.CLK90(),
		.CLK180(ext_clk),
		.CLK270(),
		.CLK_REF_OUT()
	);
	
	wire fifo_we;		// write_enable fifo
	wire fifo_re;		// read_enable fifo
	wire [39:0] fifo_buff;
	wire [39:0] fifo_outbuff;
	wire fifo_empty;

	// This module implements a FIFO memory as a buffer between receiving data and sending it out.
	CC_FIFO_40K #(
		.FIFO_MODE("ASYNC"),
		.A_WIDTH(40),
		.B_WIDTH(40)
	) esy_fifo (
		.A_DO(fifo_outbuff),						// connect to output
		.B_DI(fifo_buff),						// connect to CSI-2
		.A_CLK(clk125),
		.B_CLK(csi_byte_clk),						// PLL??
		.A_EN(fifo_re),
		.A_BM(40'hFF_FF_FF_FF_00),
		.B_EN(fifo_we),
		.B_BM(40'hFF_FF_FF_FF_00),
		.F_RST_N(rst_ref_n),
		.F_EMPTY(fifo_empty)
	);
	
	wire two_bytes;

	// two 16-bit values are buffered from CSI-2 and then written to FIFO
	always@(posedge csi_byte_clk) begin
		if (rst_ref_n == 0) begin
			two_bytes <= 0;
			fifo_we <= 0;
			fifo_buff <= 40'h00_00_00_00_00;
		end else begin
			if (two_bytes == 0 && csi_raw_valid == 1) begin
				fifo_buff [15:0] <= csi_raw_data;
				two_bytes <= 1;
				fifo_we <= 0;
			end else if (two_bytes == 1 && csi_raw_valid == 1) begin
				fifo_buff [31:0] <= csi_raw_data;
				two_bytes <= 0;
				fifo_we <= 1;
			end else begin
				fifo_we <= 0;
			end
		end
	end

	
	always@(posedge clk125) begin
		if (rst_n == 0) begin
			data_out [31:0] <= 32'hFF_FF_FF_FF;
			data_valid <= 0;
		end else begin
			if (fifo_empty != 0) begin
				data_out <= fifo_outbuff[31:0];
				data_valid <= 1;
				fifo_re <= 1;
			end else begin
				data_valid <= 0;
				fifo_re <= 0;
			end
		end
	end
endmodule