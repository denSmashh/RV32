`include "alu_defines.svh"
`include "decoder_defines.svh"


module decoder (
    input   logic [31:0]    fetched_instr_i,    // fetched instrucion
    output  logic [1:0]     ex_op_a_sel_o,      // srcA mux
    output  logic [2:0]     ex_op_b_sel_o,      // srcB mux
    output  logic [`ALU_OPCODE_WIDTH-1:0] alu_op_o, // alu opcode
    output  logic           mem_req_o,          // lsu
    output  logic           mem_we_o,           // lsu read-write
    output  logic [2:0]     mem_size_o,         // lsu 
    output  logic           gpr_we_a_o,         // rf write-enable
    output  logic           wb_src_sel_o,       // writebach mux
    output  logic           illegal_instr_o,    // csr
    output  logic           branch_o,           // branch instr
    output  logic           jal_o,              // jal  instr
    output  logic           jalr_o              // jalr instr
);

        
logic [1:0]                 ex_op_a_sel;
logic [2:0]                 ex_op_b_sel;
logic [`ALU_OPCODE_WIDTH-1:0] alu_op;
logic                       mem_req;
logic                       mem_we;
logic [2:0]                 mem_size;
logic                       gpr_we_a;
logic                       wb_src_sel;
logic                       illegal_instr;
logic                       branch;
logic                       jal;
logic                       jalr;

assign ex_op_a_sel_o = ex_op_a_sel;
assign ex_op_b_sel_o = ex_op_b_sel;
assign alu_op_o = alu_op;
assign mem_req_o = mem_req;
assign mem_we_o = mem_we;
assign mem_size_o = mem_size;
assign gpr_we_a_o = gpr_we_a;
assign wb_src_sel_o = wb_src_sel;
assign branch_o = branch;
assign jal_o = jal;
assign jalr_o = jalr;
assign illegal_instr_o = illegal_instr;
//logic                       csr;
//logic [2:0]                 csrop;
//logic                       int_rst;
//assign enpc_o = !stall_i;
//assign csr_o = csr;
//assign csrop_o = csrop;
//assign int_rst_o = int_rst;


logic [1:0] opcode_type;
logic [4:0] opcode;
logic [4:0] rd;
logic [4:0] rs1;
logic [4:0] rs2;
logic [2:0] funct3;
logic [6:0] funct7;

assign opcode_type = fetched_instr_i[1:0];
assign opcode = fetched_instr_i[6:2];
assign rd = fetched_instr_i[11:7];
assign rs1 = fetched_instr_i[19:15];
assign rs2 = fetched_instr_i[24:20];
assign funct3 = fetched_instr_i[14:12];
assign funct7 = fetched_instr_i[31:25];


logic [20:0] controls;

assign {ex_op_a_sel, ex_op_b_sel, alu_op,       // 21 bit summury 
        mem_req, mem_we, mem_size,
        gpr_we_a, wb_src_sel, 
        branch, jal, jalr, 
        illegal_instr} = controls;


// Setting controls signals
always_comb begin
if(opcode_type == 2'b11) begin
    case(opcode)
        `LOAD_OPCODE: begin 
            if(funct3 < 3'd6 && funct3 != 3'd3) begin
                controls = {`OP_A_RS1, `OP_B_IMM_I, `ALU_ADD, 1'b1, 1'b0, funct3, 1'b1,         // LB, LH, LW, LBU, LHU
                            `WB_LSU_DATA, 1'b0, 1'b0, `PC_INC, 1'b0}; 
            end
            else begin
                controls = {`OP_A_RS1, `OP_B_IMM_I, `ALU_ADD, 1'b0, 1'b0, 3'b0, 1'b1,                
                            `WB_EX_RESULT, 1'b0, 1'b0, `PC_INC, 1'b1};
            end
        end

        `OP_IMM_OPCODE: begin
            case (funct3)
                3'd0:
                    controls = {`OP_A_RS1, `OP_B_IMM_I, `ALU_ADD, 1'b0, 1'b0, 3'b0, 1'b1,   // ADDI
                                `WB_EX_RESULT, 1'b0, 1'b0, `PC_INC, 1'b0};

                3'd1:
                    controls = {`OP_A_RS1, `OP_B_IMM_I, `ALU_SLL, 1'b0, 1'b0, 3'b0, 1'b1,   // SLLI       
                                `WB_EX_RESULT, 1'b0, 1'b0, `PC_INC, 1'b0};

                3'd2:
                    controls = {`OP_A_RS1, `OP_B_IMM_I, `ALU_SLT, 1'b0, 1'b0, 3'b0, 1'b1,   // SLTI    
                                `WB_EX_RESULT, 1'b0, 1'b0, `PC_INC, 1'b0};                  

                3'd3:
                    controls = {`OP_A_RS1, `OP_B_IMM_I, `ALU_SLTU, 1'b0, 1'b0, 3'b0, 1'b1,   // SLTIU    
                                `WB_EX_RESULT, 1'b0, 1'b0, `PC_INC, 1'b0};
                
                3'd4:
                    controls = {`OP_A_RS1, `OP_B_IMM_I, `ALU_XOR, 1'b0, 1'b0, 3'b0, 1'b1,   // XORI    
                                `WB_EX_RESULT, 1'b0, 1'b0, `PC_INC, 1'b0};

                3'd5: begin
                    if(funct7 == 7'h0)
                        controls = {`OP_A_RS1, `OP_B_IMM_I, `ALU_SRL, 1'b0, 1'b0, 3'b0, 1'b1,   // SRLI    
                                    `WB_EX_RESULT, 1'b0, 1'b0, `PC_INC, 1'b0};
                    else if (funct7 == 7'h20)
                        controls = {`OP_A_RS1, `OP_B_IMM_I, `ALU_SRA, 1'b0, 1'b0, 3'b0, 1'b1,   // SRAI    
                                    `WB_EX_RESULT, 1'b0, 1'b0, `PC_INC, 1'b0};
                    else
                        controls = {`OP_A_RS1, `OP_B_IMM_I, `ALU_ADD, 1'b0, 1'b0, 3'b0, 1'b1,                
                                    `WB_EX_RESULT, 1'b0, 1'b0, `PC_INC, 1'b1};
                end     

                3'd6:
                    controls = {`OP_A_RS1, `OP_B_IMM_I, `ALU_OR, 1'b0, 1'b0, 3'b0, 1'b1,   // ORI    
                                `WB_EX_RESULT, 1'b0, 1'b0, `PC_INC, 1'b0};

                3'd7:
                    controls = {`OP_A_RS1, `OP_B_IMM_I, `ALU_AND, 1'b0, 1'b0, 3'b0, 1'b1,   // ANDI    
                                `WB_EX_RESULT, 1'b0, 1'b0, `PC_INC, 1'b0};

                default: 
                    controls = {`OP_A_RS1, `OP_B_RS2, `ALU_ADD, 1'b0, 1'b0, 3'b0, 1'b0,                
                                1'b0, 1'b0, 1'b0, `PC_INC, 1'b1};
            endcase             
        end

        `AUIPC_OPCODE: begin    
            controls = {`OP_A_CURR_PC, `OP_B_IMM_U, `ALU_ADD, 1'b0, 1'b0, 3'b0, 1'b1,       // AUIPC            
                        `WB_EX_RESULT, 1'b0, 1'b0, `PC_INC, 1'b0};          
        end

        `STORE_OPCODE: begin    
            if (funct3 < 3'd3) begin 
                controls = {`OP_A_RS1, `OP_B_IMM_S, `ALU_ADD, 1'b1, 1'b1, funct3, 1'b0,         // SB, SH, SW
                            `WB_LSU_DATA, 1'b0, 1'b0, `PC_INC, 1'b0}; 
            end
            else begin
                controls = {`OP_A_RS1, `OP_B_RS2, `ALU_ADD, 1'b0, 1'b0, 3'b0, 1'b0,                
                                1'b0, 1'b0, 1'b0, `PC_INC, 1'b1};
            end
        end

        `R_OPCODE: begin
            if(funct7 == 7'h0) begin
                case (funct3)
                    3'd0:
                        controls = {`OP_A_RS1, `OP_B_RS2, `ALU_ADD, 1'b0, 1'b0, 3'b0, 1'b1,  // ADD
                                    `WB_EX_RESULT, 1'b0, 1'b0, `PC_INC, 1'b0}; 

                    3'd1:
                        controls = {`OP_A_RS1, `OP_B_RS2, `ALU_SLL, 1'b0, 1'b0, 3'b0, 1'b1,  // SLL
                                    `WB_EX_RESULT, 1'b0, 1'b0, `PC_INC, 1'b0};

                    3'd2:
                        controls = {`OP_A_RS1, `OP_B_RS2, `ALU_SLT, 1'b0, 1'b0, 3'b0, 1'b1,  // SLT
                                    `WB_EX_RESULT, 1'b0, 1'b0, `PC_INC, 1'b0};

                    3'd3:
                        controls = {`OP_A_RS1, `OP_B_RS2, `ALU_SLTU, 1'b0, 1'b0, 3'b0, 1'b1,  // SLTU
                                    `WB_EX_RESULT, 1'b0, 1'b0, `PC_INC, 1'b0};

                    3'd4:
                        controls = {`OP_A_RS1, `OP_B_RS2, `ALU_XOR, 1'b0, 1'b0, 3'b0, 1'b1,  // XOR
                                    `WB_EX_RESULT, 1'b0, 1'b0, `PC_INC, 1'b0};

                    3'd5:
                        controls = {`OP_A_RS1, `OP_B_RS2, `ALU_SRL, 1'b0, 1'b0, 3'b0, 1'b1,  // SRL
                                    `WB_EX_RESULT, 1'b0, 1'b0, `PC_INC, 1'b0};

                    3'd6:
                        controls = {`OP_A_RS1, `OP_B_RS2, `ALU_OR, 1'b0, 1'b0, 3'b0, 1'b1,  // OR
                                     `WB_EX_RESULT, 1'b0, 1'b0, `PC_INC, 1'b0};

                    3'd7:
                        controls = {`OP_A_RS1, `OP_B_RS2, `ALU_AND, 1'b0, 1'b0, 3'b0, 1'b1,  // AND
                                     `WB_EX_RESULT, 1'b0, 1'b0, `PC_INC, 1'b0};

                    default: 
                        controls = {`OP_A_RS1, `OP_B_RS2, `ALU_ADD, 1'b0, 1'b0, 3'b0, 1'b0,                
                                     1'b0, 1'b0, 1'b0, `PC_INC, 1'b1};
                endcase
            
            end
            else if(funct7 == 7'h20) begin
                if(funct3 == 3'd0) begin
                    controls = {`OP_A_RS1, `OP_B_RS2, `ALU_SUB, 1'b0, 1'b0, 3'b0, 1'b1,  // SUB
                                `WB_EX_RESULT, 1'b0, 1'b0, `PC_INC, 1'b0};
                end

                else if (funct7 == 3'd0)  begin
                    controls = {`OP_A_RS1, `OP_B_RS2, `ALU_SRA, 1'b0, 1'b0, 3'b0, 1'b1,  // SRA
                                `WB_EX_RESULT, 1'b0, 1'b0, `PC_INC, 1'b0};
                end     

                else
                    controls = {`OP_A_RS1, `OP_B_RS2, `ALU_ADD, 1'b0, 1'b0, 3'b0, 1'b0,                
                                     1'b0, 1'b0, 1'b0, `PC_INC, 1'b1};
            end

            else
                controls = {`OP_A_RS1, `OP_B_RS2, `ALU_ADD, 1'b0, 1'b0, 3'b0, 1'b0,                
                                     1'b0, 1'b0, 1'b0, `PC_INC, 1'b1};
        end

        `LUI_OPCODE: begin   
            controls = {`OP_A_ZERO, `OP_B_IMM_U, `ALU_ADD, 1'b0, 1'b0, 3'b0, 1'b1,  // LUI
                                `WB_EX_RESULT, 1'b0, 1'b0, `PC_INC, 1'b0};
        end

        `BRANCH_OPCODE: begin
            case(funct3) 
                3'd0:   
                    controls = {`OP_A_RS1, `OP_B_RS2, `ALU_BEQ, 1'b0, 1'b0, 3'b0, 1'b0,  // BEQ
                                `WB_EX_RESULT, 1'b1, 1'b0, `PC_INC, 1'b0};

                3'd1:   
                    controls = {`OP_A_RS1, `OP_B_RS2, `ALU_BNE, 1'b0, 1'b0, 3'b0, 1'b0,  // BNE
                                `WB_EX_RESULT, 1'b1, 1'b0, `PC_INC, 1'b0};
                
                3'd4:   
                    controls = {`OP_A_RS1, `OP_B_RS2, `ALU_BLT, 1'b0, 1'b0, 3'b0, 1'b0,  // BLT
                                `WB_EX_RESULT, 1'b1, 1'b0, `PC_INC, 1'b0};

                3'd5:   
                    controls = {`OP_A_RS1, `OP_B_RS2, `ALU_BGE, 1'b0, 1'b0, 3'b0, 1'b0,  // BGE
                                `WB_EX_RESULT, 1'b1, 1'b0, `PC_INC, 1'b0};

                3'd6:   
                    controls = {`OP_A_RS1, `OP_B_RS2, `ALU_BLTU, 1'b0, 1'b0, 3'b0, 1'b0,  // BLTU
                                `WB_EX_RESULT, 1'b1, 1'b0, `PC_INC, 1'b0};

                3'd7:   
                    controls = {`OP_A_RS1, `OP_B_RS2, `ALU_BGEU, 1'b0, 1'b0, 3'b0, 1'b0,  // BGEU
                                `WB_EX_RESULT, 1'b1, 1'b0, `PC_INC, 1'b0};

                default: 
                        controls = {`OP_A_RS1, `OP_B_RS2, `ALU_ADD, 1'b0, 1'b0, 3'b0, 1'b0,                
                                     1'b0, 1'b0, 1'b0, `PC_INC, 1'b1};
            endcase
        end

        `JALR_OPCODE: begin
            if(funct3 == 3'd0) begin
                controls = {`OP_A_CURR_PC, `OP_B_INCR, `ALU_ADD, 1'b0, 1'b0, 3'b0, 1'b1,  // JALR
                                `WB_EX_RESULT, 1'b0, 1'b0, `PC_JALR, 1'b0};
            end
            else begin
                controls = {`OP_A_RS1, `OP_B_RS2, `ALU_ADD, 1'b0, 1'b0, 3'b0, 1'b0,                
                                     1'b0, 1'b0, 1'b0, `PC_INC, 1'b1};
            end
        end

        `JAL_OPCODE: begin    
            controls = {`OP_A_CURR_PC, `OP_B_INCR, `ALU_ADD, 1'b0, 1'b0, 3'b0, 1'b1,    // JAL
                                `WB_EX_RESULT, 1'b0, 1'b1, `PC_INC, 1'b0};        
        end

        `MISC_MEM_OPCODE: begin
            controls = {`OP_A_RS1, `OP_B_RS2, `ALU_ADD, 1'b0, 1'b0, 3'b0, 1'b0,         // NOP    
                        1'b0, 1'b0, 1'b0, `PC_INC, 1'b0};  
        end

        `SYSTEM_OPCODE: begin
            controls = {`OP_A_RS1, `OP_B_RS2, `ALU_ADD, 1'b0, 1'b0, 3'b0, 1'b0,         // NOP    
                        1'b0, 1'b0, 1'b0, `PC_INC, 1'b0}; 
        end 

        default:
            controls = {`OP_A_RS1, `OP_B_RS2, `ALU_ADD, 1'b0, 1'b0, 3'b0, 1'b0,                
                        1'b0, 1'b0, 1'b0, `PC_INC, 1'b1};
    endcase
end
else
    controls = {`OP_A_RS1, `OP_B_RS2, `ALU_ADD, 1'b0, 1'b0, 3'b0, 1'b0,                
                1'b0, 1'b0, 1'b0, `PC_INC, 1'b1};
end


endmodule
