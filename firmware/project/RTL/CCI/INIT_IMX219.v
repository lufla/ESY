`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//
// Create Date: 08.02.2024 15:09:47
// Module Name: INIT_IMX219
// Description: This module provides the adresses of the control regsiters and the values to send to the top module.
// 
//
//////////////////////////////////////////////////////////////////////////////////

module INIT_IMX219 (
    input clk,
    input run_init,  //active-low, asynchronous reset
    input step_increment, //this signal will be used by the top control to load the next pair of values
    input read_enable,  //this might be completely redundant, but I guess it does no harm
    output [15:0] current_address_out,  //current register address given to the top module
    output [7:0] current_data_out,  //current value to write into current register
    output reg complete  //indicates completion of initialization sequence to top module
);
  /*list of relevant control register names and addresses
  `define REG_MODEL_ID_MSB = 16'h0000;
  `define REG_MODEL_ID_LSB = 16'h0001;
  `define REG_MODE_SEL = 16'h0100;
  `define REG_CSI_LANE = 16'h0114;
  `define REG_DPHY_CTRL = 16'h0128;
  `define REG_EXCK_FREQ_MSB = 16'h012A;
  `define REG_EXCK_FREQ_LSB = 16'h012B;
  `define REG_FRAME_LEN_MSB = 16'h0160;
  `define REG_FRAME_LEN_LSB = 16'h0161;
  `define REG_LINE_LEN_MSB = 16'h0162;
  `define REG_LINE_LEN_LSB = 16'h0163;
  `define REG_X_ADD_STA_MSB = 16'h0164;
  `define REG_X_ADD_STA_LSB = 16'h0165;
  `define REG_X_ADD_END_MSB = 16'h0166;
  `define REG_X_ADD_END_LSB = 16'h0167;
  `define REG_Y_ADD_STA_MSB = 16'h0168;
  `define REG_Y_ADD_STA_LSB = 16'h0169;
  `define REG_Y_ADD_END_MSB = 16'h016A;
  `define REG_Y_ADD_END_LSB = 16'h016B;

  `define REG_X_OUT_SIZE_MSB = 16'h016C;
  `define REG_X_OUT_SIZE_LSB = 16'h016D;
  `define REG_Y_OUT_SIZE_MSB = 16'h016E;
  `define REG_Y_OUT_SIZE_LSB = 16'h016F;

  `define REG_X_ODD_INC = 16'h0170;
  `define REG_Y_ODD_INC = 16'h0171;
  `define REG_IMG_ORIENT = 16'h0172;
  `define REG_BINNING_H = 16'h0174;
  `define REG_BINNING_V = 16'h0175;
  `define REG_BIN_CALC_MOD_H = 16'h0176;
  `define REG_BIN_CALC_MOD_V = 16'h0177;

  `define REG_CSI_FORMAT_C = 16'h018C;
  `define REG_CSI_FORMAT_D = 16'h018D;

  `define REG_DIG_GAIN_GLOBAL_MSB = 16'h0158;
  `define REG_DIG_GAIN_GLOBAL_LSB = 16'h0159;
  `define REG_ANA_GAIN_GLOBAL = 16'h0157;
  `define REG_INTEGRATION_TIME_MSB = 16'h015A;
  `define REG_INTEGRATION_TIME_LSB = 16'h015B;
  `define REG_ANALOG_GAIN = 16'h0157;

  `define REG_VTPXCK_DIV = 16'h0301;
  `define REG_VTSYCK_DIV = 16'h0303;
  `define REG_PREPLLCK_VT_DIV = 16'h0304;
  `define REG_PREPLLCK_OP_DIV = 16'h0305;
  `define REG_PLL_VT_MPY_MSB = 16'h0306;
  `define REG_PLL_VT_MPY_LSB = 16'h0307;
  `define REG_OPPXCK_DIV = 16'h0309;
  `define REG_OPSYCK_DIV = 16'h030B;
  `define REG_PLL_OP_MPY_MSB = 16'h030C;
  `define REG_PLL_OP_MPY_LSB = 16'h030D;


  `define REG_TEST_PATTERN_MSB = 16'h0600;
  `define REG_TEST_PATTERN_LSB = 16'h0601;
  `define REG_TP_RED_MSB = 16'h0602;
  `define REG_TP_RED_LSB = 16'h0603;
  `define REG_TP_GREEN_MSB = 16'h0604;
  `define REG_TP_GREEN_LSB = 16'h0605;
  `define REG_TP_BLUE_MSB = 16'h0606;
  `define REG_TP_BLUE_LSB = 16'h0607;
  `define REG_TP_X_OFFSET_MSB = 16'h0620;
  `define REG_TP_X_OFFSET_LSB = 16'h0621;
  `define REG_TP_Y_OFFSET_MSB = 16'h0622;
  `define REG_TP_Y_OFFSET_LSB = 16'h0623;
  `define REG_TP_WIDTH_MSB = 16'h0624;
  `define REG_TP_WIDTH_LSB = 16'h0625;
  `define REG_TP_HEIGHT_MSB = 16'h0626;
  `define REG_TP_HEIGHT_LSB = 16'h0627;
*/
  reg [15:0] register_addresses;
  reg [5:0] init_step;
  reg [7:0] register_data;

  always @(posedge clk)
    if (read_enable)
      case (init_step)
        6'd0: register_addresses <= 16'h0100;
        6'd1: register_addresses <= 16'h0114;
        6'd2: register_addresses <= 16'h0128;
        6'd3: register_addresses <= 16'h012A;
        6'd4: register_addresses <= 16'h012B;
        6'd5: register_addresses <= 16'h0160;
        6'd6: register_addresses <= 16'h0161;
        6'd7: register_addresses <=  16'h0162;
        6'd8: register_addresses <=  16'h0163;
		//following registers are for setting image resolution
        6'd9: register_addresses <=  16'h0164;	
        6'd10: register_addresses <=  16'h0165;
        6'd11: register_addresses <=  16'h0166;
        6'd12: register_addresses <=  16'h0167;
        6'd13: register_addresses <=  16'h0168;
        6'd14: register_addresses <=  16'h0169;
        6'd15: register_addresses <=  16'h016A;
        6'd16: register_addresses <=  16'h016B;
        6'd17: register_addresses <=  16'h016C;
        6'd18: register_addresses <=  16'h016D;
        6'd19: register_addresses <=  16'h016E;
        6'd20: register_addresses <=  16'h016F;
		//end of registers for resolution setting
        6'd21: register_addresses <= 16'h0170;
        6'd22: register_addresses <= 16'h0171;
        6'd23: register_addresses <= 16'h0174;
        6'd24: register_addresses <= 16'h0175;
		//registers for output data format
        6'd25: register_addresses <= 16'h018C;
        6'd26: register_addresses <= 16'h018D;
		//end of registers for output data format
        6'd27: register_addresses <= 16'h0301;
        6'd28: register_addresses <= 16'h0303;
        6'd29: register_addresses <= 16'h0306;
        6'd30: register_addresses <= 16'h0307;
        6'd31: register_addresses <= 16'h0309;	//OPPXCK_DIV apparently this is relevant for data format setting
        6'd32: register_addresses <= 16'h030B;
        6'd33: register_addresses <= 16'h030C;  //PLL_OP_MPY_MSB (clock multiplier for D-PHY clk)
        6'd34: register_addresses <= 16'h030D; //PLL_OP_MPY_LSB 
        6'd35: register_addresses <= 16'h0602;	//monochrome test image red MSB
        6'd36: register_addresses <= 16'h0603;	//test image red LSB
        6'd37: register_addresses <= 16'h0604;	//test image green(R) MSB
        6'd38: register_addresses <= 16'h0605;	//test image green(R) LSB
        6'd39: register_addresses <= 16'h0606;	//test image blue MSB
        6'd40: register_addresses <= 16'h0607;	//test image blue LSB
		6'd41: register_addresses <= 16'h0608;	//test image green(B) MSB
		6'd42: register_addresses <= 16'h0609;	//test image green(B) LSB
        6'd43: register_addresses <= 16'h0600;	//tp mode
        6'd44: register_addresses <= 16'h0601;	//tp mode
        6'd45: register_addresses <= 16'h0620;
        6'd46: register_addresses <= 16'h0621;
        6'd47: register_addresses <= 16'h0622;
        6'd48: register_addresses <= 16'h0623;
        //here come the setting registers for test pattern size
		6'd49: register_addresses <= 16'h0624;
        6'd50: register_addresses <= 16'h0625;
        6'd51: register_addresses <= 16'h0626;
        6'd52: register_addresses <= 16'h0627;
		//end of registers for test pattern size
        6'd53: register_addresses <= 16'h0158;	//dig gain glb
        6'd54: register_addresses <= 16'h0159;	//dig gain glb
        6'd55: register_addresses <= 16'h0157;	//ana gain glb
        6'd56: register_addresses <= 16'h015A; //integration time MSB
        6'd57: register_addresses <= 16'h015B; //integration time LSB
        6'd58: register_addresses <= 16'h0100;  //last entry. "start stream" command
        default: register_addresses <= 0;  //default address is 0
      endcase

  always @(posedge clk)
    if (read_enable)
      case (init_step)
        6'd0: register_data <= 0;
        6'd1: register_data <= 1;
        6'd2: register_data <= 0;
        6'd3: register_data <= 8'h18;
        6'd4: register_data <= 8'h00;
        6'd5: register_data <= 8'h03;	//FRM_LEN_MSB
        6'd6: register_data <= 8'h5E;	//FRM_LEN_LSB
        6'd7: register_data <= 8'h0E;	//LINE_LEN_MSB
        6'd8: register_data <= 8'h02;	//LINE_LEN_LSB	
		//start of settings for resolution
        6'd9: register_data <= 8'h03;	//x start MSB
        6'd10: register_data <= 8'hE8;
        6'd11: register_data <= 8'h06;	//x end MSB
        6'd12: register_data <= 8'h68;	
        6'd13: register_data <= 8'h02;	//y start MSB
        6'd14: register_data <= 8'hEE;	
        6'd15: register_data <= 8'h04;	//y end MSB
        6'd16: register_data <= 8'hCE;	
        6'd17: register_data <= 8'h02;
        6'd18: register_data <= 8'h80;
        6'd19: register_data <= 8'h01;
        6'd20: register_data <= 8'hE0;
		//end of settings for resolution
        6'd21: register_data <= 8'h01;
        6'd22: register_data <= 8'h01;
        6'd23: register_data <= 8'h00;	//BINNING (0 for no binning)
        6'd24: register_data <= 8'h00;	//BINNING (0 for no binning)
		//output data format settings (0A0A for RAW10, 0808 for RAW8)
        6'd25: register_data <= 8'h08;
        6'd26: register_data <= 8'h08;
		//end of output data format settings
        6'd27: register_data <= 8'h04;	//VTPXCK_DIV
        6'd28: register_data <= 8'h01;
        6'd29: register_data <= 8'h00;
        6'd30: register_data <= 8'h2E;	//PLL_VT_MPY_LSB
        6'd31: register_data <= 8'h08;	//this must be "08" for RAW8, "0A" RAW10 
        6'd32: register_data <= 8'h01;
        6'd33: register_data <= 8'h00; //PLL_OP_MPY_LSB
        6'd34: register_data <= 8'h32; //PLL_OP_MPY_LSB
        6'd35: register_data <= 8'h00; //monochrome test image red MSB
        6'd36: register_data <= 8'h00;
        6'd37: register_data <= 8'h00; //monochrome test image green(R) MSB
        6'd38: register_data <= 8'h00;
        6'd39: register_data <= 8'h00; //monochrome test image blue MSB
        6'd40: register_data <= 8'h00;
		6'd41: register_data <= 8'h00; //monochrome test image green(B) MSB
		6'd42: register_data <= 8'h00;
        6'd43: register_data <= 8'h00;  //tp mode (always 0)
        6'd44: register_data <= 8'h00;	//tp mode
        6'd45: register_data <= 8'h00;
        6'd46: register_data <= 8'h00;
        6'd47: register_data <= 8'h00;
        6'd48: register_data <= 8'h00;
       //settings for test pattern size
 	    6'd49: register_data <= 8'h02;	//width MSByte
        6'd50: register_data <= 8'h80;	//width LSByte
        6'd51: register_data <= 8'h01;	//height MSByte
        6'd52: register_data <= 8'hE0;	//height LSByte
        //end of settings for test pattern size
		6'd53: register_data <= 8'h01; //dig gain glb
        6'd54: register_data <= 8'h0F; //dig gain glb	(prev value: 00)
        6'd55: register_data <= 8'hAE;	//ana gain glb	(prev value: 80)
        6'd56: register_data <= 8'h03;	//integration time MSB
        6'd57: register_data <= 8'h5A;	//integration time LSB
        6'd58: register_data <= 8'h01;  //last entry. This is the "start stream" command
        default: register_data <= 0;  //default address is 0
      endcase

  //the registers are directly connected to the module output
  assign current_address_out = register_addresses;
  assign current_data_out = register_data;

  always @(posedge clk) begin
    if (run_init) begin
      if (step_increment) init_step <= init_step + 1;  //go to next step on request from top_module
      if (init_step == 6'd59)
        complete <= 1;  
    end else begin
      init_step <= 0;     
      complete <= 0;
    end
  end

endmodule