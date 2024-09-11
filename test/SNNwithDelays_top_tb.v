`timescale 1ns/1ps

module SNNwithDelays_top_tb;

    parameter CLK_PERIOD = 10; // Clock period in ns
    parameter WAIT_TIME = 100; // Wait time between stimulus applications in ns

    reg clk;
    reg reset;
    reg enable;
    reg delay_clk;
    reg [23:0] input_spikes;
    reg [(24*8+8*2)*2-1:0] weights;
    reg [5:0] threshold;
    reg [5:0] decay;
    reg [5:0] refractory_period;
    reg [(8*24+8*2)*4-1:0] delays;
    wire [(8+2)*6-1:0] membrane_potential_out;
    wire [7:0] output_spikes_layer1;
    wire [1:0] output_spikes;

    // Instantiate the SNNwithDelays_top module
    SNNwithDelays_top uut (
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .delay_clk(delay_clk),
        .input_spikes(input_spikes),
        .weights(weights),
        .threshold(threshold),
        .decay(decay),
        .refractory_period(refractory_period),
        .delays(delays),
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
            weights = 0;
            threshold = 0;
            decay = 0;
            refractory_period = 0;
            delays = 0;
            #10 reset = 0;
        end
    endtask

    // Task to apply stimulus
    task apply_stimulus;
        input [23:0] i_input_spikes;
        input [(24*8+8*2)*2-1:0] i_weights;
        input [5:0] i_threshold;
        input [5:0] i_decay;
        input [5:0] i_refractory_period;
        input [(8*24+8*2)*4-1:0] i_delays;
        input integer wait_time;
        begin
            input_spikes = i_input_spikes;
            weights = i_weights;
            threshold = i_threshold;
            decay = i_decay;
            refractory_period = i_refractory_period;
            delays = i_delays;
            #wait_time; // Wait for the specified time
        end
    endtask

    // Test cases
    initial begin
        // Initialize inputs
        initialize_inputs();

        // Test Case 1: All weights set to 00 (1 in 2-bit), threshold = A, input_spikes set to 1, all others = 0
        apply_stimulus(24'hFFFFFF, {(24*8+8*2)*2{1'b0}}, 6'hA, 6'h00, 6'h00, {(8*24+8*2)*4{1'b0}}, WAIT_TIME);
        #WAIT_TIME;

        // Test Case 2: Weights as above, threshold = B, decay = 0, delays = 1
        apply_stimulus(24'hFFFFFF, {(24*8+8*2)*2{1'b0}}, 6'hB, 6'h00, 6'h00, {(8*24+8*2)*4{1'b1}}, WAIT_TIME);
        #WAIT_TIME;

        // Test Case 3: Increment delay values and delays
        apply_stimulus(24'hFFFFFF, {(24*8+8*2)*2{1'b0}}, 6'hB, 6'h00, 6'h00, {(8*24+8*2)*4{2'b10}}, WAIT_TIME);
        #WAIT_TIME;

        // Test Case 4: decay = 1, all delays = 0
        apply_stimulus(24'hFFFFFF, {(24*8+8*2)*2{1'b0}}, 6'hB, 6'h01, 6'h00, {(8*24+8*2)*4{1'b0}}, WAIT_TIME);
        #WAIT_TIME;

        // Test Case 5: decay = 2, all delays = 0
        apply_stimulus(24'hFFFFFF, {(24*8+8*2)*2{1'b0}}, 6'hB, 6'h02, 6'h00, {(8*24+8*2)*4{1'b0}}, WAIT_TIME);
        #WAIT_TIME;

        // Test Case 6: decay = 0, refractory period = 1
        apply_stimulus(24'hFFFFFF, {(24*8+8*2)*2{1'b0}}, 6'hB, 6'h00, 6'h01, {(8*24+8*2)*4{1'b0}}, WAIT_TIME);
        #WAIT_TIME;

        // Test Case 7: decay = 0, refractory period = 2
        apply_stimulus(24'hFFFFFF, {(24*8+8*2)*2{1'b0}}, 6'hB, 6'h00, 6'h02, {(8*24+8*2)*4{1'b0}}, WAIT_TIME);
        #WAIT_TIME;

        // Test Case 8: decay = 1, refractory period = 1
        apply_stimulus(24'hFFFFFF, {(24*8+8*2)*2{1'b0}}, 6'hB, 6'h01, 6'h01, {(8*24+8*2)*4{1'b0}}, WAIT_TIME);
        #WAIT_TIME;

        // Finish simulation
        $finish;
    end

endmodule
