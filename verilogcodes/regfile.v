`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 20.11.2025 10:39:53
// Design Name: 
// Module Name: regfile
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module regfile (
    input wire clk,
    input wire rst,
    // Read Ports
    input wire [3:0] r_addr1,
    input wire [3:0] r_addr2,
    input wire       r_thread_id, // 0 for Thread 0, 1 for Thread 1
    output reg [15:0] r_data1,
    output reg [15:0] r_data2,
    
    // Write Port
    input wire [3:0]  w_addr,
    input wire [15:0] w_data,
    input wire        w_thread_id,
    input wire        w_en
);

    // 2 Threads, 16 Registers each, 16-bit wide
    // Addressed as memory[thread_id][reg_index]
    reg [15:0] regs [0:1][0:15]; 
    integer i, j;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Initialize with some dummy values for testing
            for (i=0; i<2; i=i+1) begin
                for (j=0; j<16; j=j+1) begin
                    regs[i][j] <= (i == 0) ? j : j + 20; // T0 gets 0..15, T1 gets 20..35
                end
            end
        end else if (w_en) begin
            regs[w_thread_id][w_addr] <= w_data;
            $display("WriteBack: Thread %0d, Reg %0d = %h", w_thread_id, w_addr, w_data);
        end
    end

    // Asynchronous Read
    always @(*) begin
        r_data1 = regs[r_thread_id][r_addr1];
        r_data2 = regs[r_thread_id][r_addr2];
    end

endmodule
