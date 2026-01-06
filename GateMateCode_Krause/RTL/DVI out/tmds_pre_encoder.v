module tmds_pre_encoder(
	input [7:0] i_data,
	output [8:0] qm_o
);
/* generate xor and xnor representation */
	wire [8:0] dat_xor_s, dat_xnor_s;
	assign dat_xor_s[0] = i_data[0];
	assign dat_xnor_s[0] = i_data[0];
	assign dat_xor_s[8] = 1'b1;
	assign dat_xnor_s[8] = 1'b0;
	genvar l_inst;
	generate
	for (l_inst = 1; l_inst < 8; l_inst = l_inst + 1) begin
		assign dat_xor_s[l_inst]  = i_data[l_inst] ^ dat_xor_s[l_inst-1];
		assign dat_xnor_s[l_inst] = ~(i_data[l_inst] ^ dat_xnor_s[l_inst-1]);
	end
	endgenerate	
	
	/* determine bit high count */
	wire [3:0] N1_in = i_data[0] + i_data[1] + i_data[2] + i_data[3] +
					i_data[4] + i_data[5] + i_data[6] + i_data[7];

	wire [8:0] q_m = (N1_in > 4 || (N1_in == 4 && i_data[0] == 0))?dat_xnor_s : dat_xor_s;
	
	assign qm_o = q_m;
	
	endmodule