`timescale 1ns / 1ps

module tb_mt_core;

    reg clk;
    reg rst;

    mt_core uut (
        .clk(clk),
        .rst(rst)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        $dumpfile("mt_cpu_loop.vcd");
        $dumpvars(0, tb_mt_core);

        rst = 1;
        #10;
        rst = 0;

        // Run enough cycles for the loop to sum 1..10 (approx 6 instrs * 10 loops)
        #1500;
        
        $finish;
    end
endmodule