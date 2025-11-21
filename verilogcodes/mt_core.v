`include "defines.v"

module mt_core (
    input wire clk,
    input wire rst
);

    // --- PIPELINE REGISTERS ---
    reg       curr_fetch_thread;
    
    // IF/ID
    reg [15:0] if_id_instr;
    reg        if_id_thread;

    // ID/EX
    reg [3:0]  id_ex_op;
    reg [3:0]  id_ex_dest;
    reg [15:0] id_ex_val1;
    reg [15:0] id_ex_val2;
    reg        id_ex_thread;

    // EX/WB
    reg [3:0]  ex_wb_dest;
    reg [15:0] ex_wb_result;
    reg        ex_wb_thread;
    reg        ex_wb_valid;
    reg        ex_wb_branch_taken;
    reg [7:0]  ex_wb_branch_target;

    // Wires
    wire [15:0] rf_r1, rf_r2;
    wire [7:0]  current_pc;
    wire [15:0] fetch_instr;

    // --- INSTANTIATIONS ---

    context_manager ctx_mgr (
        .clk(clk),
        .rst(rst),
        .fetch_thread_id(curr_fetch_thread),
        .fetch_pc(current_pc),
        .wb_valid(ex_wb_valid),
        .wb_thread_id(ex_wb_thread),
        .branch_taken(ex_wb_branch_taken),
        .branch_target(ex_wb_branch_target)
    );

    imem instr_mem (
        .pc(current_pc),
        .instr(fetch_instr)
    );

    regfile rf (
        .clk(clk),
        .rst(rst),
        .r_addr1(if_id_instr[7:4]),
        .r_addr2(if_id_instr[3:0]),
        .r_thread_id(if_id_thread),
        .r_data1(rf_r1),
        .r_data2(rf_r2),
        .w_addr(ex_wb_dest),
        .w_data(ex_wb_result),
        .w_thread_id(ex_wb_thread),
        .w_en(ex_wb_valid) 
    );

    // --- STAGE 1: FETCH ---
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            curr_fetch_thread <= 0;
            if_id_instr <= 16'd0;
            if_id_thread <= 0;
        end else begin
            if_id_instr <= fetch_instr;
            if_id_thread <= curr_fetch_thread;
            curr_fetch_thread <= ~curr_fetch_thread;
        end
    end

// --- STAGE 2: DECODE ---
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            id_ex_op <= `OP_NOP;
            id_ex_dest <= 0;
            id_ex_val1 <= 0;
            id_ex_val2 <= 0;
            id_ex_thread <= 0;
        end else begin
            // --- FLUSH LOGIC (BUG FIXED) ---
            // Removed "&& ex_wb_valid" check. 
            // If branch_taken is 1, it's a real branch, so we must flush.
            if (ex_wb_branch_taken && (ex_wb_thread == if_id_thread)) begin
                id_ex_op <= `OP_NOP; // Kill the zombie instruction
                id_ex_dest <= 0;
                id_ex_thread <= if_id_thread; 
            end 
            else begin
                // Normal Decode Logic
                id_ex_op <= if_id_instr[15:12];
                id_ex_dest <= if_id_instr[11:8];
                id_ex_thread <= if_id_thread;
                
                if (if_id_instr[15:12] == `OP_LDI) begin
                    id_ex_val1 <= {12'b0, if_id_instr[7:4]}; 
                    id_ex_val2 <= {12'b0, if_id_instr[3:0]}; 
                end 
                else if (if_id_instr[15:12] == `OP_BNZ) begin
                    // BNZ FORMAT: {OP, Target_High, Reg_Check, Target_Low}
                    id_ex_val1 <= rf_r1; 
                    id_ex_val2 <= {8'b0, if_id_instr[11:8], if_id_instr[3:0]}; 
                end 
                else begin
                    id_ex_val1 <= rf_r1;
                    id_ex_val2 <= rf_r2;
                end
            end
        end
    end

    // --- STAGE 3: EXECUTE ---
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ex_wb_result <= 0;
            ex_wb_dest <= 0;
            ex_wb_thread <= 0;
            ex_wb_valid <= 0;
            ex_wb_branch_taken <= 0;
            ex_wb_branch_target <= 0;
        end else begin
            ex_wb_branch_taken <= 0; // Default to Not Taken
            ex_wb_branch_target <= 0;

            case (id_ex_op)
                `OP_ADD: ex_wb_result <= id_ex_val1 + id_ex_val2;
                `OP_SUB: ex_wb_result <= id_ex_val1 - id_ex_val2;
                `OP_AND: ex_wb_result <= id_ex_val1 & id_ex_val2;
                `OP_OR:  ex_wb_result <= id_ex_val1 | id_ex_val2;
                `OP_LDI: ex_wb_result <= {id_ex_val1[3:0], id_ex_val2[3:0]};

                `OP_BNZ: begin 
                    ex_wb_result <= 0;
                    if (id_ex_val1 != 0) begin
                        ex_wb_branch_taken <= 1;
                        ex_wb_branch_target <= id_ex_val2[7:0];
                    end
                end
                
                default: ex_wb_result <= 0;
            endcase

            ex_wb_dest <= id_ex_dest;
            ex_wb_thread <= id_ex_thread;
            ex_wb_valid <= (id_ex_op != `OP_NOP) && (id_ex_op != `OP_BNZ);
        end
    end
    // --- PERFORMANCE METRICS ---
    reg [31:0] cycle_count;
    reg [31:0] instr_count_t0;
    reg [31:0] instr_count_t1;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cycle_count <= 0;
            instr_count_t0 <= 0;
            instr_count_t1 <= 0;
        end else begin
            cycle_count <= cycle_count + 1;

            // Count completed instructions (Valid Writebacks)
            // Excluding the final "Spin" loops which are just NOPs effectively
            if (ex_wb_valid && !ex_wb_branch_taken) begin
                if (ex_wb_thread == 0) instr_count_t0 <= instr_count_t0 + 1;
                if (ex_wb_thread == 1) instr_count_t1 <= instr_count_t1 + 1;
            end
        end
    end

endmodule