`timescale 1ns / 1ps

module clkrst_gen (
   input  clk_ref,
   output rst_ref_n
);

    reg [5:0] rst_ref_cnt = 0;
    assign rst_ref_n = &rst_ref_cnt;

    always @(posedge clk_ref) begin
        rst_ref_cnt <= rst_ref_cnt + !rst_ref_n;
    end

endmodule
