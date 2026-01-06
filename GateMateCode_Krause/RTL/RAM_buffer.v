`timescale 1ns/1ps
// Dual Port RAM (NO_CHANGE)
module bram_dp_no_change #(
	parameter DATA_WIDTH=18,
	parameter ADDR_WIDTH=9
	)(
	input wire wea,
	input wire web,
	input wire clka,
	input wire clkb,
	input wire [DATA_WIDTH-1:0] dia,
	input wire [DATA_WIDTH-1:0] dib,
	input wire [ADDR_WIDTH-1:0] addra,
	input wire [ADDR_WIDTH-1:0] addrb,
	output reg [DATA_WIDTH-1:0] doa,
	output reg [DATA_WIDTH-1:0] dob
);
	localparam WORD = (DATA_WIDTH-1);
	localparam DEPTH = (2**ADDR_WIDTH-1);
	reg [WORD:0] memory [0:DEPTH];

always @(posedge clka) begin
	if (wea) begin
		memory[addra] <= dia;
	end else
	doa <= memory[addra];
end
always @(posedge clkb) begin
	if (web) begin
		memory[addrb] <= dib;
	end else
		dob <= memory[addrb];
	end
endmodule

/* RAM BUFFER concept:
	The idea is to basically sub-sample (is that the right word?) the frame and only store every second pixel
	Because of the bayer-pattern that means repeating a "store 2, skip 2" routine.
	Conveniently with 2 lane CSI-2 that means I can store every other 2 lane input.	
	
	This version is not particularly resilient when it comes to mismatch between input and output speeds.
	The error handling is currently based on decoupling input and output side as much as possible. For example,
	if the input stops, the same frame will be read indefinitely. Similarly, the write side does not care what
	happens on the read side. This way, at least "catastrophic" malfunctions are avoided.
*/

module RAM_buffer(
	input clk_a,
	input clk_b,
	input rst_n,
	input[15:0] data_in,
	input data_in_valid,
	input data_request,
	output data_out_valid,
	output [23:0] data_out
);

	localparam COLUMNS = 320; // half of 6*320 Columns is what goes into one RAM Block
	localparam LINES = 40;	//240/6 Lines, this equals the number of 20K RAM Blocks used
	localparam OS_INCREMENT = COLUMNS >> 1;
	localparam LINELENGTH = 2*COLUMNS;		//for output lines!

//always two columns written at once (green, blue or red, green)
//naming scheme: col for column, lin for line, cnt for counter, i for in, o for out
	reg[10:0] col_cnt_i = 0;
	reg[8:0] lin_cnt_i = 0;
	reg[9:0] col_cnt_o = 0;
	reg[8:0] lin_cnt_o = 0;
//flags
	reg data_available = 0; //this is used to determine when to start reading
//write control
	wire we_a;
	wire en_a, en_b; 
//combinatorial
	wire store_pixel;
	assign store_pixel = (col_cnt_i[0] == 0 & lin_cnt_i[1] == 0);
	assign en_b = (data_available & data_request);
	assign data_out_valid = data_available;
	assign we_a = data_in_valid & en_a; //always write when valid data available
	assign en_a = store_pixel;
//signals for rams, write side
	wire[15:0] wr_data_even, wr_data_odd;
	wire[9:0] wr_addr_even, wr_addr_odd;
	reg [2:0] block_lin_cnt = 0; //this counts the lines written to the current block 
	reg[6:0] wr_sel = 0;	//this denotes which pair of RAM blocks is currently used
    reg [9:0] wr_offset = 0;

//write control
	wire wr_odd_line;
	assign wr_odd_line = lin_cnt_i[0]; 
	assign wr_addr_even = (col_cnt_i >> 1) + wr_offset;
	assign wr_addr_odd = wr_addr_even; //always same adresses for either line
	assign wr_data_even = data_in;
	assign wr_data_odd = data_in;

//reset counters after every frame
/*Without the LP signals, detecting the stop state on the clock lane (after every frame)
  is more difficult. The continuous read clock is used to detect the absence of the
  write clock instead.*/
	wire write_rst_n;
	reg frame_rst_n = 1;
	assign write_rst_n = rst_n && frame_rst_n;
	reg[1:0] no_clk_a_cnt = 0;
	always @ (posedge clk_b or posedge clk_a) begin
		if (clk_a) begin
			no_clk_a_cnt <= 0;
			frame_rst_n <= 1;
		end
		else begin
			if (no_clk_a_cnt == 2'b11) begin
				frame_rst_n <= 0;
				no_clk_a_cnt <= 0;
			end
			else begin
				no_clk_a_cnt <= no_clk_a_cnt + 1'b1;
			end
		end
	end

//write side counter(s)
always@(posedge clk_a or negedge write_rst_n) begin
	if(write_rst_n) begin
		if(data_in_valid) begin
			col_cnt_i <= (col_cnt_i >= COLUMNS -1) ? 0 : col_cnt_i + 1;		//increment until COLUMNS-1, then reset to 0
			if (col_cnt_i >= COLUMNS-1) begin
				lin_cnt_i <= (lin_cnt_i == (12*LINES-1)) ? 0 : lin_cnt_i + 1;	//incrmement to LINES-1, then reset to 0
				if (wr_odd_line & (lin_cnt_i[1] == 0)) begin    				
					data_available <= 1;										//set data_available when 2 lines are written
                    block_lin_cnt <= block_lin_cnt + 1;							//increment lines in current ram block
                    wr_offset <= wr_offset + OS_INCREMENT;  					//increment addr offset after every odd line
				    if (block_lin_cnt == 5) begin
				        wr_sel <= (wr_sel == LINES/2-1) ? 0 : wr_sel +1;
                        wr_offset <= 0; 										//reset wr_addr offset
                        block_lin_cnt <= 0;
                    end
				end
			end
		end
		else begin //if data not valid
		end
	end	//end of run condition
	else begin	//reset routine
		col_cnt_i <= 0;
		lin_cnt_i <= 0;
		block_lin_cnt <= 0;
		wr_sel <= 0;
		wr_offset <= 0;
	end
end

//read control
	wire[15:0] rd_data_even [(LINES/2)-1:0];
	wire[15:0] rd_data_odd [(LINES/2)-1:0];
	wire [9:0] rd_addr_even, rd_addr_odd;
	reg[1:0] hold_lin = 0;		//counter to enable reading each line 4 times
	reg [6:0] rd_sel = 0;
	reg [3:0] ram_pos = 0; 	//which of the 6 lines is read from current block			
	reg [9:0] rd_offset = 0;
	assign data_out = {rd_data_even[rd_sel][7:0], 	//red
						rd_data_odd[rd_sel][7:0], 	//green
						rd_data_odd[rd_sel][15:8]};	//blue
	assign rd_addr_odd = (col_cnt_o >> 2) + rd_offset;	//rd_offset is multiple of LINELENGTH/2
	assign rd_addr_even = rd_addr_odd;

always@(posedge clk_b) begin
	if(rst_n) begin
		if (en_b) begin
			col_cnt_o <= (col_cnt_o == LINELENGTH-1) ? 0 : col_cnt_o + 1;
			if (col_cnt_o == LINELENGTH-1) begin
                lin_cnt_o <= (lin_cnt_o >= 12*LINES-1) ? 0 : lin_cnt_o + 1;
				hold_lin <= hold_lin +1;
				if (hold_lin == 2'd3) begin
					hold_lin <= 0;
					ram_pos <= ram_pos + 1;
					rd_offset <= rd_offset + OS_INCREMENT;	//increment addr offset
					if (ram_pos == 5) begin
						ram_pos <= 0;
						rd_sel <= (rd_sel == (LINES>>1)-1) ? 0 : rd_sel + 1;
						rd_offset <= 0;
					end
				end
			end
		end
		else begin
			//What shall happen here? Nothing?
		end
	end //end of run condition
	else begin //reset routine
		col_cnt_o <= 0;
		lin_cnt_o <= 0;
		rd_sel <= 0;
		rd_offset <= 0;
		ram_pos <= 0;
		hold_lin <= 0;
	end
end
//generate RAMs
generate
	genvar i;
		for(i = 0; i < (LINES/2); i = i + 1)
			begin : ram_generate
			
			bram_dp_no_change #(
				.DATA_WIDTH (16),
				.ADDR_WIDTH (10)
			) line_buf_even_i (
				.wea((wr_sel == i)&~wr_odd_line & we_a),
				.web(1'b0),
				.clka(clk_a),
				.clkb(clk_b),
				.dia(wr_data_even),
				.dib(),
				.addra(wr_addr_even),
				.addrb(rd_addr_even),
				.doa(),
				.dob(rd_data_even[i])
			);
	end
endgenerate

generate
	genvar j;
		for(j = 0; j < (LINES/2); j = j + 1)
			begin : ram_generate_1
			
			bram_dp_no_change #(
				.DATA_WIDTH (16),
				.ADDR_WIDTH (10)
			) line_buf_odd_j (
				.wea((wr_sel == j)&wr_odd_line & we_a),
				.web(1'b0),
				.clka(clk_a),
				.clkb(clk_b),
				.dia(wr_data_odd),
				.dib(),
				.addra(wr_addr_odd),
				.addrb(rd_addr_odd),
				.doa(),
				.dob(rd_data_odd[j])
			);
	end
endgenerate

endmodule