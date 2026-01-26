`timescale 1ns / 1ps

// Main FSM for controlling CSI Readout caching the data and writing the data to an external port
//
// States:
// 0: reset
// 1: Initialize camera
// 2: wait for start
// 3: capture single picture and save in SDRAM
// 4: transfer pixel data to external port


module esy_control #(
	input clk,
	input rst_n,
	input fifo_enable,
	input init_done,
);

	//State-Machine
	reg [2:0] current_state = 0;  //current state for control state machine

	//State-Machine for control of initialization
	always @ (posedge clk)       //this contains the control sequence
	begin
		if (!rst_n) begin
			current_state <= 3'b000;
			fifo_enable <= 0;
		end
		else begin
		//  if (switch_active) begin   !I'll leave this in in case I want to control the start time here!
			case (current_state)
				0: begin  //starting with a reset seems like a good idea
					fifo_enable <= 0;
				end
				1: begin	// Initialize the camera
				end
				2: begin
				end
				3: begin
					fifo_enable <= 1;
				end
				4: begin
					fifo_enable <= 0;
				end
			endcase
		end //end of run condition (RST_N  = 1)

	end  //end of always block   

endmodule;