`timescale 1ns / 1ps

module esy_top #(
    parameter NUM_LANES = 2,
    parameter NUM_RAW = 8
)(
    input  clk_ext,

    // CSI-2 RX Interface
    input  DPHY_CK_HS_N, DPHY_CK_HS_P,
    //input  DPHY_CK_LP_N, DPHY_CK_LP_P,
    input  DPHY_D0_HS_N, DPHY_D0_HS_P,
    //input  DPHY_D0_LP_N, DPHY_D0_LP_P,
    input  DPHY_D1_HS_N, DPHY_D1_HS_P,
    //input  DPHY_D1_LP_N, DPHY_D1_LP_P,
    inout  DPHY_CCI_SCL, DPHY_CCI_SDA,

    // TMDS Video Interface
    output TMDS_CK_P, TMDS_CK_N,
    output TMDS_D0_P, TMDS_D0_N,
    output TMDS_D1_P, TMDS_D1_N,
    output TMDS_D2_P, TMDS_D2_N,
	
	// User LEDs, former PMODC
	output [7:0] LED,

	output [31:0] DATA,
	output DATA_CLK,
	output DATA_VALID
);
    wire f0, f1;
	
    //assign PMODA = {6'b0, f1, f0, 1'b0, csi_byte_clk};
    //assign PMODB = csi_checksum_good[7:0];
    //assign PMODC = {5'b0, checksum_err_seen ,i2c_done, csi_raw_valid};
    //assign PMODD = csi_checksum_err[7:0];

    wire rst_ref_n, rst_csi;
	assign rst_csi = ~rst_ref_n;
	
	assign LED = 8'b00000000;
	assign TMDS_CK_P = 0;
	assign TMDS_CK_N = 0;
	assign TMDS_D0_P = 0;
	assign TMDS_D0_N = 0;
	assign TMDS_D1_P = 0;
	assign TMDS_D1_N = 0;
	assign TMDS_D2_P = 0;
	assign TMDS_D2_N = 0;

	// generates an internal reset pulse after power up
    clkrst_gen clkrst_gen_inst (
      .clk_ref   (clk_ext),
      .rst_ref_n (rst_ref_n)
    );

	wire init_done;
	wire init_error;
    wire i2c_done;	//this is used as an enable for the csi rx
	wire i2c_error;
	
	assign i2c_done = !init_done; //required because flags from CCI_Handler use negative logic
	assign i2c_error = !init_error; 
	
	// Module to handle the I²C communication with the camera
	CCI_Handler CCI (
		.clk(clk_ext),	
		.RST_N(rst_ref_n),
		.I2C_SCL(DPHY_CCI_SCL),
		.I2C_SDA(DPHY_CCI_SDA),
		.init_done(init_done),
		.init_error(init_error)
	);

    wire csi_byte_clk;
    wire csi_raw_valid;
    wire [(NUM_LANES*NUM_RAW)-1:0] csi_raw_data;
	wire [7:0] csi_checksum_err;
	wire [7:0] csi_checksum_good;
	reg checksum_err_seen = 0;
	//debug code for the CRC
	always@(posedge csi_byte_clk) begin
		if (csi_checksum_err != 0) checksum_err_seen <= 1;				
		//else checksum_err_seen <= 0;
	end
	
	// This module is responsible for the reception of picture data from the camera
    csi_rx_top #(
        .ONCHIP_RTERM_EN(0),
        .IDELAY_CK(4'h0), // CK_HS_{P,N} input delay
        .IDELAY_DN(4'h0), // D{0,1}_HS_{P,N} input delay for skew compensation
        .NUM_LANES(NUM_LANES),
        .NUM_RAW(NUM_RAW)
    ) csi_rx_inst (
`ifdef IVERILOG
        .enable        (1'b1),
`else
        .enable        (i2c_done),
`endif
		.reset		   (rst_csi),

        .dphy_ck_hs    ({DPHY_CK_HS_N, DPHY_CK_HS_P}),
        .dphy_d0_hs    ({DPHY_D0_HS_N, DPHY_D0_HS_P}),
        .dphy_d1_hs    ({DPHY_D1_HS_N, DPHY_D1_HS_P}),

        .f0(f0), .f1(f1),
		 
        .csi_byte_clk  (csi_byte_clk),
        .csi_raw_valid (csi_raw_valid),
        .csi_raw_data  (csi_raw_data),
        
		.csi_checksum_good (csi_checksum_good),
		.csi_checksum_err (csi_checksum_err)
    );		
  
	// This module implements the data buffering and generation
	// of output signals
	esy_DE10 output_inst(
		.csi_clk(csi_byte_clk),
		.clk(clk_ext),
		.rst_n(rst_ref_n),
		.data_in(csi_raw_data),
		.data_avail(csi_raw_valid),
		.ext_clk(DATA_CLK),
		.data_out(DATA),
		.data_valid(DATA_VALID),
	);


























// old stuff, should be deleted


    // wire rgb_valid;
    // wire pixel_request;
	// wire [23:0] rgb_pix;
	// wire TMDS_clk;
	// wire[2:0] TMDS_data;
	// wire pix_clk;

// RAM_buffer test_buffer (
	// .clk_a (csi_byte_clk),
	// .clk_b (pix_clk),
	// .rst_n (rst_ref_n),
	// .data_in (csi_raw_data),
	// .data_in_valid (csi_raw_valid),
	// .data_request(pixel_request),
	// .data_out_valid(rgb_valid),
	// .data_out(rgb_pix)
// );	

// esy_control top_fsm(
	// .clk (clk_ext),
	// .rst_n (rst_ref_n),
	// .fifo_enable (enable_fifo),
	
// );


//This part is for a HDMI output
// video_output_ctrl DVI_OUT(
	// .clk_ref (clk_ext),
	// .RST_N(rst_ref_n),
	// .RGB_data_in(rgb_pix),
	// .RGB_in_valid(rgb_valid),
	
	// .clk_pix_out(pix_clk),
	// .pixel_request(pixel_request),
	// .TMDS_clk(TMDS_clk),
	// .TMDS_data(TMDS_data)
// );
//  Output buffers for DVI out
  // CC_LVDS_OBUF #(
		// .LVDS_BOOST(1),
		// .DELAY_OBF(0),
	// ) lvds_ck_obuf_inst (
		// .A(TMDS_clk),
		// .O_N(TMDS_CK_N),
		// .O_P(TMDS_CK_P)
	// );

	// CC_LVDS_OBUF #(
		// .LVDS_BOOST(1),
		// .DELAY_OBF(0),
	// ) lvds_dn_obuf_inst_0 (
		// .A(TMDS_data[0]),
		// .O_N(TMDS_D0_N),
		// .O_P(TMDS_D0_P)
	// );
  	// CC_LVDS_OBUF #(
		// .LVDS_BOOST(1),
		// .DELAY_OBF(0),
	// ) lvds_dn_obuf_inst_1 (
		// .A(TMDS_data[1]),
		// .O_N(TMDS_D1_N),
		// .O_P(TMDS_D1_P)
	// );
	// CC_LVDS_OBUF #(
		// .LVDS_BOOST(1),
		// .DELAY_OBF(0),
	// ) lvds_dn_obuf_inst_2 (
		// .A(TMDS_data[2]),
		// .O_N(TMDS_D2_N),
		// .O_P(TMDS_D2_P)
	// );

endmodule
