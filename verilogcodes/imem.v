`include "defines.v"

module imem (
    input  wire [7:0]  pc,
    output reg  [15:0] instr
);

    always @(*) begin
        case(pc)
            // =================================================
            // THREAD 0: SUM 1 to 10 (Result in R0)
            // =================================================
            // Address format for BNZ: {OP, Target_High, Reg, Target_Low}
            
            8'd0: instr = {`OP_LDI, 4'd0, 4'd0, 4'd0};  // R0 = 0 (Sum)
            8'd2: instr = {`OP_LDI, 4'd1, 4'd0, 4'd10}; // R1 = 10 (i)
            8'd4: instr = {`OP_LDI, 4'd2, 4'd0, 4'd1};  // R2 = 1 (Dec)

            // LOOP (Addr 6)
            8'd6: instr = {`OP_ADD, 4'd0, 4'd0, 4'd1};  // Sum += i
            8'd8: instr = {`OP_SUB, 4'd1, 4'd1, 4'd2};  // i--
            
            // BNZ R1 to Addr 6. 
            // Target=06 (High=0, Low=6). Reg=1.
            8'd10: instr = {`OP_BNZ, 4'd0, 4'd1, 4'd6}; 

            // DONE (Spin at 12)
            8'd12: instr = {`OP_BNZ, 4'd0, 4'd0, 4'd12};


            // =================================================
            // THREAD 1: FIBONACCI N=10 (Result in R1)
            // =================================================
            // Start Address: 100 (0x64)
            
            // Init: R0(a)=0, R1(b)=1, R2(cnt)=10, R4(dec)=1, R5(zero)=0
            8'd100: instr = {`OP_LDI, 4'd0, 4'd0, 4'd0};  // a = 0
            8'd102: instr = {`OP_LDI, 4'd1, 4'd0, 4'd1};  // b = 1
            8'd104: instr = {`OP_LDI, 4'd2, 4'd0, 4'd10}; // count = 10
            8'd106: instr = {`OP_LDI, 4'd4, 4'd0, 4'd1};  // decrement = 1
            8'd108: instr = {`OP_LDI, 4'd5, 4'd0, 4'd0};  // zero constant

            // LOOP START (Addr 110 -> 0x6E)
            // R3(temp) = a(R0) + b(R1)
            8'd110: instr = {`OP_ADD, 4'd3, 4'd0, 4'd1}; 
            
            // a(R0) = b(R1) + 0(R5)  [Move b to a]
            8'd112: instr = {`OP_ADD, 4'd0, 4'd1, 4'd5}; 
            
            // b(R1) = temp(R3) + 0(R5) [Move temp to b]
            8'd114: instr = {`OP_ADD, 4'd1, 4'd3, 4'd5}; 

            // count(R2)--
            8'd116: instr = {`OP_SUB, 4'd2, 4'd2, 4'd4}; 

            // BNZ R2 to Addr 110 (0x6E)
            // Target High = 6, Reg = 2, Target Low = E (14)
            8'd118: instr = {`OP_BNZ, 4'd6, 4'd2, 4'd14}; 

            // DONE (Spin at 120 -> 0x78)
            // Target High = 7, Reg = 0, Target Low = 8
            8'd120: instr = {`OP_BNZ, 4'd7, 4'd0, 4'd8}; 
            
            default: instr = {`OP_NOP, 4'd0, 4'd0, 4'd0};
        endcase
    end
endmodule