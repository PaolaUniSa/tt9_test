module tb_memory;

    // Parameters
    parameter M = 164;
    parameter N = 8;

    // Inputs
    reg [N-1:0] data_in;
    reg [$clog2(M)-1:0] addr;
    reg write_enable;
    reg clk;
    reg reset;

    // Outputs
    wire [N-1:0] data_out;
    wire [M*N-1:0] all_data_out;

    // Instantiate the memory module
    memory  uut (
        .data_in(data_in),
        .addr(addr),
        .write_enable(write_enable),
        .clk(clk),
        .reset(reset),
        .data_out(data_out),
        .all_data_out(all_data_out)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Task for writing to memory
    task write_memory(input [$clog2(M)-1:0] address, input [N-1:0] data);
        begin
            addr = address;
            data_in = data;
            write_enable = 1;
            #10;
            write_enable = 0;
            #10;
        end
    endtask

    // Task for reading from memory
    task read_memory(input [$clog2(M)-1:0] address);
        begin
            write_enable = 0;
            addr = address; 
            #10;
            $display("Address %0d: Data %h", address, data_out);
        end
    endtask

    // Task for displaying all memory data
    task display_all_memory_data;
        begin
            #10;
            $display("All Memory Data: %h", all_data_out);
        end
    endtask

    initial begin
        // Initialize Inputs
        data_in = 0;
        addr = 0;
        write_enable = 0;
        clk = 0;
        reset = 1;

        // Perform initial reset
        #20 reset = 0;

        // Write the first set of 5 8-bit signals
        write_memory(0, 8'hA0);
        write_memory(1, 8'hA1);
        write_memory(2, 8'hA2);
        write_memory(3, 8'hA3);
        write_memory(4, 8'hA4);

        // Write the second set of 5 8-bit signals
        write_memory(0, 8'hB0);
        write_memory(1, 8'hB1);
        write_memory(2, 8'hB2);
        write_memory(3, 8'hB3);
        write_memory(4, 8'hB4);

        // Write the third set of 5 8-bit signals
        write_memory(0, 8'hC0);
        write_memory(1, 8'hC1);
        write_memory(2, 8'hC2);
        write_memory(3, 8'hC3);
        write_memory(4, 8'hC4);

        // Write the fourth set of 5 8-bit signals
        write_memory(0, 8'hD0);
        write_memory(1, 8'hD1);
        write_memory(2, 8'hD2);
        write_memory(3, 8'hD3);
        write_memory(4, 8'hD4);

        // Write the fifth set of 5 8-bit signals
        write_memory(11, 8'hE0);
        write_memory(12, 8'hE1);
        write_memory(13, 8'hE2);
        write_memory(14, 8'hE3);
        write_memory(15, 8'hE4);

        // Disable write
        write_enable = 0;

        // Read and display the memory contents
        read_memory(0);
        read_memory(1);
        read_memory(2);
        read_memory(3);
        read_memory(4);
        
        read_memory(5);
        read_memory(6);
        read_memory(7);
        read_memory(8);
        read_memory(9);
        
        read_memory(11);
        read_memory(12);
        read_memory(13);
        read_memory(14);
        read_memory(15);
        // Display all memory data
        display_all_memory_data();

        // End simulation
        #10 $finish;
    end

endmodule
