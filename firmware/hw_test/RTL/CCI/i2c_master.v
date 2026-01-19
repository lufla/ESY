
module i2c_master #(
    parameter DATA_WIDTH     = 8,
    parameter REGISTER_WIDTH = 16,
    parameter ADDRESS_WIDTH  = 7
) (
    input wire                      clock,
    input wire                      reset_n,
    input wire                      enable,
    input wire                      read_write,
    input wire [    DATA_WIDTH-1:0] mosi_data,
    input wire [REGISTER_WIDTH-1:0] register_address,
    input wire [ ADDRESS_WIDTH-1:0] device_address,
    input wire [              15:0] divider,

    output reg [DATA_WIDTH-1:0] miso_data,
    output reg                  busy,
    output reg                  error,

    inout external_serial_data,
    inout external_serial_clock
);

       // reg _sv2v_0;
        
        reg [31:0] state;
        reg [31:0] _state;
        reg [31:0] post_state;
        reg [31:0] _post_state;
        reg serial_clock;
        reg _serial_clock;
        reg [ADDRESS_WIDTH:0] saved_device_address;
        reg [ADDRESS_WIDTH:0] _saved_device_address;
        reg [REGISTER_WIDTH - 1:0] saved_register_address;
        reg [REGISTER_WIDTH - 1:0] _saved_register_address;
        reg [DATA_WIDTH - 1:0] saved_mosi_data;
        reg [DATA_WIDTH - 1:0] _saved_mosi_data;
        reg [1:0] process_counter;
        reg [1:0] _process_counter;
        reg [7:0] bit_counter;
        reg [7:0] _bit_counter;
        reg serial_data;
        reg _serial_data;
        reg post_serial_data;
        reg _post_serial_data;
        reg last_acknowledge;
        reg _last_acknowledge;
        reg _saved_read_write;
        reg saved_read_write;
        reg [15:0] divider_counter;
        reg [15:0] _divider_counter;
        reg divider_tick;
        reg [DATA_WIDTH - 1:0] _miso_data;
        reg _busy;
        reg serial_data_output_enable;
        reg serial_clock_output_enable;
        reg _error;
        assign external_serial_clock = (serial_clock_output_enable ? serial_clock : 1'bz);
        assign external_serial_data = (serial_data_output_enable ? serial_data : 1'bz);
        always @(*) begin
                _state = state;
                _post_state = post_state;
                _process_counter = process_counter;
                _bit_counter = bit_counter;
                _last_acknowledge = last_acknowledge;
                _miso_data = miso_data;
                _saved_read_write = saved_read_write;
                _busy = busy;
                _divider_counter = divider_counter;
                _saved_register_address = saved_register_address;
                _saved_device_address = saved_device_address;
                _saved_mosi_data = saved_mosi_data;
                _serial_data = serial_data;
                _serial_clock = serial_clock;
                _post_serial_data = post_serial_data;
                _error = error;
                if (divider_counter == divider) begin
                        _divider_counter = 0;
                        divider_tick = 1;
                end
                else begin
                        _divider_counter = divider_counter + 1;
                        divider_tick = 0;
                end
                if ((((state != 32'd0) && (state != 32'd3)) && (state != 32'd7)) && (state != 32'd13))
                        serial_data_output_enable = 1;
                else
                        serial_data_output_enable = 0;
                if (((state != 32'd0) && (process_counter != 1)) && (process_counter != 2))
                        serial_clock_output_enable = 1;
                else
                        serial_clock_output_enable = 0;
                case (state)
                        32'd0: begin
                                _process_counter = 0;
                                _bit_counter = 0;
                                _last_acknowledge = 0;
                                _busy = 0;
                                _saved_read_write = read_write;
                                _saved_register_address = register_address;
                                _saved_device_address = {device_address, 1'b0};
                                _saved_mosi_data = mosi_data;
                                _serial_data = 1;
                                _serial_clock = 1;
                                _error = 0;
                                if (enable) begin
                                        _state = 32'd1;
                                        _post_state = 32'd2;
                                        _busy = 1;
                                end
                        end
                        32'd1:
                                if (divider_tick)
                                        case (process_counter)
                                                0: _process_counter = 1;
                                                1: begin
                                                        _serial_data = 0;
                                                        _process_counter = 2;
                                                end
                                                2: begin
                                                        _bit_counter = 8;
                                                        _process_counter = 3;
                                                end
                                                3: begin
                                                        _serial_clock = 0;
                                                        _process_counter = 0;
                                                        _state = post_state;
                                                        _serial_data = saved_device_address[ADDRESS_WIDTH];
                                                end
                                        endcase
                        32'd2:
                                if (divider_tick)
                                        case (process_counter)
                                                0: begin
                                                        _serial_clock = 1;
                                                        _process_counter = 1;
                                                end
                                                1:
                                                        if (external_serial_clock == 1)
                                                                _process_counter = 2;
                                                2: begin
                                                        _serial_clock = 0;
                                                        _bit_counter = bit_counter - 1;
                                                        _process_counter = 3;
                                                end
                                                3: begin
                                                        if (bit_counter == 0) begin
                                                                _post_serial_data = saved_register_address[REGISTER_WIDTH - 1];
                                                                if (REGISTER_WIDTH == 16)
                                                                        _post_state = 32'd11;
                                                                else
                                                                        _post_state = 32'd4;
                                                                _state = 32'd3;
                                                                _bit_counter = 8;
                                                        end
                                                        else
                                                                _serial_data = saved_device_address[bit_counter - 1];
                                                        _process_counter = 0;
                                                end
                                        endcase
                        32'd3:
                                if (divider_tick)
                                        case (process_counter)
                                                0: begin
                                                        _serial_clock = 1;
                                                        _process_counter = 1;
                                                end
                                                1:
                                                        if (external_serial_clock == 1) begin
                                                                _last_acknowledge = 0;
                                                                _process_counter = 2;
                                                        end
                                                2: begin
                                                        _serial_clock = 0;
                                                        if (external_serial_data == 0)
                                                                _last_acknowledge = 1;
                                                        _process_counter = 3;
                                                end
                                                3: begin
                                                        if (last_acknowledge == 1) begin
                                                                _last_acknowledge = 0;
                                                                _serial_data = post_serial_data;
                                                                _state = post_state;
                                                        end
                                                        else begin
                                                                _error = 1;
                                                                _state = 32'd0;
                                                        end
                                                        _process_counter = 0;
                                                end
                                        endcase
                        32'd11:
                                if (divider_tick)
                                        case (process_counter)
                                                0: begin
                                                        _serial_clock = 1;
                                                        _process_counter = 1;
                                                end
                                                1:
                                                        if (external_serial_clock == 1) begin
                                                                _last_acknowledge = 0;
                                                                _process_counter = 2;
                                                        end
                                                2: begin
                                                        _serial_clock = 0;
                                                        _bit_counter = bit_counter - 1;
                                                        _process_counter = 3;
                                                end
                                                3: begin
                                                        if (bit_counter == 0) begin
                                                                _post_state = 32'd4;
                                                                _post_serial_data = saved_register_address[7];
                                                                _bit_counter = 8;
                                                                _serial_data = 0;
                                                                _state = 32'd3;
                                                        end
                                                        else
                                                                _serial_data = saved_register_address[bit_counter + 7];
                                                        _process_counter = 0;
                                                end
                                        endcase
                        32'd4:
                                if (divider_tick)
                                        case (process_counter)
                                                0: begin
                                                        _serial_clock = 1;
                                                        _process_counter = 1;
                                                end
                                                1:
                                                        if (external_serial_clock == 1) begin
                                                                _last_acknowledge = 0;
                                                                _process_counter = 2;
                                                        end
                                                2: begin
                                                        _serial_clock = 0;
                                                        _bit_counter = bit_counter - 1;
                                                        _process_counter = 3;
                                                end
                                                3: begin
                                                        if (bit_counter == 0) begin
                                                                if (read_write == 0) begin
                                                                        if (DATA_WIDTH == 16) begin
                                                                                _post_state = 32'd12;
                                                                                _post_serial_data = saved_mosi_data[15];
                                                                        end
                                                                        else begin
                                                                                _post_state = 32'd10;
                                                                                _post_serial_data = saved_mosi_data[7];
                                                                        end
                                                                end
                                                                else begin
                                                                        _post_state = 32'd5;
                                                                        _post_serial_data = 1;
                                                                end
                                                                _bit_counter = 8;
                                                                _serial_data = 0;
                                                                _state = 32'd3;
                                                        end
                                                        else
                                                                _serial_data = saved_register_address[bit_counter - 1];
                                                        _process_counter = 0;
                                                end
                                        endcase
                        32'd12:
                                if (divider_tick)
                                        case (process_counter)
                                                0: begin
                                                        _serial_data = 1;
                                                        _process_counter = 1;
                                                end
                                                1:
                                                        if (external_serial_clock == 1) begin
                                                                _last_acknowledge = 0;
                                                                _process_counter = 2;
                                                        end
                                                2: begin
                                                        _serial_clock = 0;
                                                        _bit_counter = bit_counter - 1;
                                                        _process_counter = 3;
                                                end
                                                3: begin
                                                        if (bit_counter == 0) begin
                                                                _state = 32'd3;
                                                                _post_state = 32'd10;
                                                                _post_serial_data = saved_mosi_data[7];
                                                                _bit_counter = 8;
                                                                _serial_data = 0;
                                                        end
                                                        else
                                                                _serial_data = saved_mosi_data[bit_counter + 7];
                                                        _process_counter = 0;
                                                end
                                        endcase
                        32'd10:
                                if (divider_tick)
                                        case (process_counter)
                                                0: begin
                                                        _serial_clock = 1;
                                                        _process_counter = 1;
                                                end
                                                1:
                                                        if (external_serial_clock == 1) begin
                                                                _last_acknowledge = 0;
                                                                _process_counter = 2;
                                                        end
                                                2: begin
                                                        _serial_clock = 0;
                                                        _bit_counter = bit_counter - 1;
                                                        _process_counter = 3;
                                                end
                                                3: begin
                                                        if (bit_counter == 0) begin
                                                                _state = 32'd3;
                                                                _post_state = 32'd9;
                                                                _post_serial_data = 0;
                                                                _bit_counter = 8;
                                                                _serial_data = 0;
                                                        end
                                                        else
                                                                _serial_data = saved_mosi_data[bit_counter - 1];
                                                        _process_counter = 0;
                                                end
                                        endcase
                        32'd5:
                                if (divider_tick)
                                        case (process_counter)
                                                0: _process_counter = 1;
                                                1: begin
                                                        _process_counter = 2;
                                                        _serial_clock = 1;
                                                end
                                                2: _process_counter = 3;
                                                3: begin
                                                        _state = 32'd1;
                                                        _post_state = 32'd6;
                                                        _saved_device_address[0] = 1;
                                                        _process_counter = 0;
                                                end
                                        endcase
                        32'd6:
                                if (divider_tick)
                                        case (process_counter)
                                                0: begin
                                                        _serial_clock = 1;
                                                        _process_counter = 1;
                                                end
                                                1:
                                                        if (external_serial_clock == 1) begin
                                                                _last_acknowledge = 0;
                                                                _process_counter = 2;
                                                        end
                                                2: begin
                                                        _serial_clock = 0;
                                                        _bit_counter = bit_counter - 1;
                                                        _process_counter = 3;
                                                end
                                                3: begin
                                                        if (bit_counter == 0) begin
                                                                if (DATA_WIDTH == 16) begin
                                                                        _post_state = 32'd13;
                                                                        _post_serial_data = 0;
                                                                end
                                                                else begin
                                                                        _post_state = 32'd7;
                                                                        _post_serial_data = 0;
                                                                end
                                                                _state = 32'd3;
                                                                _bit_counter = 8;
                                                        end
                                                        else
                                                                _serial_data = saved_device_address[bit_counter - 1];
                                                        _process_counter = 0;
                                                end
                                        endcase
                        32'd13:
                                if (divider_tick)
                                        case (process_counter)
                                                0: begin
                                                        _serial_clock = 1;
                                                        _process_counter = 1;
                                                end
                                                1:
                                                        if (external_serial_clock == 1) begin
                                                                _last_acknowledge = 0;
                                                                _process_counter = 2;
                                                        end
                                                2: begin
                                                        _serial_clock = 0;
                                                        _miso_data[bit_counter + 7] = external_serial_data;
                                                        _bit_counter = bit_counter - 1;
                                                        _process_counter = 3;
                                                end
                                                3: begin
                                                        if (bit_counter == 0) begin
                                                                _post_state = 32'd7;
                                                                _state = 32'd14;
                                                                _bit_counter = 8;
                                                                _serial_data = 0;
                                                        end
                                                        _process_counter = 0;
                                                end
                                        endcase
                        32'd7:
                                if (divider_tick)
                                        case (process_counter)
                                                0: begin
                                                        _serial_clock = 1;
                                                        _process_counter = 1;
                                                end
                                                1:
                                                        if (external_serial_clock == 1) begin
                                                                _last_acknowledge = 0;
                                                                _process_counter = 2;
                                                        end
                                                2: begin
                                                        _serial_clock = 0;
                                                        _miso_data[bit_counter - 1] = external_serial_data;
                                                        _bit_counter = bit_counter - 1;
                                                        _process_counter = 3;
                                                end
                                                3: begin
                                                        if (bit_counter == 0) begin
                                                                _state = 32'd8;
                                                                _serial_data = 0;
                                                        end
                                                        _process_counter = 0;
                                                end
                                        endcase
                        32'd8:
                                if (divider_tick)
                                        case (process_counter)
                                                0: begin
                                                        _serial_clock = 1;
                                                        _serial_data = 1;
                                                        _process_counter = 1;
                                                end
                                                1:
                                                        if (external_serial_clock == 1) begin
                                                                _last_acknowledge = 0;
                                                                _process_counter = 2;
                                                        end
                                                2: begin
                                                        _process_counter = 3;
                                                        _serial_clock = 0;
                                                end
                                                3: begin
                                                        _state = 32'd9;
                                                        _process_counter = 0;
                                                        _serial_data = 0;
                                                end
                                        endcase
                        32'd14:
                                if (divider_tick)
                                        case (process_counter)
                                                0: begin
                                                        _serial_clock = 1;
                                                        _process_counter = 1;
                                                        _serial_data = 0;
                                                end
                                                1:
                                                        if (external_serial_clock == 1) begin
                                                                _last_acknowledge = 0;
                                                                _process_counter = 2;
                                                        end
                                                2: begin
                                                        _process_counter = 3;
                                                        _serial_clock = 0;
                                                end
                                                3: begin
                                                        _state = post_state;
                                                        _process_counter = 0;
                                                end
                                        endcase
                        32'd9:
                                if (divider_tick)
                                        case (process_counter)
                                                0: begin
                                                        _serial_clock = 1;
                                                        _process_counter = 1;
                                                end
                                                1:
                                                        if (external_serial_clock == 1) begin
                                                                _last_acknowledge = 0;
                                                                _process_counter = 2;
                                                        end
                                                2: begin
                                                        _process_counter = 3;
                                                        _serial_data = 1;
                                                end
                                                3: _state = 32'd0;
                                        endcase
                endcase
        end
        always @(posedge clock)
                if (!reset_n) begin
                        state <= 32'd0;
                        post_state <= 32'd0;
                        process_counter <= 0;
                        bit_counter <= 0;
                        last_acknowledge <= 0;
                        miso_data <= 0;
                        saved_read_write <= 0;
                        divider_counter <= 0;
                        saved_device_address <= 0;
                        saved_register_address <= 0;
                        saved_mosi_data <= 0;
                        serial_clock <= 0;
                        serial_data <= 0;
                        saved_mosi_data <= 0;
                        post_serial_data <= 0;
                        busy <= 0;
                        error <= 0;
                end
                else begin
                        state <= _state;
                        post_state <= _post_state;
                        process_counter <= _process_counter;
                        bit_counter <= _bit_counter;
                        last_acknowledge <= _last_acknowledge;
                        miso_data <= _miso_data;
                        saved_read_write <= _saved_read_write;
                        divider_counter <= _divider_counter;
                        saved_device_address <= _saved_device_address;
                        saved_register_address <= _saved_register_address;
                        saved_mosi_data <= _saved_mosi_data;
                        serial_clock <= _serial_clock;
                        serial_data <= _serial_data;
                        post_serial_data <= _post_serial_data;
                        busy <= _busy;
                        error <= _error;
                end
       //initial _sv2v_0 = 0;
endmodule