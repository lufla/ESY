/*********************************************************************
Description:
This module handles the initialization of the camera.
It consists of an I2C master, a ROM containing the data and an FSM to
manage the process. 
*********************************************************************/

module CCI_Handler (
input clk,
input RST_N,
inout I2C_SCL, 
inout I2C_SDA,
output init_done,
output init_error
);

//Internal Signal declarations..................................................................................................................................
//I2C Master
  wire i2c_master_clock;  
  wire i2c_master_reset_n;
  wire i2c_master_enable;
  wire i2c_master_read_write;
  wire [7:0] i2c_master_mosi_data;  //master output slave input: data to be sent to slave device    
  wire [15:0] i2c_master_register_address;
  wire [6:0] i2c_master_device_address;
  wire [15:0] i2c_master_divider;
  wire [7:0] i2c_master_miso_data;  //master input slave output: data received from slave device   
  wire i2c_master_busy;
  wire i2c_master_error;
  
  //Initializer
  wire initializer_clock;  //seperate clk wires in case I need to use several clocks
  reg run_init = 0;  //these initial assognments are probably pointless
  reg step_increment = 0;
  reg init_read_EN = 0;
  wire [15:0] init_address;
  wire [7:0] init_data;
  wire init_complete;
  
  //State-Machine
  reg [3:0] current_state = 0;  //current state for control state machine
  reg i2c_reset = 1;  //for active low reset        
  reg i2c_enable = 0;  //start with i2c disabled
  reg i2c_read_write;
  reg [7:0] i2c_mosi_data;  //master output slave input: data to be sent to slave device 
  reg     [15:0]   i2c_register_address;           //This is the register address. For the first test I will only write to 0x0100
  reg     [6:0]   i2c_device_address = 7'b0010000;    //I think this is the default address for the camera chip
  reg [15:0] i2c_divider = 16'd24;  //For now set for clk = 10MHz
  reg init_done_flag;  //flag to mark successful initialization
  reg init_error_flag;
  reg dummy_flag = 0;
  reg      [2:0]  i2c_iterations = 0; //this is a counter, to limit the number of communication attempts before giving up
//..........................................................................................................................................................................

//Assigns++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  assign i2c_master_clock = clk;  //For now all internal clocks are clk
  assign initializer_clock = clk;
  assign i2c_master_reset_n = i2c_reset;
  assign i2c_master_enable = i2c_enable;
  assign i2c_master_read_write = i2c_read_write;
  assign i2c_master_mosi_data = i2c_mosi_data;
  assign i2c_master_register_address = i2c_register_address;
  assign i2c_master_device_address = i2c_device_address;
  assign i2c_master_divider = i2c_divider;  //For now I'll keep the divider at a set value (register initialized with 4 and unchanged)

  assign init_done = init_done_flag;
  assign init_error = init_error_flag;
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

//Submodule instantiation----------------------------------------------------------------------------
  i2c_master #(
      .DATA_WIDTH(8),
      .REGISTER_WIDTH(16),
      .ADDRESS_WIDTH(7)
	  
  ) I2C (
      .clock(i2c_master_clock),
      .reset_n(i2c_master_reset_n),
      .enable(i2c_master_enable),
      .read_write(i2c_master_read_write),
      .mosi_data(i2c_master_mosi_data),
      .register_address(i2c_master_register_address),
      .device_address(i2c_master_device_address),  //can probably be static for most cameras
      .divider(i2c_master_divider),  //this determines I2C clk, depending on clk

      .miso_data(i2c_master_miso_data),
      .busy     (i2c_master_busy),
      .error    (i2c_master_error),

      .external_serial_data (I2C_SDA),
      .external_serial_clock(I2C_SCL)
  );
  
  INIT_IMX219 initializer (
      .clk(clk),
      .run_init(run_init),
      .step_increment(step_increment),
      .read_enable(init_read_EN),
      .current_address_out(init_address),
      .current_data_out(init_data),
      .complete(init_complete)
  );
//-------------------------------------------------------------------------------------------------------

//State-Machine for control of initialization
always @ (posedge clk)       //this contains the control sequence
begin
if (!RST_N) begin
	current_state <= 4'b0000;
	i2c_reset <= 0;
	init_done_flag <= 1;
	init_error_flag <= 1;
end
	else begin
    //  if (switch_active) begin   !I'll leave this in in case I want to control the start time here!
    case (current_state)
      0: begin  //starting with a reset seems like a good idea
        i2c_reset <= 0;
        i2c_enable <= 0;
        i2c_iterations <= 0;
        current_state <= 1;
		init_done_flag <= 1; //debug flag, negative logic for LED
		init_error_flag <= 1; //debug flag, negative logic for LED
      end

      1: begin
        i2c_reset <= 1;  //set reset signal to HIGH to enable operation of i2c_master
        run_init <= 1;  //this is basically an enable signal for the initializer
        i2c_read_write <= 0;  //the initialization is write only
        i2c_enable <= 0;                        //this may be redundant, but it's important that the master doesn't send when its not supposed to
        init_read_EN <= 1;  //this activates the LUT/ROM construct in the initializer
        step_increment <= 0;                 //I NEED TO MAKE SURE THIS ACTUALLY ONLY INCREMENTS THE COUNTER BY 1 !!!!!!!!!

        current_state <= 2;
      end

      2: begin
        i2c_register_address <= init_address;  //give current address to i2c master
        i2c_mosi_data        <= init_data;  //give current data to i2c master

        current_state        <= 3;
      end

      3: begin  //start I2C operation and wait for busy flag
        i2c_enable <= 1;
        if (i2c_master_busy) begin
          i2c_enable <= 0;
          current_state <= 4;
        end
      end

      4: begin  //Check for error or successful read
        if (i2c_master_error) begin  //if something went wrong, try again a few times
          if (i2c_iterations >= 4) begin  //if it didn't work 4 times, give up
            current_state <= 6;  //SET TO ERROR STATE                   
          end else begin
            i2c_iterations <= i2c_iterations + 1'b1;
            current_state  <= 3;
          end
        end else begin
          if (!i2c_master_busy) begin  //busy flag 0 and no error means succesful EoT
            if (init_complete) begin  //check for completion signal from initializer
              i2c_iterations <= 0;  //reset the attempt counter
              run_init       <= 0;  //reset initializer
              current_state  <= 5;  //leave the loop and go to next state
            end else begin
              step_increment <= 1;  //increment to next step
              i2c_iterations <= 0;  //reset the attempt counter
              current_state  <= 1;  //repeat the process for the next register-value combination
            end
          end
        end
      end  //end of state

      5: begin  //if everything worked correctly, this should be a dead end state
       init_done_flag <= 0;  //turn on LED to indicate the end of initialization
      end

      6: begin  //error state; light up error LED
       init_error_flag <= 0;
      end

    endcase
	end //end of run condition (RST_N  = 1)

  end  //end of always block   

endmodule