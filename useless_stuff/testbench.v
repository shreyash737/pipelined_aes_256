`timescale 1ns/1ps

module firstcode_tb;

    // Testbench signals (reg for inputs, wire for output)
    reg a;
    reg b;
    wire out;

    // Instantiate the DUT
    firstcode dut (
        .a(a),
        .b(b),
        .out(out)
    );

    initial begin
        // Monitor changes
        $monitor("Time=%0t | a=%b b=%b -> out=%b", $time, a, b, out);

        // Apply test vectors
        a = 0; b = 0; #10;
        a = 0; b = 1; #10;
        a = 1; b = 0; #10;
        a = 1; b = 1; #10;

        // End simulation
        $finish;
    end

initial begin    
    $dumpfile("wave.vcd");
    $dumpvars(0,firstcode_tb);
end

endmodule

