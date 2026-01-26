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
    reg mipi_clk_r;
    wire clk_hsp;
    wire clk_hsn;
    wire clk_lpp;
    wire clk_lpn;
    wire [2:0] data_lpp;
    wire [2:0] data_lpn;

    reg clk_lpp_r;
    reg clk_lpn_r;
    reg [2:0] data_lpp_r;
    reg [2:0] data_lpn_r;

    reg [1:0] mipi_data;

    wire pclk;
    wire [15:0] data;
    wire fsync;
    wire lsync;

assign clk_hsp =  mipi_clk_r | clk_lpp;
assign clk_hsn = ~mipi_clk_r | clk_lpn;
assign clk_lpp = clk_lpp_r;
assign clk_lpn = clk_lpn_r;
assign data_lpp = data_lpp_r;
assign data_lpn = data_lpn_r;

esy_top dut(
    .clk_ext(clk),

    .DPHY_CK_HS_P(clk_hsp),
    .DPHY_CK_HS_N(clk_hsn),
    //.DPHY_CK_LP_P(clk_lpp),
    //.DPHY_CK_LP_N(clk_lpn),

    .DPHY_D0_HS_P( mipi_data[0]),
    .DPHY_D0_HS_N(~mipi_data[0]),
    //.DPHY_D0_LP_P(data_lpp[0]),
    //.DPHY_D0_LP_N(data_lpn[0]),

    .DPHY_D1_HS_P( mipi_data[1]),
    .DPHY_D1_HS_N(~mipi_data[1])//,
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

function [7:0] calculate_ecc;
    input [23:0] data;
    begin
        calculate_ecc[7] = 1'b0;
        calculate_ecc[6] = 1'b0;

        calculate_ecc[5] = data[10] ^ data[11] ^ data[12] ^ data[13] ^ data[14] ^ data[15]
                         ^ data[16] ^ data[17] ^ data[18] ^ data[19] ^ data[21] ^ data[22]
                         ^ data[23];
        calculate_ecc[4] = data[4]  ^ data[5]  ^ data[6]  ^ data[7]  ^ data[8]  ^ data[9]
                         ^ data[16] ^ data[17] ^ data[18] ^ data[19] ^ data[20] ^ data[22]
                         ^ data[23];
        calculate_ecc[3] = data[1]  ^ data[2]  ^ data[3]  ^ data[7]  ^ data[8]  ^ data[9]
                         ^ data[13] ^ data[14] ^ data[15] ^ data[19] ^ data[20] ^ data[21]
                         ^ data[23];
        calculate_ecc[2] = data[0]  ^ data[2]  ^ data[3]  ^ data[5]  ^ data[6]  ^ data[9]
                         ^ data[11] ^ data[12] ^ data[15] ^ data[18] ^ data[20] ^ data[21]
                         ^ data[22];
        calculate_ecc[1] = data[0]  ^ data[1]  ^ data[3]  ^ data[4]  ^ data[6]  ^ data[8]
                         ^ data[10] ^ data[12] ^ data[14] ^ data[17] ^ data[20] ^ data[21]
                         ^ data[22] ^ data[23];
        calculate_ecc[0] = data[0]  ^ data[1]  ^ data[2]  ^ data[4]  ^ data[5]  ^ data[7]
                         ^ data[10] ^ data[11] ^ data[13] ^ data[16] ^ data[20] ^ data[21]
                         ^ data[22] ^ data[23];
    end
endfunction

task start_mipi_frame;
    begin
        send_mipi_clock();
        send_mipi_clock();
        send_mipi_clock();
        data_lpp_r = 2'b0;
        send_mipi_clock();
        send_mipi_clock();
        send_mipi_clock();
        send_mipi_byte(16'h0000); //  00 00
        send_mipi_byte(16'hB8B8); //  B8 B8
        send_mipi_byte(16'h0000); //  00 00
        send_mipi_byte(16'h0000); // ecc 00
        send_mipi_byte(16'h0000); //  00 00 (x6)
        send_mipi_byte(16'h0000);
        send_mipi_byte(16'h0000);
        send_mipi_byte(16'h0000);
        send_mipi_byte(16'h0000);
        send_mipi_byte(16'h0000);
        send_mipi_clock();
        send_mipi_clock();
        data_lpp_r = 2'b11;
        data_lpn_r = 2'b11;
    end
endtask

task send_mipi_frame;
     reg [15:0] i;
         //i= 16'd0;
     begin
                 //i = 0;
         clk_lpp_r = 0;
         #20;
         clk_lpn_r = 0;
         #5;
         send_mipi_clock();
         send_mipi_clock();
         send_mipi_clock();
         send_mipi_clock();
         send_mipi_clock();
         send_mipi_clock();
         send_mipi_clock();
         send_mipi_clock();
         send_mipi_clock();
         send_mipi_clock();
         // start frame
         start_mipi_frame();
         for (i= 16'd0; i <16'd10 ; i = i +1'd1)
         begin
             send_line();
             #20;
         end
         send_mipi_clock();
         send_mipi_clock();
         send_mipi_clock();
         send_mipi_clock();
         send_mipi_clock();
         send_mipi_clock();
         send_mipi_clock();
         send_mipi_clock();
         send_mipi_clock();
         #5
         clk_lpp_r = 1;
         clk_lpn_r = 1;
     end
endtask

task send_line;
    reg[15:0]i;
    begin
                i = 16'b0;
        send_mipi_clock();
        send_mipi_clock();
        send_mipi_clock();
        data_lpp_r = 2'b0;
        send_mipi_clock();
        send_mipi_clock();
        send_mipi_clock();
        data_lpn_r = 2'b0;
        send_bad_byte(16'h0000); //  00 00 SMALL CHANGE HERE FOR SOME TEST
        send_mipi_byte(16'hB8B8); //  B8 B8
        send_mipi_byte(16'h182A); // llw  2A
        send_mipi_byte({calculate_ecc(24'h00182A), 8'h00}); // ecc lhi
        // data FF 00 00 02 B9 DC F3 72 BB D4 B8 5A C8 75 C2 7C 81 F8 05 DF FF 00 00 01
        send_mipi_byte(16'h00FF);
        send_mipi_byte(16'h0200);
        send_mipi_byte(16'hDCB9);
        send_mipi_byte(16'h72F3);
        send_mipi_byte(16'hD4BB);
        send_mipi_byte(16'h5AB8);
        send_mipi_byte(16'h75C8);
        send_mipi_byte(16'h7CC2);
        send_mipi_byte(16'hF881);
        send_mipi_byte(16'hDF05);
        send_mipi_byte(16'h00FF);
        send_mipi_byte(16'h0100);
        send_mipi_byte(16'h00F0); // EOT checksum
        send_mipi_clock();
        send_mipi_clock();
        send_mipi_clock();
        send_mipi_clock();
        send_mipi_clock();
        send_mipi_clock();
        send_mipi_clock();
        send_mipi_clock();
        data_lpp_r = 2'b11;
        data_lpn_r = 2'b11;
    end
endtask

task send_mipi_byte;
    input [15:0]bytes;
    reg [7:0] i;
    begin
        for(i = 8'b0; i< 8'h8; i = i+2) begin
            #1;
            mipi_data = {bytes[8'd8 + i], bytes[i]};
            #1;
            mipi_clk_r = 1'b1;
            #1;
            mipi_data = {bytes[8'd8 +i + 1], bytes[i+1]};
            #1;
            mipi_clk_r = 1'b0;
        end
    end
endtask

task send_bad_byte;
    input [15:0]bytes;
    reg [7:0] i;
    begin
        for(i = 8'b0; i< 8'h6; i = i+2) begin
            #1;
            mipi_data = {bytes[8'd8 + i], bytes[i]};
            #1;
            mipi_clk_r = 1'b1;
            #1;
            mipi_data = {bytes[8'd8 +i + 1], bytes[i+1]};
            #1;
            mipi_clk_r = 1'b0;
        end
    end
endtask

task send_mipi_clock;
    begin
        send_mipi_byte(16'h0000);
    end
endtask

initial begin
    mipi_data = 0;
    mipi_clk_r = 0;
    data_lpp_r = 2'b11;
    data_lpn_r = 2'b11;
    clk_lpp_r = 1;
    clk_lpn_r = 1;
    #2000
    send_mipi_frame();
    #200
    send_mipi_frame();
    #200
    send_mipi_frame();
    #200
    $finish;
end

endmodule