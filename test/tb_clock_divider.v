`timescale 1ns/1ps

module tb_clock_divider;

    // Parameters for clock period and wait time
    parameter CLOCK_PERIOD = 10;     // Clock period in ns (e.g., 10 ns for 100 MHz)
    parameter WAIT_TIME = 1000;      // Time to wait in ns for observation

    // Testbench signals
    reg clk;                         // Clock signal
    reg reset;                       // Reset signal
    reg enable;                      // Enable signal
    reg [7:0] div_value;             // Divider value
    wire clk_out;                    // Output clock from DUT

    // Instantiate the clock divider module
    clock_divider uut (
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .div_value(div_value),
        .clk_out(clk_out)
    );

    // Clock generation task
    initial begin
            clk = 0;
            forever #(CLOCK_PERIOD / 2) clk = ~clk; // Toggle clock every half period
    end

    // Reset task
    task apply_reset;
        begin
            reset = 1;
            #20;                         // Apply reset for 20 ns
            reset = 0;
        end
    endtask

    // Enable divider task
    task enable_divider(input [7:0] value);
        begin
            enable = 1;
            div_value = value;
            #WAIT_TIME;                 // Wait for the specified wait time
            enable = 1;
        end
    endtask

    // Test sequence
    initial begin
        // Initialize signals
        reset = 1;
        enable = 0;
        div_value = 8'd0;

        // Apply reset
        apply_reset();

        // Test with div_value = 1 (divide by 4)
        $display("Testing with div_value = 0 (Divide by 2)");
        enable_divider(8'd0);
        $display("Testing with div_value = 1 (Divide by 4)");
        enable_divider(8'd1);

        // Test with div_value = 3 (divide by 8)
        $display("Testing with div_value = 3 (Divide by 8)");
        enable_divider(8'd3);

        // Test with div_value = 7 (divide by 16)
        $display("Testing with div_value = 7 (Divide by 16)");
        enable_divider(8'd7);

        // Test with div_value = 255 (divide by 512)
        $display("Testing with div_value = 255 (Divide by 512)");
        enable_divider(8'd255);
        #1000000000; 
        // Finish simulation
        $stop;
    end

endmodule
