`timescale 1ns / 1ps

module spi_slave_tb;

    // Parameters
    parameter CLK_PERIOD = 10; // Clock period in ns (100 MHz clock)
    parameter BYTE_SIZE = 8; // Size of the data byte

    // Inputs
    reg SCLK;
    reg MOSI;
    reg SS;
    reg RESET;
    reg [7:0] data_to_send;

    // Outputs
    wire MISO;
    wire [7:0] received_data;
    wire data_valid;
    // Instantiate the SPI slave module
    spi_slave uut (
        .SCLK(SCLK),
        .MOSI(MOSI),
        .SS(SS),
        .RESET(RESET),
        .data_to_send(data_to_send),
        .MISO(MISO),
        .received_data(received_data),
        .data_valid(data_valid)
    );

    // Clock generation (only active when SS is low)
    initial begin
        SCLK = 0;
        forever begin
            if (SS == 0) begin
                #(CLK_PERIOD / 2) SCLK = ~SCLK;
            end else begin
                SCLK = 0;
                #CLK_PERIOD;
            end
        end
    end

    // Stimulus generation
    initial begin
        // Initialize inputs
        MOSI = 0;
        SS = 1; // SS inactive
        RESET = 0;
        data_to_send = 8'b11110001; // Example data to send

        // Apply reset
        RESET = 1;
        #(2 * CLK_PERIOD);
        RESET = 0;

        // Activate slave select
        #(2 * CLK_PERIOD);
        SS = 0;

        // Transmit data from master to slave (MOSI)
        send_byte(8'b11000001); // Example data to send to slave
        #(3*CLK_PERIOD);
        // Deactivate slave select
//        #(CLK_PERIOD*16);
//        SS = 1;
        
        
//        // Activate slave select
//        #(2 * CLK_PERIOD);
//        SS = 0;

        // Transmit data from master to slave (MOSI)
        send_byte(8'b01001011); // Example data to send to slave

        // Deactivate slave select
//        #(CLK_PERIOD*16);
//        SS = 1;

        // Wait and then finish the simulation
        #(10 * CLK_PERIOD);
        $stop;
    end

    // Task to send a byte of data over MOSI
    task send_byte;
        input [7:0] byte;
        integer i;
        begin
            SS = 0; // Activate slave select
            for (i = 0; i < BYTE_SIZE; i = i + 1) begin
                MOSI = byte[BYTE_SIZE - 1 - i];
                #(CLK_PERIOD); // Wait for one clock cycle
            end
            #(CLK_PERIOD/2);
            SS = 1;// Deactivate slave select
        end
    endtask

endmodule
