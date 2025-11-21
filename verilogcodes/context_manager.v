`include "defines.v"

module context_manager (
    input wire clk,
    input wire rst,
    
    // -- FETCH INTERFACE --
    input wire        fetch_thread_id, 
    output wire [7:0] fetch_pc,
    
    // -- WRITEBACK / UPDATE INTERFACE --
    input wire        wb_valid,       
    input wire        wb_thread_id,   
    input wire        branch_taken,    // From EX/WB stage
    input wire [7:0]  branch_target    // From EX/WB stage
);

    reg [7:0] pc_table [0:1];

    // Output the PC for the thread requesting a fetch
    assign fetch_pc = pc_table[fetch_thread_id];
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pc_table[0] <= 8'd0;
            pc_table[1] <= 8'd100;
        end else begin
            // 1. Default: Increment the Fetching Thread's PC
            pc_table[fetch_thread_id] <= pc_table[fetch_thread_id] + 2;

            // 2. Override: If a Branch is TAKEN, update PC immediately.
            // BUG FIX: We removed "&& wb_valid" because BNZ instrs have valid=0
            if (branch_taken) begin
                pc_table[wb_thread_id] <= branch_target;
            end
        end
    end

endmodule