`timescale 1ns / 1ps

module tb_tt_um_chatgpt_snn_with_delays_paolaunisa;

    // Parameters
    parameter CLOCK_PERIOD = 1000;       // 20 ns clock period -- system clock freq = 50 MHz
    parameter SERIAL_CLOCK_PERIOD = 1000; // 1000 ns clock period -- SCL freq = 1 MHz
    parameter WAIT_CYCLES = 8;         // Number of clock cycles to wait between operations
    parameter BYTE_SIZE = 8;           // Size of the data byte for SPI transmission

    // Inputs
    reg SCLK;
    reg MOSI;
    reg SS;
    reg RESET;
    reg input_ready;
    reg system_clock;

    // Outputs
    wire MISO;
    wire data_valid_out;
    wire spi_instruction_done;
    wire [1:0] output_spikes;
    wire [7:0] debug_output;
    
    reg [7:0] address_msb;
    reg [7:0] address_lsb;
    reg [7:0] instruction;
    reg [7:0] data_byte;
    
    integer i=0;
    reg [23:0] test_input_spikes=0;
    
    // memory:
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
    
    

    wire [7:0] ui_in;   // Dedicated inputs
    wire [7:0] uo_out;  // Dedicated outputs
    wire [7:0] uio_in;  // IOs: Input path
    wire [7:0] uio_out;  // IOs: Output path
    wire [7:0] uio_oe;   // IOs: Enable path (active high: 0=input, 1=output)
    wire       ena=1;      // always 1 when the design is powered, so you can ignore it
    wire       clk;      // clock
    wire       rst_n;
    
    
    assign rst_n = ! RESET;
    // All output pins must be assigned. If not used, assign to 0.
    assign debug_output = uo_out;
      
    assign uio_oe = 8'b00110100;
    
    //input
    assign ui_in[7:1]=0;
    assign ui_in[0]=input_ready;
    assign uio_in[0]=SS;
    assign uio_in[1]=MOSI;
    assign uio_in[2]=0;
    assign uio_in[3]=SCLK;
    assign uio_in[7:4]=0;
    assign clk=system_clock;
    
    //output
    assign MISO = uio_out[2];
    assign output_spikes = uio_out[5:4];
    assign data_valid_out = uio_out[6];
    assign spi_instruction_done = uio_out[7];
    
    tt_um_chatgpt_snn_with_delays_paolaunisa uut(
        .ui_in(ui_in),    // Dedicated inputs
        .uo_out(uo_out),   // Dedicated outputs
        .uio_in(uio_in),   // IOs: Input path
        .uio_out(uio_out),  // IOs: Output path
        .uio_oe(uio_oe),   // IOs: Enable path (active high: 0=input, 1=output)
        .ena(ena),      // always 1 when the design is powered, so you can ignore it
        .clk(clk),      // clock
        .rst_n(rst_n)     // reset_n - low to reset
    );
    
    
    
//    spiking_network_top uut(
//    .system_clock(system_clock),
//    .reset(RESET),
//    .SCLK(SCLK),
//    .MOSI(MOSI),
//    .SS(SS),
//    .input_ready(input_ready),
//    .MISO(MISO),
//    .debug_output(debug_output),
//    .output_spikes(output_spikes),
//    .spi_instruction_done(spi_instruction_done),
//    .data_valid_out(data_valid_out)
//    );

    // System Clock generation 
    initial begin
        SCLK = 0;
        forever begin
            #(SERIAL_CLOCK_PERIOD / 2) SCLK = ~SCLK;
        end
    end

    // SPI Clock generation 
    initial begin
        system_clock = 0;
        forever begin
            #(CLOCK_PERIOD / 2) system_clock = ~system_clock;
        end
    end

    // Test stimulus
    initial begin
        
        // Apply reset
        input_ready=0;
        MOSI=0;
        SS=1;
        address_msb=8'h00;
        address_lsb=8'h00;
        instruction=8'h00;
        data_byte=8'h00;
        apply_reset();
    
        wait_cycles(1);
        
        //////////////////////////////////////////////////////////////////////////////////
        // Test case 1: Write into memory
        // 1.1 Write 0xA5 into the memory at the address 0x34
        address_msb=8'h12;
        address_lsb=8'h34;
        instruction=8'h01;
        data_byte=8'hA5;
        execute_instr(address_msb,address_lsb,instruction,data_byte);
        
        // 1.2 Write 0xFF into the memory at the address 0x00
        address_msb=8'h12;
        address_lsb=8'h00;
        instruction=8'h01;
        data_byte=8'hFF;
        execute_instr(address_msb,address_lsb,instruction,data_byte);
        
        //////////////////////////////////////////////////////////////////////////////////
        // Test case 2: Write into clk_div register -- clkd_div_reg_address=6
        write_clk_div(8'hB6); 
//        execute_instr(8'h13,8'h06,8'h05,8'hB6);  //(address_msb,address_lsb,instruction,data_byte); // Instruction to write into clk_div register 
        wait_cycles(4);
 
        //////////////////////////////////////////////////////////////////////////////////
        // Test case 3: Write into input spike registers -- spike_reg_address=0,1,2
        test_input_spikes = 24'hFEDCBA; // Example 24-bit value input spikes
        write_input_spikes(test_input_spikes);
        
        //////////////////////////////////////////////////////////////////////////////////
        // Test case 4: Write into debug config register  debug_reg_address=163 (8'hA3)
        write_debug_config(8'hD8);
        wait_cycles(4);
//        execute_instr(8'h07,8'hA3,8'h09,8'hD8);  //(address_msb,address_lsb,instruction,data_byte);
//        wait_cycles(4);

        //////////////////////////////////////////////////////////////////////////////////
        // Test case 5: Read from memory
        execute_instr(8'h45,8'h34,8'h00,8'h00);  //(address_msb,address_lsb,instruction,data_byte); // 00=dummy data to send to spi slave 
        wait_cycles(4);
        
        //////////////////////////////////////////////////////////////////////////////////
        // Test case 6 : writing to all addresses in the memory
        // Initialize data byte
        data_byte = 8'h01; // Start with 1
        address_msb = 8'h00;
        instruction = 8'h01; // instruction to write into the memory
        for (i = 3; i <= 163; i = i + 1) begin
            address_lsb = i; // Increment LSB address each iteration
            // Execute instruction
            execute_instr(address_msb, address_lsb, instruction, data_byte);
            // Increment data byte by multiplying by 2, saturate at 255 (8'hFF)
            data_byte = (data_byte <= 8'h7F) ? data_byte * 2 : 8'h01;
            wait_cycles(2);
        end

        //////////////////////////////////////////////////////////////////////////////////
        // Test case 7: Write into clk_div register -- clkd_div_reg_address=6
         write_clk_div(8'h45); 
//        execute_instr(8'h13,8'h06,8'h05,8'h45);  //(address_msb,address_lsb,instruction,data_byte); // Instruction to write into clk_div register 
        wait_cycles(4);

        // Test case 8: Write into input spike register spike_reg_address=0,1,2
        test_input_spikes = 24'h654321; // Example 24-bit value input spikes
        write_input_spikes(test_input_spikes);        

        // Test case 9: Write into debug config register  debug_reg_address=163 (8'hA3)
        write_debug_config(8'hF3);
//        execute_instr(8'h07,8'hA3,8'h09,8'hF3);  //(address_msb,address_lsb,instruction,data_byte);
        wait_cycles(4);

        write_parameters(8'h00,8'h00,8'h05,8'h00,8'h00,8'h00); //decay,refractory_period,threshold,div_value,delays,debug_config_in);
        
        write_weights(2'b00); 
        test_input_spikes = 24'hFFFFFF;
        write_input_spikes(test_input_spikes);
        
        // End of parameter-input writing
        #(100 * SERIAL_CLOCK_PERIOD);
        
        // Start computation
        input_ready=1;

        write_parameters(8'h1F,8'h17,8'h19,8'h03,8'hA9,8'hCB); //decay,refractory_period,threshold,div_value,delays,debug_config_in);
        
        write_weights(2'b10); 
        test_input_spikes = 24'hFFFFFF;
        write_input_spikes(test_input_spikes);
        
        // End of parameter-input writing
        #(100 * SERIAL_CLOCK_PERIOD);
        
        
        // Finish simulation
        #(1000 * CLOCK_PERIOD);
        $stop;
    end

    // Task to apply reset
    task apply_reset;
        begin
            RESET = 1;
            #(2 * SERIAL_CLOCK_PERIOD);
            RESET = 0;
        end
    endtask

    // Task to send a byte of data over MOSI
    task send_byte;
        input [7:0] byte;
        integer i;
        begin
            #(SERIAL_CLOCK_PERIOD);
            #(SERIAL_CLOCK_PERIOD/4);
            SS=0; //activate SS
            for (i = 0; i < BYTE_SIZE; i = i + 1) begin
                MOSI = byte[BYTE_SIZE - 1 - i];
                #(SERIAL_CLOCK_PERIOD); // Wait for one clock cycle
            end
            SS=1; //deactivate SS
            #(SERIAL_CLOCK_PERIOD/4);
            #(SERIAL_CLOCK_PERIOD/2);
        end
    endtask

    // Task to wait for a number of serial clock cycles
    task wait_cycles(input integer num_cycles);
        integer i;
        begin
            for (i = 0; i < num_cycles; i = i + 1) begin
                #(SERIAL_CLOCK_PERIOD);
            end
        end
    endtask
    
    // Task to execute an instruction
    task execute_instr;
        input [7:0] address_msb;
        input [7:0] address_lsb;
        input [7:0] instruction;
        input [7:0] data_byte;
        begin
            send_byte(address_msb);  // send_address_msb - Example MSB address
            wait_cycles(2);
            send_byte(address_lsb);  // send_address_lsb - Example LSB address
            wait_cycles(2);
            send_byte(instruction);  // send_instruction - Example instruction: Write into memory
            wait_cycles(2);
            send_byte(data_byte);  // send_data_byte - Example data byte to write
            wait_cycles(2);
        end
    endtask   

    //Write into input spike registers -- spike_reg_address=0,1,2
    task write_input_spikes; 
        input [23:0] input_spikes;
        integer i;
        reg [7:0] data_byte;
        begin
            // Loop through each byte of input_spikes
            for (i = 0; i < 3; i = i + 1) begin
                // Extract the correct byte from input_spikes
                data_byte = input_spikes[(i*8) +: 8];
                // Execute the correct instruction (h07:write input spike into the memory) with the corresponding address (0,1,2) and data_byte 
                execute_instr(8'h00, 8'h00 + i, 8'h07, data_byte);  // (address_msb, address_lsb, instruction, data_byte);
                wait_cycles(1);
            end
        end
    endtask

    //Write parameters into the memory
    task write_parameters;
        input [7:0] decay,refractory_period,threshold,div_value,delays,debug_config_in;
        integer i;
        reg [7:0] data_byte;
        begin
            // Execute the correct instruction with the corresponding address and data_byte 
            execute_instr(8'h00, 8'h03, 8'h01, decay);  // (address_msb, address_lsb, instruction, data_byte); (h01:write into the memory)
            wait_cycles(1);
            execute_instr(8'h00, 8'h04, 8'h01, refractory_period);  // (address_msb, address_lsb, instruction, data_byte); (h01:write into the memory)
            wait_cycles(1);
            execute_instr(8'h00, 8'h05, 8'h01, threshold);  // (address_msb, address_lsb, instruction, data_byte); (h01:write into the memory)
            wait_cycles(1);
            write_clk_div( div_value); 
//            execute_instr(8'h00, 8'h06, 8'h05, div_value);  // (address_msb, address_lsb, instruction, data_byte); (h05:write div_value into the memory)
            wait_cycles(1);
            
            execute_instr(8'h00, 8'h67, 8'h01, delays);  // (address_msb, address_lsb, instruction, data_byte); (h01:write into the memory)
            wait_cycles(1);
            
            // write the same delays value into addresses from 0x3B to 0xA2 (decimal 59 to 162)
            for (i = 59; i <= 162; i = i + 1) begin
                execute_instr(8'h00, i[7:0], 8'h07, delays);  // (address_msb, address_lsb, instruction, data_byte); (h01:write into the memory)
                wait_cycles(1);
            end 
            
            write_debug_config(debug_config_in);
//            execute_instr(8'h00, 8'hA3, 8'h09, debug_config_in);  // (address_msb, address_lsb, instruction, data_byte); (h09:write debug_config_in into the memory)
            wait_cycles(1);                        
        end
    endtask
    
    // Write into clk_div register -- clkd_div_reg_address=6
    task write_clk_div;
        input [7:0] clk_div_value;
        begin
            execute_instr(8'h00,8'h06,8'h05,clk_div_value);  //(address_msb,address_lsb,instruction,data_byte); // Instruction to write into clk_div register 
            wait_cycles(1);
        end
    endtask
    
    
    // Write into debug_config_value register -- debug_config_value_reg_address=A3
    task write_debug_config;
        input [7:0] debug_config_value;
        begin
            execute_instr(8'h00,8'hA3,8'h09,debug_config_value);  //(address_msb,address_lsb,instruction,data_byte); // Instruction to write into debug_config_value register 
            wait_cycles(1);
        end
    endtask
    
    
    task write_weights;
        input [1:0] weight;
        integer i;
        reg [7:0] weight_byte;
        begin
            // Repeat the 2-bit weight four times to fill the 8-bit weight_byte
            weight_byte = {4{weight}};  // Replicate the 2-bit weight 4 times to create an 8-bit value
        
            // write the same weight value into addresses [0x07,0x3A] decimal:[7 - 58]
            for (i = 7; i <= 58; i = i + 1) begin
                execute_instr(8'h00, i[7:0], 8'h01, weight_byte);  // (address_msb, address_lsb, instruction, data_byte);
                wait_cycles(1);
            end
        end
    endtask
    
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

endmodule





