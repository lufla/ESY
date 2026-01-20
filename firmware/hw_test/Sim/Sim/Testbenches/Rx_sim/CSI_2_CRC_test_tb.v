`timescale 1 ns / 1 ps

/*
This test uses the 2nd example for checksum generation from the CSI-2 Spec.
This way I can check if the checksum generation works properly.

Input Data Bytes:
FF 00 00 00 1E F0 1E C7 4F 82 78 C5 82 E0 8C 70 D2 3C 78 E9 FF 00 00 01
Checksum LS byte and MS byte:
69 E5
*/

module CSI_2_CRC_test_tb;

  reg clk = 0;
  reg [15:0] data_stream_in = 0;
  reg data_in_valid = 0;
  reg [15:0] rec_checksum = 16'hE569;  //reference checksum; should be = calc_checksum
  wire [15:0] calc_checksum;

  CSI_2_CRC_test DUT (
      .clk(clk),
      .rst(),
      .data_in(data_stream_in),
      .data_valid(data_in_valid),
      .calc_checksum(calc_checksum)
  );

  initial begin
    $dumpfile("CSI_2_CRC_test_tb.vcd");
    $dumpvars(0, CSI_2_CRC_test_tb);

    forever #5 clk = !clk;
  end

/* 8-bit standard implementation
initial begin
    #9 data_stream_in = 62;  //start with random value to test valid signal
    #10 data_in_valid = 1;
    data_stream_in = 8'hFF;
    #10 data_stream_in = 8'h00;
    #10 data_stream_in = 8'h00;
    #10 data_stream_in = 8'h00;
    #10 data_stream_in = 8'h1E;
    #10 data_stream_in = 8'hF0;
    #10 data_stream_in = 8'h1E;
    #10 data_stream_in = 8'hC7;
    #10 data_stream_in = 8'h4F;
    #10 data_stream_in = 8'h82;
    #10 data_stream_in = 8'h78;
    #10 data_stream_in = 8'hC5;
    #10 data_stream_in = 8'h82;
    #10 data_stream_in = 8'hE0;
    #10 data_stream_in = 8'h8C;
    #10 data_stream_in = 8'h70;
    #10 data_stream_in = 8'hD2;
    #10 data_stream_in = 8'h3C;
    #10 data_stream_in = 8'h78;
    #10 data_stream_in = 8'hE9;
    #10 data_stream_in = 8'hFF;
    #10 data_stream_in = 8'h00;
    #10 data_stream_in = 8'h00;
    #10 data_stream_in = 8'h01;
    #10 data_in_valid = 0;
end
*/
//16-bit (2 lanes parallel) implementation
initial begin
    /* this variant doesn't work!
    #9 data_stream_in = 62;  //start with random value to test valid signal
    #10 data_in_valid = 1;
    data_stream_in = 16'hFF00;
    #10 data_stream_in = 16'h0000;
    #10 data_stream_in = 16'h1EF0;
    #10 data_stream_in = 16'h1EC7;
    #10 data_stream_in = 16'h4F82;
    #10 data_stream_in = 16'h78C5;
    #10 data_stream_in = 16'h82E0;
    #10 data_stream_in = 16'h8C70;
    #10 data_stream_in = 16'hD23C;
    #10 data_stream_in = 16'h78E9;
    #10 data_stream_in = 16'hFF00;
    #10 data_stream_in = 16'h0001;
    #10 data_in_valid = 0;
*/
    #9 data_stream_in = 62;  //start with random value to test valid signal
    #10 data_in_valid = 1;
    data_stream_in = 16'h00FF;
    #10 data_stream_in = 16'h0000;
    #10 data_stream_in = 16'hF01E;
    #10 data_stream_in = 16'hC71E;
    #10 data_stream_in = 16'h824F;
    #10 data_stream_in = 16'hC578;
    #10 data_stream_in = 16'hE082;
    #10 data_stream_in = 16'h708C;
    #10 data_stream_in = 16'h3CD2;
    #10 data_stream_in = 16'hE978;
    #10 data_stream_in = 16'h00FF;
    #10 data_stream_in = 16'h0100;
    #10 data_in_valid = 0;
end
  //Input Data Bytes:
  //FF 00 00 00 1E F0 1E C7 4F 82 78 C5 82 E0 8C 70 D2 3C 78 E9 FF 00 00 01
  initial begin
    #1000;
    $finish;
  end

endmodule

