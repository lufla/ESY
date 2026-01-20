`timescale 1ns / 1ps
/*****************************************************************
This module handles the control of the video output and bundles
all related sub-modules. This also includes the generation of the
pixel- and bit-clocks for the video output and the colour
correction.   
*****************************************************************/
module video_output_ctrl (
	input clk_ref,
	input RST_N,
	input[23:0] RGB_data_in,
	input RGB_in_valid,
	
	output clk_pix_out,
	output pixel_request,
	output TMDS_clk,
	output[2:0] TMDS_data
);	
	
    wire[8:0] r_qm, g_qm, b_qm;
    wire de_s, hsync_s, vsync_s;
    wire rst;
    wire [8:0] v_count;
	wire [9:0] h_count;
	reg soft_rst = 0;
	assign rst = (soft_rst | !RST_N);
	//very basic synchronisation with input at startup
	reg startup_hold = 0;
	//Registers for timing. Delays the input to the  dvi core
	reg [8:0] qm_r, qm_g, qm_b;
	reg v_sync = 1;	//initialize with 1 for negative sync polarity
	reg h_sync = 1;	//see above
	reg de_reg = 0;
	
	assign pixel_request = de_s;	//very basic, but it seems to work
	
	wire[23:0] RGB_data_cor;
	wire rgb_out_vld;
	
	color_balance #(
		.INT_GAIN_RED(4'h6),	//multiplier red 
		.INT_GAIN_GREEN(4'h4),	//multiplier green (8 is neutral for shift of 3)
		.INT_GAIN_BLUE(4'h6),	//multiplier blue 
		.SHIFT_DIV(2'h2)		//# of bits to shift initial values by 
	) color_correct (
		.clk(clk_pix),
		.rgb_in(RGB_data_in),
		.rgb_in_valid(RGB_in_valid),
		.rgb_out(RGB_data_cor),
		.rgb_out_valid(rgb_out_vld)
	);
	
	tmds_pre_encoder pre_encod_r(
		.i_data(RGB_data_cor[23:16]),
		.qm_o(r_qm)
	);
	tmds_pre_encoder pre_encod_g(
		.i_data(RGB_data_cor[15:8]),
		.qm_o(g_qm)
	);
	tmds_pre_encoder pre_encod_b(
		.i_data(RGB_data_cor[7:0]),
		.qm_o(b_qm)
	);
	
	/* PLL: 25MHz (pix clock) and 125MHz (hdmi clk rate) */
	wire clk_pix, clk_dvi, lock;
	pll pll_inst (
		.clock_in(clk_ref),       //  50 MHz reference
		.clock_out(clk_pix),    //  25 MHz, 0 deg
		.clock_5x_out(clk_dvi), // 125 MHz, 0 deg
		.lock_out(lock)
	);

	assign clk_pix_out = clk_pix;
	localparam
		HRES = 640,
		HSZ  = $clog2(HRES),
		VRES = 480,
		VSZ  = $clog2(VRES);

   vga_core #(
		.HSZ(HSZ), .VSZ(VSZ)
	) vga_inst (.clk_i(clk_pix), .rst_i (rst),
		.hcount_o(h_count), .vcount_o(v_count),
		.de_o(de_s),
		.vsync_o(vsync_s), .hsync_o(hsync_s)
	);

	dvi_core dvi_inst (
		.clk_pix(clk_pix), .rst(rst), .clk_dvi(clk_dvi),
		// horizontal & vertical synchro
		.hsync_i(hsync_s), .vsync_i(vsync_s),
		// display enable (active area)
		.de_i(de_s),
		//pre-encoding signals
		.qm_r(qm_r), .qm_g(qm_g), .qm_b(qm_b),
		// output signals
		.TMDS_clk(TMDS_clk),
		.TMDS_data(TMDS_data)
	);

always@(posedge clk_pix) begin
	if (RST_N && startup_hold) begin			
		//Assigning the preprocessed image data to the registers
		qm_r <= r_qm;
		qm_g <= g_qm;
		qm_b <= b_qm;
		
		v_sync <= vsync_s;
		h_sync <= hsync_s;
		de_reg <= de_s;
	end	//end of run condition
	else begin //reset routine
		soft_rst <= 1;
		v_sync <= 1;
		h_sync <= 1;
		de_reg <= 0;
		if (RGB_in_valid) begin
			startup_hold <= 1;
			soft_rst <= 0;
		end
	end
end

endmodule