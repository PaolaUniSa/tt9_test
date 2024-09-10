module spiking_network_top (
    input wire system_clock,
    input wire reset,
    input wire SCLK,
    input wire MOSI,
    input wire SS,
    input wire input_ready,
    output wire MISO,
    output wire [8-1:0] debug_output,//[7:0]
    output wire [1:0] output_spikes,
    output wire spi_instruction_done, //additional support signal at protocol level -- added 6Sep2024
    output wire data_valid_out //additional debug signal -- added 6Sep2024
);
    // Internal signals
    wire SNN_enable;
    wire clk_div_ready_reg_out;
    wire input_spike_ready_reg_out;
    wire debug_config_ready_reg_out;
    wire clk_div_ready_sync;
    wire input_spike_ready_sync;
    wire [23:0] input_spikes; 
    wire [6-1:0] decay;
    wire [6-1:0] refractory_period;
    wire [6-1:0] threshold;
    wire [7:0] div_value;
    wire [(24*8+8*2)*2-1:0] weights;
    wire [(24*8+8*2)*4-1:0] delays; // 832
    wire [7:0] debug_config_in;
    wire [(8+2)*6-1:0] membrane_potentials; 
    wire [8-1:0] output_spikes_layer1;
    wire delay_clk;
    wire input_ready_sync;
    wire [164*8-1:0] all_data_out;
    wire debug_config_ready_sync;
    // all_data_out Assignments
    // output wire [161*8-1:0] all_data_out
    // all_data_out:
    // input spikes      = 3*8 LSB ( first 3 bytes)-- addr: 0x00 -0x01 - 0x02
    // decay             = 5:0 bits in the 4° byte -- addr: 0x03
    // refractory_period = 5:0 bits in the 5° byte -- addr: 0x04
    // threshold         = 5:0 bits in the 6° byte -- addr: 0x05
    // div_value         = 7° byte  -- addr: 0x06
    // weights           = (24*8+8*2)*2 = 208 weights*2 bits = 416 bits -> 52 bytes (from 8° to 59°)  -- addr: [0x07,0x3A] decimal:[7 - 58]
    // delays            = (24*8+8*2)*4= 832 bits (104 bytes) (from 60° to 163°) -- addr: [0x3B,0xA2] decimal:[59 - 162]
    // debug_config_in   = 8 bits in the 164° byte -- addr: 0xA3
    // Instantiations
    
    
    
    spi_interface spi_inst (
        .SCLK(SCLK),
        .MOSI(MOSI),
        .SS(SS),
        .RESET(reset),
        .MISO(MISO),
        .clk_div_ready_reg_out(clk_div_ready_reg_out),
        .input_spike_ready_reg_out(input_spike_ready_reg_out),
        .debug_config_ready_reg_out(debug_config_ready_reg_out),
        .all_data_out(all_data_out),
        .spi_instruction_done(spi_instruction_done), //additional support signal at protocol level -- added 6Sep2024
        .data_valid_out(data_valid_out) //additional debug signal -- added 6Sep2024
    );

    clock_divider clk_div_inst (
        .clk(system_clock),
        .reset(reset),
        .enable(clk_div_ready_sync),
        .div_value(div_value),
        .clk_out(delay_clk)
    );

    debug_module debug_inst  (
        .clk(system_clock),
        .rst(reset),
        .en(debug_config_ready_sync),
        .debug_config_in(debug_config_in),
        .membrane_potentials(membrane_potentials),
        .output_spikes_layer1(output_spikes_layer1),
        .debug_output(debug_output)
    );

    assign SNN_enable = input_spike_ready_sync & input_ready_sync;

    SNNwithDelays_top snn_inst (
        .clk(system_clock),
        .reset(reset),
        .enable(SNN_enable), //(input_spike_ready_sync),
        .delay_clk(delay_clk),
        .input_spikes(input_spikes),
        .weights(weights),
        .threshold(threshold),
        .decay(decay),
        .refractory_period(refractory_period),
        .delays(delays),
        .membrane_potential_out(membrane_potentials),
        .output_spikes_layer1(output_spikes_layer1),
        .output_spikes(output_spikes)
    );

    // Synchronizers
    synchronizer input_ready_sync_inst (
        .clk(system_clock),
        .reset(reset),
        .async_signal(input_ready),
        .sync_signal(input_ready_sync)
    );
    
    synchronizer clk_div_sync (
        .clk(system_clock),
        .reset(reset),
        .async_signal(clk_div_ready_reg_out),
        .sync_signal(clk_div_ready_sync)
    );

    synchronizer input_spike_sync (
        .clk(system_clock),
        .reset(reset),
        .async_signal(input_spike_ready_reg_out),
        .sync_signal(input_spike_ready_sync)
    );

    synchronizer debug_config_sync (
        .clk(system_clock),
        .reset(reset),
        .async_signal(debug_config_ready_reg_out),
        .sync_signal(debug_config_ready_sync)
    );

    // all_data_out Assignments
    // output wire [161*8-1:0] all_data_out
    // all_data_out:
    // input spikes      = 3*8 LSB ( first 3 bytes)-- addr: 0x00 -0x01 - 0x02
    // decay             = 5:0 bits in the 4° byte -- addr: 0x03
    // refractory_period = 5:0 bits in the 5° byte -- addr: 0x04
    // threshold         = 5:0 bits in the 6° byte -- addr: 0x05
    // div_value         = 7° byte  -- addr: 0x06
    // weights           = (24*8+8*2)*2 = 208 weights*2 bits = 416 bits -> 52 bytes (from 8° to 59°)  -- addr: [0x07,0x3A] decimal:[7 - 58]
    // delays            = (24*8+8*2)*4= 832 bits (104 bytes) (from 60° to 163°) -- addr: [0x3B,0xA2] decimal:[59 - 162]
    // debug_config_in   = 8 bits in the 164° byte -- addr: 0xA3
	assign input_spikes = all_data_out      [3*8-1 : 0];     // 3 bytes
	assign decay = all_data_out             [4*8-1-2 : 3*8];   // 5:0 bits in the 4° byte
	assign refractory_period = all_data_out [5*8-1-2 : 4*8];   // 5:0 bits in the 5° byte 
	assign threshold = all_data_out         [6*8-1-2 : 5*8];   // 5:0 bits in the 6° byte
    assign div_value = all_data_out         [7*8-1:6*8];     // 7° byte
    assign weights = all_data_out           [59*8-1:7*8];    // (24*8+8*2)*2 = 208 weights*2 bits = 416 bits -> 52 bytes (from 8° to 59°)         
    assign delays = all_data_out            [163*8-1:59*8];  // (24*8+8*2)*4= 832 bits (104 bytes) (from 60° to 163°) 
    assign debug_config_in = all_data_out   [164*8-1:163*8]; // 8 bits in the 164° byte

endmodule   

