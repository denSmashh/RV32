
// instruction opcodes
`define LOAD_OPCODE      5'b00000
`define MISC_MEM_OPCODE  5'b00011
`define OP_IMM_OPCODE    5'b00100
`define AUIPC_OPCODE     5'b00101
`define STORE_OPCODE     5'b01000
`define R_OPCODE         5'b01100
`define LUI_OPCODE       5'b01101
`define BRANCH_OPCODE    5'b11000
`define JALR_OPCODE      5'b11001
`define JAL_OPCODE       5'b11011
`define SYSTEM_OPCODE    5'b11100

// operand a selection
`define OP_A_RS1         2'b00
`define OP_A_CURR_PC     2'b01
`define OP_A_ZERO        2'b10

// operand b selection
`define OP_B_RS2         3'b000
`define OP_B_IMM_I       3'b001
`define OP_B_IMM_U       3'b010
`define OP_B_IMM_S       3'b011
`define OP_B_INCR        3'b100

// writeback source selection
`define WB_EX_RESULT     1'b0
`define WB_LSU_DATA      1'b1

//next PC selection
`define PC_INC           1'b0
`define PC_JALR          1'b1
//`define PC_INC           2'b00
//`define PC_JALR          2'b01
//`define PC_MTVEC         2'b11
//`define PC_MEPC          2'b10