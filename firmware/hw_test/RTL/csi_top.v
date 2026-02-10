`timescale 1ns / 1ps

module csi_top #(
    parameter NUM_LANES = 2,
    parameter NUM_RAW = 8
)(
    input  clk_ext,
	
	input [2:0] BUTTON,

	output reg [7:0] LED
    
);

    wire rst_ref_n;

    clkrst_gen clkrst_gen_inst (
      .clk_ref   (clk_ext),
      .rst_ref_n (rst_ref_n)
    );
	
	localparam integer COUNT_MAX = 5000000 -1;
	
	reg [21:0] counter = 0;
	reg [7:0] led_count = 0;

	wire btn1;

	CC_IBUF #(
		.PULLUP (1)
	) buttbuff (
		.I (BUTTON[0]),
		.Y (btn1)
	);

always  @(posedge clk_ext)
begin
	if (!rst_ref_n) begin
		counter <= 0;
		led_count <= 0;
		//LED <= 8'b0;
	end else begin
		if (counter >= COUNT_MAX) begin
			counter <= 0;
			led_count <= led_count + 1;
			//LED <= led_count + 1;
		end else begin
			counter <= counter + 1;
		end
	end
end

always @(posedge clk_ext)
begin
	if (btn1 == 1'b1) begin
		LED <= 8'b0;
	end else begin
		LED <= 8'b1;
	end
end


  

endmodule
