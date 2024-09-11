`timescale 1ns / 1ps

module tb_spi_control_unit;

    // Parameters
    parameter CLOCK_PERIOD = 10; // 10 ns clock period (100 MHz)
    parameter WAIT_CYCLES = 8;   // Number of clock cycles to wait

    // Inputs
    reg clk;
    reg reset;
    reg cs;
    reg data_valid;
    reg [7:0] SPI_instruction_reg_in;
    reg [7:0] SPI_instruction_reg_out;

    // Outputs
    wire SPI_address_MSB_reg_en;
    wire SPI_address_LSB_reg_en;
    wire SPI_instruction_reg_en;
    wire clk_div_ready;
    wire clk_div_ready_en;
    wire input_spike_ready;
    wire input_spike_ready_en;
    wire debug_config_ready;
    wire debug_config_ready_en;
    wire write_memory_enable;
    wire spi_instruction_done;
    
    // Instantiate the Unit Under Test (UUT)
    spi_control_unit uut (
        .clk(clk),
        .reset(reset),
        .cs(cs),
        .data_valid(data_valid),
        .SPI_instruction_reg_in(SPI_instruction_reg_in),
        .SPI_instruction_reg_out(SPI_instruction_reg_out),
        .SPI_address_MSB_reg_en(SPI_address_MSB_reg_en),
        .SPI_address_LSB_reg_en(SPI_address_LSB_reg_en),
        .SPI_instruction_reg_en(SPI_instruction_reg_en),
        .clk_div_ready(clk_div_ready),
        .clk_div_ready_en(clk_div_ready_en),
        .input_spike_ready(input_spike_ready),
        .input_spike_ready_en(input_spike_ready_en),
        .debug_config_ready(debug_config_ready),
        .debug_config_ready_en(debug_config_ready_en),
        .write_memory_enable(write_memory_enable),
        .spi_instruction_done(spi_instruction_done)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #(CLOCK_PERIOD / 2) clk = ~clk;
    end

    // Tasks for stimulus generation
    task reset_dut;
        begin
            reset = 1;
            cs = 1;
            data_valid = 0;
            SPI_instruction_reg_in = 8'h00;
            SPI_instruction_reg_out = 8'h00;
            #(2 * CLOCK_PERIOD);
            reset = 0;
        end
    endtask

    task wait_cycles(input integer num_cycles);
        integer i;
        begin
            for (i = 0; i < num_cycles; i = i + 1) begin
                #(CLOCK_PERIOD);
            end
        end
    endtask

    task send_spi_instruction(input [7:0] instr_in, input [7:0] instr_out);
        begin
            cs = 0;
            wait_cycles(WAIT_CYCLES);
            data_valid = 1;
            wait_cycles(1);
            data_valid = 0;
            SPI_instruction_reg_in = instr_in;
            wait_cycles(WAIT_CYCLES);
            data_valid = 1;
            wait_cycles(1);
            data_valid = 0;
            wait_cycles(WAIT_CYCLES);
            data_valid = 1;
            wait_cycles(1);
            data_valid = 0;
            SPI_instruction_reg_out = instr_out;
            wait_cycles(WAIT_CYCLES);
            data_valid = 1;
            wait_cycles(1);
            data_valid = 0;
            cs = 1;
        end
    endtask

    // Test cases
    initial begin
        reset_dut();

        // Case 1: SPI_instruction_reg_in = SPI_instruction_reg_out = h01 Write into the memory
        send_spi_instruction(8'h01, 8'h01);
        wait_cycles(2);

        // Case 2: SPI_instruction_reg_in = SPI_instruction_reg_out = h05 Write into clk_div reg
        send_spi_instruction(8'h05, 8'h05);
        wait_cycles(2);

        // Case 3: SPI_instruction_reg_in = SPI_instruction_reg_out = h07 Write into input spikes reg
        send_spi_instruction(8'h07, 8'h07);
        wait_cycles(2);

        // Case 4: SPI_instruction_reg_in = SPI_instruction_reg_out = h09 Write into debug config reg
        send_spi_instruction(8'h09, 8'h09);
        wait_cycles(2);

        // Case 5: SPI_instruction_reg_in = SPI_instruction_reg_out = h00 Read from the memory
        send_spi_instruction(8'h00, 8'h00);
        wait_cycles(2);

        // Finish simulation
        $stop;
    end

endmodule
