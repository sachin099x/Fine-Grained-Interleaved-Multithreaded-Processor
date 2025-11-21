// Existing defines...
`define OP_ADD  4'b0000
`define OP_SUB  4'b0001
`define OP_AND  4'b0010
`define OP_OR   4'b0011
`define OP_LDI  4'b0100  // Load value directly: R1 = 5
`define OP_BNZ  4'b0101  // Branch if Not Zero: if (R1 != 0) goto Target
`define OP_NOP  4'b1111

`define DATA_W  16
`define ADDR_W  8
`define REG_W   4

// NEW: Status Register Bits
`define FLAG_Z  0  // Zero Flag
`define FLAG_N  1  // Negative Flag
