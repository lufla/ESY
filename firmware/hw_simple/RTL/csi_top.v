`timescale 1ns / 1ps

module csi_top #(
    parameter NUM_LANES = 2,
    parameter NUM_RAW = 8
)(
    input  clk_ext,
    output reg [7:0] LED
);

    wire rst_ref_n;

    clkrst_gen clkrst_gen_inst (
      .clk_ref   (clk_ext),
      .rst_ref_n (rst_ref_n)
    );

    localparam integer COUNT_MAX = 500000 - 1;

    reg [21:0] counter = 0;
    reg [7:0] led_count = 0;

always  @(posedge clk_ext)
begin
    if (counter >= COUNT_MAX) begin
        counter <= 0;
        led_count <= led_count + 1;
    end else begin
        counter <= counter + 1;
    end
    LED <= led_count;
end

endmodule
