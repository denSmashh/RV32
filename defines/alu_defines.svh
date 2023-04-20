`define ALU_OPCODE_WIDTH  5

`define ALU_ADD   5'b00000
`define ALU_SUB   5'b01000
`define ALU_XOR   5'b00100
`define ALU_OR    5'b00110	
`define ALU_AND   5'b00111	

`define ALU_SRA   5'b01101
`define ALU_SRL   5'b00101
`define ALU_SLL   5'b00001	

`define ALU_SLT   5'b00010	
`define ALU_SLTU  5'b00011	
`define ALU_BGE   5'b11101	
`define ALU_BGEU  5'b11111	
`define ALU_BEQ   5'b11000	
`define ALU_BNE   5'b11001	

`define ALU_BLT   5'b11100	
`define ALU_BLTU  5'b11110	


// `define ALU_OPCODE_WIDTH  6

// // add, sub, logic operationss
// `define ALU_ADD   6'b011000
// `define ALU_SUB   6'b011001
// `define ALU_XOR   6'b101111
// `define ALU_OR    6'b101110
// `define ALU_AND   6'b010101

// // shifts
// `define ALU_SRA   6'b100100
// `define ALU_SRL   6'b100101
// `define ALU_SLL   6'b100111

// // comparison 
// `define ALU_SLT   6'b000000
// `define ALU_SLTU  6'b000001
// `define ALU_BGE   6'b001010
// `define ALU_BGEU  6'b001011
// `define ALU_BEQ   6'b001100
// `define ALU_BNE   6'b001101

// // set lower than operations
// `define ALU_BLT  6'b000010
// `define ALU_BLTU 6'b000011
