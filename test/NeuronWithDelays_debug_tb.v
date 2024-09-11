`timescale 1ns/1ps

module NeuronWithDelays_debug_tb;

    parameter M = 24; // Number of input spikes and weights
    parameter CLK_PERIOD = 10; // Clock period in ns
    parameter WAIT_TIME = 100; // Wait time between stimulus applications in ns

    reg clk;
    reg reset;
    reg enable;
    reg delay_clk;
    reg [M-1:0] input_spikes;
    reg [M*2-1:0] weights;
    reg [5:0] threshold;
    reg [5:0] decay;
    reg [5:0] refractory_period;
    reg [M*3-1:0] delay_values;
    reg [M-1:0] delays;
    wire [5:0] membrane_potential_out;
    wire spike_out;

    // Instantiate the NeuronWithDelays_debug module
    NeuronWithDelays_debug #(
        .M(M)
    ) uut (
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .delay_clk(delay_clk),
        .input_spikes(input_spikes),
        .weights(weights),
        .threshold(threshold),
        .decay(decay),
        .refractory_period(refractory_period),
        .delay_values(delay_values),
        .delays(delays),
        .membrane_potential_out(membrane_potential_out),
        .spike_out(spike_out)
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
            weights = 0;
            threshold = 0;
            decay = 0;
            refractory_period = 0;
            delay_values = 0;
            delays = 0;
            #10 reset = 0;
        end
    endtask

    // Task to apply stimulus
    task apply_stimulus;
        input [M*2-1:0] i_weights;
        input [5:0] i_threshold;
        input [5:0] i_decay;
        input [5:0] i_refractory_period;
        input [M*3-1:0] i_delay_values;
        input [M-1:0] i_delays;
        input [M-1:0] i_input_spikes;
        input integer wait_time;
        begin
            weights = i_weights;
            threshold = i_threshold;
            decay = i_decay;
            refractory_period = i_refractory_period;
            delay_values = i_delay_values;
            delays = i_delays;
            input_spikes = i_input_spikes;
            #wait_time; // Wait for the specified time
        end
    endtask

    // Test cases
    initial begin
        // Initialize inputs
        initialize_inputs();

        // Case 1: All weights = 00 (1 in 2-bit), threshold = A, input_spikes = 1, all others = 0
        apply_stimulus({M{2'b00}}, 6'hA, 6'h00, 6'h00, {M*3{1'b0}}, {M{1'b0}}, {M{1'b1}}, WAIT_TIME);
        #WAIT_TIME;

        // Case 2: decay = 0, delay_values = 1, delays = 1
        apply_stimulus({M{2'b00}}, 6'hA, 6'h00, 6'h00, {M*3{1'b1}}, {M{1'b1}}, {M{1'b1}}, WAIT_TIME);
        #WAIT_TIME;

        // Case 3: decay = 0, delay_values = 2, delays = 2 (incremented by 1)
        apply_stimulus({M{2'b00}}, 6'hA, 6'h00, 6'h00, {M*3{2'b10}}, {M{2'b10}}, {M{1'b1}}, WAIT_TIME);
        #WAIT_TIME;

        // Case 4: decay = 1, delay_values = 0, delays = 0
        apply_stimulus({M{2'b00}}, 6'hA, 6'h01, 6'h00, {M*3{1'b0}}, {M{1'b0}}, {M{1'b1}}, WAIT_TIME);
        #WAIT_TIME;

        // Case 5: decay = 2, delay_values = 0, delays = 0
        apply_stimulus({M{2'b00}}, 6'hA, 6'h02, 6'h00, {M*3{1'b0}}, {M{1'b0}}, {M{1'b1}}, WAIT_TIME);
        #WAIT_TIME;

        // Case 6: decay = 0, refractory period = 1
        apply_stimulus({M{2'b00}}, 6'hA, 6'h00, 6'h01, {M*3{1'b0}}, {M{1'b0}}, {M{1'b1}}, WAIT_TIME);
        #WAIT_TIME;

        // Case 7: decay = 0, refractory period = 2
        apply_stimulus({M{2'b00}}, 6'hA, 6'h00, 6'h02, {M*3{1'b0}}, {M{1'b0}}, {M{1'b1}}, WAIT_TIME);
        #WAIT_TIME;

        // Case 8: decay = 1, refractory period = 1
        apply_stimulus({M{2'b00}}, 6'hA, 6'h01, 6'h01, {M*3{1'b0}}, {M{1'b0}}, {M{1'b1}}, WAIT_TIME);
        #WAIT_TIME;

        // Finish simulation
        $finish;
    end

endmodule
