`timescale 1ns/1ps

module TwoLayerNetwork_debug_tb;

    parameter M1 = 24;  // Number of input spikes for the first layer
    parameter N1 = 8;   // Number of neurons in the first layer
    parameter N2 = 2;   // Number of neurons in the second layer
    parameter CLK_PERIOD = 10; // Clock period in ns
    parameter WAIT_TIME = 100; // Wait time between stimulus applications in ns

    reg clk;
    reg reset;
    reg enable;
    reg delay_clk;
    reg [M1-1:0] input_spikes;
    reg [N1*M1*2-1:0] weights1;
    reg [N2*N1*2-1:0] weights2;
    reg [5:0] threshold1;
    reg [5:0] decay1;
    reg [5:0] refractory_period1;
    reg [5:0] threshold2;
    reg [5:0] decay2;
    reg [5:0] refractory_period2;
    reg [N1*M1*3-1:0] delay_values1;
    reg [N1*M1-1:0] delays1;
    reg [N2*N1*3-1:0] delay_values2;
    reg [N2*N1-1:0] delays2;
    wire [(N1+N2)*6-1:0] membrane_potential_out;
    wire [N1-1:0] output_spikes_layer1;
    wire [N2-1:0] output_spikes;

    // Instantiate the TwoLayerNetwork_debug module
    TwoLayerNetwork_debug #(
        .M1(M1),
        .N1(N1),
        .N2(N2)
    ) uut (
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .delay_clk(delay_clk),
        .input_spikes(input_spikes),
        .weights1(weights1),
        .weights2(weights2),
        .threshold1(threshold1),
        .decay1(decay1),
        .refractory_period1(refractory_period1),
        .threshold2(threshold2),
        .decay2(decay2),
        .refractory_period2(refractory_period2),
        .delay_values1(delay_values1),
        .delays1(delays1),
        .delay_values2(delay_values2),
        .delays2(delays2),
        .membrane_potential_out(membrane_potential_out),
        .output_spikes_layer1(output_spikes_layer1),
        .output_spikes(output_spikes)
    );

    // Generate clock signal
    initial begin
        clk = 0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    // Generate delay clock signal
    initial begin
        delay_clk = 0;
        forever #(CLK_PERIOD / 2) delay_clk = ~delay_clk;
    end

    // Task to initialize the inputs
    task initialize_inputs;
        begin
            reset = 1;
            enable = 1; // Enable is always active
            input_spikes = 0;
            weights1 = 0;
            weights2 = 0;
            threshold1 = 0;
            decay1 = 0;
            refractory_period1 = 0;
            threshold2 = 0;
            decay2 = 0;
            refractory_period2 = 0;
            delay_values1 = 0;
            delays1 = 0;
            delay_values2 = 0;
            delays2 = 0;
            #10 reset = 0;
        end
    endtask

    // Task to apply stimulus
    task apply_stimulus;
        input [M1-1:0] i_input_spikes;
        input [N1*M1*2-1:0] i_weights1;
        input [N2*N1*2-1:0] i_weights2;
        input [5:0] i_threshold1;
        input [5:0] i_decay1;
        input [5:0] i_refractory_period1;
        input [5:0] i_threshold2;
        input [5:0] i_decay2;
        input [5:0] i_refractory_period2;
        input [N1*M1*3-1:0] i_delay_values1;
        input [N1*M1-1:0] i_delays1;
        input [N2*N1*3-1:0] i_delay_values2;
        input [N2*N1-1:0] i_delays2;
        input integer wait_time;
        begin
            input_spikes = i_input_spikes;
            weights1 = i_weights1;
            weights2 = i_weights2;
            threshold1 = i_threshold1;
            decay1 = i_decay1;
            refractory_period1 = i_refractory_period1;
            threshold2 = i_threshold2;
            decay2 = i_decay2;
            refractory_period2 = i_refractory_period2;
            delay_values1 = i_delay_values1;
            delays1 = i_delays1;
            delay_values2 = i_delay_values2;
            delays2 = i_delays2;
            #wait_time; // Wait for the specified time
        end
    endtask

    // Test cases
    initial begin
        // Initialize inputs
        initialize_inputs();

        // Test Case 1: All weights1 and weights2 set to 00 (1 in 2-bit), thresholds set to A, input_spikes set to 1, all others = 0
        apply_stimulus({M1{1'b1}}, {N1*M1{2'b00}}, {N2*N1{2'b00}}, 6'hA, 6'h00, 6'h00, 6'hA, 6'h00, 6'h00, {N1*M1*3{1'b0}}, {N1*M1{1'b0}}, {N2*N1*3{1'b0}}, {N2*N1{1'b0}}, WAIT_TIME);
        #WAIT_TIME;

        // Test Case 2: Weights as above, threshold1 = B, decay1 = 0, delay_values1 = 1, delays1 = 1
        apply_stimulus({M1{1'b1}}, {N1*M1{2'b00}}, {N2*N1{2'b00}}, 6'hB, 6'h00, 6'h00, 6'hA, 6'h00, 6'h00, {N1*M1*3{1'b1}}, {N1*M1{1'b1}}, {N2*N1*3{1'b0}}, {N2*N1{1'b0}}, WAIT_TIME);
        #WAIT_TIME;

        // Test Case 3: Weights as above, decay1 = 0, delay_values1 = 2, delays1 = 2 (incremented by 1)
        apply_stimulus({M1{1'b1}}, {N1*M1{2'b00}}, {N2*N1{2'b00}}, 6'hB, 6'h00, 6'h00, 6'hA, 6'h00, 6'h00, {N1*M1*3{2'b10}}, {N1*M1{2'b10}}, {N2*N1*3{1'b0}}, {N2*N1{1'b0}}, WAIT_TIME);
        #WAIT_TIME;

        // Test Case 4: decay1 = 1, delay_values1 = 0, delays1 = 0
        apply_stimulus({M1{1'b1}}, {N1*M1{2'b00}}, {N2*N1{2'b00}}, 6'hB, 6'h01, 6'h00, 6'hA, 6'h00, 6'h00, {N1*M1*3{1'b0}}, {N1*M1{1'b0}}, {N2*N1*3{1'b0}}, {N2*N1{1'b0}}, WAIT_TIME);
        #WAIT_TIME;

        // Test Case 5: decay1 = 2, delay_values1 = 0, delays1 = 0
        apply_stimulus({M1{1'b1}}, {N1*M1{2'b00}}, {N2*N1{2'b00}}, 6'hB, 6'h02, 6'h00, 6'hA, 6'h00, 6'h00, {N1*M1*3{1'b0}}, {N1*M1{1'b0}}, {N2*N1*3{1'b0}}, {N2*N1{1'b0}}, WAIT_TIME);
        #WAIT_TIME;

        // Test Case 6: decay1 = 0, refractory period1 = 1
        apply_stimulus({M1{1'b1}}, {N1*M1{2'b00}}, {N2*N1{2'b00}}, 6'hB, 6'h00, 6'h01, 6'hA, 6'h00, 6'h00, {N1*M1*3{1'b0}}, {N1*M1{1'b0}}, {N2*N1*3{1'b0}}, {N2*N1{1'b0}}, WAIT_TIME);
        #WAIT_TIME;

        // Test Case 7: decay1 = 0, refractory period1 = 2
        apply_stimulus({M1{1'b1}}, {N1*M1{2'b00}}, {N2*N1{2'b00}}, 6'hB, 6'h00, 6'h02, 6'hA, 6'h00, 6'h00, {N1*M1*3{1'b0}}, {N1*M1{1'b0}}, {N2*N1*3{1'b0}}, {N2*N1{1'b0}}, WAIT_TIME);
        #WAIT_TIME;

        // Test Case 8: decay1 = 1, refractory period1 = 1
        apply_stimulus({M1{1'b1}}, {N1*M1{2'b00}}, {N2*N1{2'b00}}, 6'hB, 6'h01, 6'h01, 6'hA, 6'h00, 6'h00, {N1*M1*3{1'b0}}, {N1*M1{1'b0}}, {N2*N1*3{1'b0}}, {N2*N1{1'b0}}, WAIT_TIME);
        #WAIT_TIME;

        // Finish simulation
        $finish;
    end

endmodule
