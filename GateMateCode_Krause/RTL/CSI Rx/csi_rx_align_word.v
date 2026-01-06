//------------------------------------------------------------------------
// Description: This modules receives aligned bytes with their valid flags
// to then COMPENSATE FOR UP TO 2 CLOCK CYCLES OF SKEW BETWEEN LANES.
//
// It also resets byte aligners' sync status (via 'packet_done_out')
// when SYNC pattern is not found by the byte aligners on all lanes.
//
// Similarly to the byte aligner, it locks (latches) the alignment
// taps when a valid word is found and until 'packet_done' is asserted.
//
// It also effectively filters out the 0xB8 sync bytes from output data.
//------------------------------------------------------------------------
//
// Here is an illustration for the 2-lane case with 2-clock-cycle skew
// between lanes. This RTL is written to work for any number of lanes.
//
//    clk            | 1 | 2 |         |n-1| n |
//                   |___|___|_________|   |   |
//    lane0 vld_in __|                 |_____________
//          data_in  |<===============>
//                   |
//                   |<--2-->|_________________
//    lane1 vld_in __________|                 |_____
//          data_in           <===============>
//                   |   |   |
//    taps           0   1   2
//                            _________
//    valid_in_all __________|         |_____________
//
// In this case, taps[0]=2, taps[1]=0, i.e. take:
//   - lane0 byte after 2-clock delay
//   - lane1 byte without any delay
//========================================================================

module csi_rx_align_word #(
	parameter NUM_LANES = 2
)(
   input         byte_clock,      // byte clock in
   input         reset,           // active-1 reset

   input         enable,          // active-1 enable
   input         packet_done,     // packet done input from packet handler entity
   input         wait_for_sync,   // whether or not to be looking for an alignment
   input  [(NUM_LANES*8)-1:0] word_in,         // unaligned word from the byte aligners
   input  [NUM_LANES-1:0]  valid_in,        // valid flags from byte aligners

   output	reg packet_done_out, // 'packet_done' output to byte aligners
   output  reg [(NUM_LANES*8)-1:0] word_out,        // aligned word out to packet handler
   output  reg valid_out        // goes high once alignment is valid: First word
);                               //  with 'valid_out=1' is the CSI packet header,
                                 //  i.e. the 0xB8 Sync byte is filtered out

// there is no need for Word alignment when we have only one byte
//--------------------------------
//`ifdef MIPI_1_LANE
//   assign packet_done_out = packet_done;
//   assign word_out        = word_in;
//   assign valid_out       = valid_in;
//`else
   reg [(NUM_LANES*8)-1:0] word_dly_1;
   reg [(NUM_LANES*8)-1:0] word_dly_2;
   reg [NUM_LANES-1:0]  valid_dly_1;
   reg [NUM_LANES-1:0]  valid_dly_2;
   reg [1:0] taps [0:NUM_LANES-1];
   reg   valid, valid_in_all;
   reg   is_triggered;
   reg [2:0] i = 0;
   always@* begin
      valid_in_all = &valid_in; // all input byte lanes must be valid
     // look for VLD on all three pipeline stages for at least one lane
      is_triggered = 1'b0;
      for (i = 0; i <= NUM_LANES-1; i++) begin
         if ({valid_in[i], valid_dly_1[i], valid_dly_2[i]} == 3'b111) begin
            is_triggered = 1'b1;
         end
      end
      packet_done_out =  packet_done
                      | (is_triggered & ~valid_in_all); //"invalid_start" error
   end

  always @(posedge byte_clock or posedge reset) begin
	if (reset == 1'b1) begin
		valid 		 <= 1'b0;
		valid_dly_1 <= 1'b0;
		valid_dly_2 <= 1'b0;
		word_dly_1  <= 0;
		word_dly_2  <= 0;
		valid_out 	 <= 1'b0;
	end
	else begin
		word_dly_1  <= word_in;
		word_dly_2  <= word_dly_1;
		valid_dly_1 <= valid_in;
		valid_dly_2 <= valid_dly_1;
		valid_out <= valid;
		if (enable == 1'b1) begin
			if ({valid_in_all, valid, wait_for_sync} == 3'b101) begin
				valid <= 1'b1;
				for ( i = 0; i <= NUM_LANES-1; i = i + 1) begin
					if (valid_dly_2[i] == 1'b1) begin
						taps[i] <= 2'd2;
					end
					else if (valid_dly_1[i] == 1'b1) begin
						taps[i] <= 2'd1;
					end
					else begin
						taps[i] <= 2'd0;
					end
				end
			end
			else if (packet_done == 1'b1) begin
				valid <= 1'b0;
			end
		end
	end
  end
   
   genvar j;
   generate
      for (j = 0; j <= NUM_LANES-1; j = j + 1) begin
         always @(posedge byte_clock) begin
            if (valid == 1'b1) begin
               case (taps[j])
                  2'd2   : word_out[((j+1)*8)-1:j*8] <= word_dly_2[((j+1)*8)-1:j*8];
                  2'd1   : word_out[((j+1)*8)-1:j*8] <= word_dly_1[((j+1)*8)-1:j*8];
                  default: word_out[((j+1)*8)-1:j*8] <= word_in   [((j+1)*8)-1:j*8];
               endcase
            end
         end
      end
   endgenerate

//`endif // !MIPI_1_LANE

endmodule
