`timescale 1ns / 1ps

`define RAW8

module csi_rx_iserdes (
    input wire bit_clk,
    input wire byte_clk,
    input wire rst,
    input wire [1:0] ddr_i,
    output reg [7:0] byte_o
);
    reg [7:0] s0 = 0, s1 = 0, s2 = 0;
    (*keep*)
	always @(posedge bit_clk or posedge rst) begin
        if (rst) begin
            s0 <= 0;
            s1 <= 0;
            s2 <= 0;
        end else begin
            s0 <= {ddr_i[1], ddr_i[0], s0[7:2]};
            s1 <= s0;
            s2 <= s1;
        end
    end
    always @(posedge byte_clk or posedge rst) begin
        if (rst)
            byte_o <= 0;
        else
            byte_o <= s2;
    end
endmodule

module csi_rx_ck #(
    parameter ONCHIP_RTERM_EN = 0,
    parameter IDELAY = 4'h0
)(
    input wire [1:0] dphy_ck_hs,
	input wire rst,

    output hs_bit_clk, // ddr bit clock  = dphy_ck_hs
    output reg hs_byte_clk // sdr byte clock = dphy_ck_hs/4
);
    (* clkbuf_inhibit *)
    wire ddr_ck;

    CC_LVDS_IBUF #(
        .LVDS_RTERM(ONCHIP_RTERM_EN),
        .DELAY_IBF(IDELAY)
    ) dphy_ck_ibuf (
        .I_P (dphy_ck_hs[0]),
        .I_N (dphy_ck_hs[1]),
        .Y   (ddr_ck)
    );

    // Output the clock only when enable is set
    assign hs_bit_clk = ddr_ck; // enable ? ddr_ck : 0;
    reg [1:0] div = 2'b00;

    always @(posedge hs_bit_clk or posedge rst) begin
		if (rst) begin
			div <= 0;
			hs_byte_clk <= 0;
		end
		else begin
			div <= div + 1'b1;
			if (div == 2) begin
				hs_byte_clk <= ~hs_byte_clk;
				div <= 1;
			end
		end
    end
endmodule

module csi_rx_dn #(
    parameter ONCHIP_RTERM_EN = 0,
    parameter IDELAY = 4'h0,
    parameter SWAP_D = 1'b0,
    parameter INV_CK = 1'b0
)(
    input wire rst,
    input wire [1:0] dphy_dn_hs,
    input wire bit_clk,
    input wire byte_clk,
	
    output wire [7:0] recvd_byte
);
    wire dphy_dn;
    wire [1:0] ddr_dn_q;

    CC_LVDS_IBUF #(
        .LVDS_RTERM(ONCHIP_RTERM_EN),
        .DELAY_IBF(IDELAY)
    ) dphy_dn_ibuf (
        .I_P (dphy_dn_hs[0]),
        .I_N (dphy_dn_hs[1]),
        .Y   (dphy_dn)
    );

    CC_IDDR #(
        .CLK_INV(INV_CK)
    ) iddr_dn (
        .D   (dphy_dn),
        .CLK (bit_clk),
        .Q0  (ddr_dn_q[0]),
        .Q1  (ddr_dn_q[1])
    );

    csi_rx_iserdes iserdes_dn (
        .bit_clk(bit_clk),
        .byte_clk(byte_clk),
        .rst(rst),
        .ddr_i({ddr_dn_q[1], ddr_dn_q[0]}),
        .byte_o(recvd_byte)
    );

endmodule  

module csi_rx_top #(
    parameter ONCHIP_RTERM_EN = 0,
    parameter IDELAY_CK = 4'h0,	//clock input delay
    parameter IDELAY_DN = 4'h0,	//data input delay
    parameter NUM_LANES = 2, // only 2 lanes supported
    parameter NUM_RAW = 8 // only RAW8 supported
)(
    input enable,
	input reset,
    input [1:0] dphy_ck_hs,
    input [1:0] dphy_d0_hs,
    input [1:0] dphy_d1_hs,

    output f0, f1,	 //show when sync sequence is found (for debugging)

    output csi_byte_clk,
    output [(NUM_LANES*NUM_RAW)-1:0] csi_raw_data,
	output csi_raw_valid,
	output [7:0] csi_checksum_good, //good checksum count for debug
	output [7:0] csi_checksum_err   //bad checksum count for debug
);
    wire csi_bit_clk, lp_clk;
	wire csi_rst;
    wire dphy_d0, dphy_d1;
    wire [1:0] ddr_d0_q, ddr_d1_q;

	assign csi_rst = reset;

    csi_rx_ck #(
        .ONCHIP_RTERM_EN(ONCHIP_RTERM_EN),
        .IDELAY(IDELAY_CK)
    ) ck_inst (
        .dphy_ck_hs(dphy_ck_hs),
		.rst(csi_rst),
        .hs_bit_clk(csi_bit_clk),
        .hs_byte_clk(csi_byte_clk)
    );

    wire wait_for_sync, byte_packet_done, packet_done;

    wire [7:0] d1_byte, d0_byte;

    csi_rx_dn #(
        .ONCHIP_RTERM_EN(ONCHIP_RTERM_EN),
        .IDELAY(IDELAY_DN),	
        .INV_CK(0),
        .SWAP_D(0) // swap pair
    ) d0_inst (
        .rst(csi_rst),
        .dphy_dn_hs(dphy_d0_hs),
        .bit_clk(csi_bit_clk),
        .byte_clk(csi_byte_clk),
        .recvd_byte(d0_byte)
    );

    csi_rx_dn #(
        .ONCHIP_RTERM_EN(ONCHIP_RTERM_EN),
        .IDELAY(IDELAY_DN),	
        .INV_CK(0),
        .SWAP_D(0) // swap pair
    ) d1_inst (
        .rst(csi_rst),
        .dphy_dn_hs(dphy_d1_hs),
        .bit_clk(csi_bit_clk),
        .byte_clk(csi_byte_clk),
        .recvd_byte(d1_byte)
    );

    wire [NUM_LANES-1:0] byte_valid;
    wire [(NUM_LANES*8)-1:0] byte_align_data;

    csi_rx_align_byte d0_align_byte_inst (
        .clock           (csi_byte_clk),
        .reset           (csi_rst),
        .enable          (enable),
        .deser_in        (d0_byte),
        .wait_for_sync   (wait_for_sync),
        .packet_done     (byte_packet_done),
        .found(f0),
        .data_out        (byte_align_data[7:0]),
        .data_vld        (byte_valid[0])
    );

    csi_rx_align_byte d1_align_byte_inst (
        .clock           (csi_byte_clk),
        .reset           (csi_rst),
        .enable          (enable),
        .deser_in        (d1_byte),
        .wait_for_sync   (wait_for_sync),
        .packet_done     (byte_packet_done),
        .found(f1),
        .data_out        (byte_align_data[15:8]),
        .data_vld        (byte_valid[1])
    );

    wire [(NUM_LANES*8)-1:0] word_data;
	wire word_valid;

    csi_rx_align_word #(
        .NUM_LANES(NUM_LANES)
    ) align_word_inst (
        .byte_clock      (csi_byte_clk),
        .reset           (csi_rst),
        .enable          (enable),

        .packet_done     (packet_done),
        .wait_for_sync   (wait_for_sync),
        .word_in         (byte_align_data),
        .valid_in        (byte_valid),

        .packet_done_out (byte_packet_done),
        .word_out        (word_data),
        .valid_out       (word_valid)
    );

	wire csi_sync_seq;
    wire [(NUM_LANES*8)-1:0] csi_unpack_dat;
    wire csi_unpack_dat_vld;
	assign csi_raw_data  = csi_unpack_dat;
    assign csi_raw_valid = csi_unpack_dat_vld;
    
	csi_rx_packet_handler depacket_inst (
        .clock           (csi_byte_clk),
        .reset           (csi_rst),
        .enable          (enable),

        .data            (word_data),
        .data_valid      (word_valid),

        .sync_wait       (wait_for_sync),
        .packet_done     (packet_done),
        .payload_out     (csi_unpack_dat),
        .payload_valid   (csi_unpack_dat_vld),
		
		.good_checksum_cnt	 (csi_checksum_good),
		.bad_checksum_cnt	 (csi_checksum_err)
    );
	//HIER MUSS ICH AUCH NOCHMAL SCHAUEN OB ICH DAS NICHT RAUSWERFE...
	//ABER EFFEKTIV MACHT DAS HALT EINFACH NIX, WENN DER PARAMETER STIMMT
    /*generate
        if (NUM_RAW == 8) begin
            
        end
        else if (NUM_RAW == 10) begin
            csi_rx_10bit_unpack unpack10_inst (
                .clock           (csi_byte_clk),
                .reset           (csi_rst),
                .enable          (enable),
                .data_in         (csi_unpack_dat),
                .din_valid       (csi_unpack_dat_vld),
                .data_out        (csi_raw_data),
                .dout_valid      (csi_raw_valid)
            );
        end
        else begin // NUM_RAW == 12
            csi_rx_12bit_unpack unpack12_inst (
                .clock           (csi_byte_clk),
                .reset           (csi_rst),
                .enable          (enable),
                .data_in         (csi_unpack_dat),
                .din_valid       (csi_unpack_dat_vld),
                .data_out        (csi_raw_data),
                .dout_valid      (csi_raw_valid)
            );
        end
    endgenerate*/

endmodule
