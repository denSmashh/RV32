`include "alu_defines.svh"

module alu (
    input  logic [31:0]  srcA,
    input  logic [31:0]  srcB,
    input  logic [`ALU_OPCODE_WIDTH - 1:0] alu_opcode,
    output logic [31:0]  alu_result,
    output logic         cmp_result
);

always_comb begin
    case(alu_opcode)
        `ALU_ADD : begin 
            alu_result = srcA + srcB; 
            cmp_result = 1'b0; 
         end
         `ALU_SUB : begin 
            alu_result = srcA - srcB; 
            cmp_result = 1'b0; 
         end
         `ALU_XOR : begin 
            alu_result = srcA ^ srcB; 
            cmp_result = 1'b0; 
         end
         `ALU_OR : begin 
            alu_result = srcA | srcB;  
            cmp_result = 1'b0; 
         end
         `ALU_AND : begin 
            alu_result = srcA & srcB; 
            cmp_result = 1'b0; 
         end
         `ALU_SRA : begin 
            alu_result = $signed(srcA) >>> srcB[4:0]; 
            cmp_result = 1'b0; 
         end
         `ALU_SRL : begin 
            alu_result = srcA >> srcB[4:0]; 
            cmp_result = 1'b0; 
         end
         `ALU_SLL : begin 
            alu_result = srcA << srcB[4:0]; 
            cmp_result = 1'b0; 
         end
         `ALU_SLT : begin 
            alu_result = $signed(srcA) < $signed(srcB) ? 32'b1 : 32'b0; 
            cmp_result = alu_result; 
         end
         `ALU_SLTU : begin 
            alu_result = srcA < srcB ? 32'b1 : 32'b0; 
            cmp_result = alu_result; 
         end
         `ALU_BGE : begin 
            alu_result = $signed(srcA) >= $signed(srcB) ? 32'b1 : 32'b0; 
            cmp_result = alu_result; 
         end
         `ALU_BGEU : begin 
            alu_result = srcA >= srcB ? 32'b1 : 32'b0; 
            cmp_result = alu_result; 
         end
         `ALU_BEQ : begin 
            alu_result = srcA == srcB ? 32'b1 : 32'b0;
            cmp_result = alu_result; 
         end
         `ALU_BNE : begin 
            alu_result = srcA != srcB ? 32'b1 : 32'b0;
            cmp_result = alu_result; 
         end
        `ALU_BLT : begin
            alu_result = $signed(srcA) < $signed(srcB) ? 32'b1 : 32'b0;
            cmp_result = alu_result;
        end
        `ALU_BLTU: begin
            alu_result = srcA < srcB ? 32'b1 : 32'b0;
            cmp_result = alu_result;            
        end

        default: begin
            alu_result = 32'b0;
            cmp_result = 1'b0;
        end 
        
    endcase
end

endmodule