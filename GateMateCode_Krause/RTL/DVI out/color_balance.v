`timescale 1ns / 1ps
/*************************************************************************** 
This is a crude implementation of static white balancing for rgb image data.
The idea is to enable multiplication by fractional factors using integer 
numbers by first dividing the values via a bit-shift operation,then 
multiplying the result by an integer number. 
***************************************************************************/

module color_balance #(
	parameter INT_GAIN_RED = 4'd4,
	parameter INT_GAIN_GREEN = 4'd4,
	parameter INT_GAIN_BLUE = 4'd4,
	parameter SHIFT_DIV = 2'd2
 )(
	input clk,
	input [23:0] rgb_in,
	input rgb_in_valid,
	output reg [23:0] rgb_out,
	output reg rgb_out_valid
);
	reg valid_in_reg;	//this is used to delay the incoming valid signal
	wire[8:0] pre_red, pre_green, pre_blue;
	wire [7:0] red, green, blue;

	assign pre_red = (rgb_in[23:16] >> SHIFT_DIV) * INT_GAIN_RED;
	assign pre_green = (rgb_in[15:8] >> SHIFT_DIV) * INT_GAIN_GREEN;
	assign pre_blue = (rgb_in[7:0] >> SHIFT_DIV) * INT_GAIN_BLUE;
	
	assign red = (pre_red[8]) ? 8'hFF : pre_red;
	assign green = (pre_green[8]) ? 8'hFF : pre_green;
	assign blue = (pre_blue[8]) ? 8'hFF : pre_blue;
	
	always@(posedge clk) begin
		valid_in_reg <= rgb_in_valid;
		if (valid_in_reg) begin
			rgb_out <= {red, green, blue};
			rgb_out_valid <= 1;
		end
		else begin
			rgb_out <= 24'd0;
			rgb_out_valid <= 0;
		end		
	end
endmodule