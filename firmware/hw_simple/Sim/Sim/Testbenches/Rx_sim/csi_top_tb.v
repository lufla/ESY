`timescale 1ns/1ns

`define IVERILOG 1

/*Checksum example:
Input Data Bytes:
FF 00 00 02 B9 DC F3 72 BB D4 B8 5A C8 75 C2 7C 81 F8 05 DF FF 00 00 01
Checksum LS byte and MS byte:
F0 00
*/

module tb();
    reg clk;


csi_top dut(
    .clk_ext(clk)

    //.DPHY_CK_HS_P(clk_hsp),
    //.DPHY_CK_HS_N(clk_hsn),
    //.DPHY_CK_LP_P(clk_lpp),
    //.DPHY_CK_LP_N(clk_lpn),

    //.DPHY_D0_HS_P( mipi_data[0]),
    //.DPHY_D0_HS_N(~mipi_data[0]),
    //.DPHY_D0_LP_P(data_lpp[0]),
    //.DPHY_D0_LP_N(data_lpn[0]),

    //.DPHY_D1_HS_P( mipi_data[1]),
    //.DPHY_D1_HS_N(~mipi_data[1])//,
    //.DPHY_D1_LP_P(data_lpp[1]),
    //.DPHY_D1_LP_N(data_lpn[1])
);

initial begin
    $dumpfile("csi_top_tb.vcd");
    $dumpvars(0, tb);
    clk = 1'b0;
end
always begin
    #10 clk =  ~clk;
end


initial begin
    #20000000
    $finish;
end

endmodule