//------------------------------------------------------------------------
// Description: This modules receives raw, unaligned bytes (which could 
//  contain fragments of two bytes) from the SERDES and aligns them by 
//  looking for the standard D-PHY SYNC pattern.
//
//  When 'wait_for_sync=1', it will wait until it sees the valid header
//  at some alignment, at which point the found alignment is locked 
//  until 'packet_done=1' arrives.
//
//  'valid_data' is asserted as soon as the SYNC pattern is found. 
//  The next byte therefore contains the CSI packet header.
//
//  In reality, to avoid false triggers we must look for a valid SYNC 
//  pattern on all used lanes. If this does not occur, the word aligner 
//  (which is a seperate block), will assert 'packet_done' immediately.
//========================================================================

module csi_rx_align_byte (
   input         clock,         // byte clock in
   input         reset,         // active-1 reset
   input         enable,        // active-1 enable
   input   [7:0] deser_in,      // raw data from ISERDES
   input         wait_for_sync, // when 1, if sync not already found, look for it
   input         packet_done,   // drive 1 to reset synchronisation status

   output reg       found,
   output reg [7:0] data_out,      // aligned data out, typically delayed by 2 cycles
   output reg       data_vld       // goes 1 as soon as sync pattern is found
);                                  //  so data_out on next cycle contains header

//--------------------------------
   reg [7:0]  curr_byte;
   reg [7:0]  last_byte;
   reg [7:0]  shifted_byte;

   //logic        found;
   reg [2:0]  offset;
   reg [2:0]  data_offs;

   always @(posedge clock or posedge reset) begin
      if (reset == 1'b1) begin
         data_vld  <= 1'b0;
         data_offs <= 0;
      end
      else if (enable == 1'b1) begin
         curr_byte <= deser_in;
         last_byte <= curr_byte;
         data_out  <= shifted_byte;
         if (packet_done == 1'b1) begin
            data_vld  <= found;
         end
         else if ({wait_for_sync, found, data_vld} == 3'b110) begin
            data_vld  <= 1'b1;
            data_offs <= offset;
         end
      end
   end


//--------------------------------
   localparam [7:0] SYNC = 8'b1011_1000;

   always@* begin
   //---find SYNC pattern and its bit-offset
      found  = 1'b0;
      offset = 3'd0;
      if ({curr_byte[0],   last_byte} == {SYNC, 1'd0}) begin
         found  = 1'b1;
         offset = 3'd0;
      end
      if ({curr_byte[1:0], last_byte} == {SYNC, 2'd0}) begin
         found  = 1'b1;
         offset = 3'd1;
      end
      if ({curr_byte[2:0], last_byte} == {SYNC, 3'd0}) begin
         found  = 1'b1;
         offset = 3'd2;
      end
      if ({curr_byte[3:0], last_byte} == {SYNC, 4'd0}) begin
         found  = 1'b1;
         offset = 3'd3;
      end
      if ({curr_byte[4:0], last_byte} == {SYNC, 5'd0}) begin
         found  = 1'b1;
         offset = 3'd4;
      end
      if ({curr_byte[5:0], last_byte} == {SYNC, 6'd0}) begin
         found  = 1'b1;
         offset = 3'd5;
      end
      if ({curr_byte[6:0], last_byte} == {SYNC, 7'd0}) begin
         found  = 1'b1;
         offset = 3'd6;
      end
      if (curr_byte[7:0] == SYNC) begin
         found  = 1'b1;
         offset = 3'd7;
      end

   //---then barrel-shift input data to align output
      case (data_offs)
         3'd7   : shifted_byte =  curr_byte;
         3'd6   : shifted_byte = {curr_byte[6:0], last_byte[7]};
         3'd5   : shifted_byte = {curr_byte[5:0], last_byte[7:6]};
         3'd4   : shifted_byte = {curr_byte[4:0], last_byte[7:5]};
         3'd3   : shifted_byte = {curr_byte[3:0], last_byte[7:4]};
         3'd2   : shifted_byte = {curr_byte[2:0], last_byte[7:3]};
         3'd1   : shifted_byte = {curr_byte[1:0], last_byte[7:2]};
         default: shifted_byte = {curr_byte[0],   last_byte[7:1]};
      endcase

   end

endmodule
