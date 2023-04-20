`include "hazard_defines.svh"

module hazard (
    input  logic [4:0]  rs1_D,
    input  logic [4:0]  rs2_D,
    input  logic [4:0]  rs1_E,
    input  logic [4:0]  rs2_E,
    input  logic [4:0]  rd_E,
    input  logic [4:0]  rd_M,
    input  logic [4:0]  rd_W,
    input  logic        rf_we_E,
    input  logic        rf_we_M,
    input  logic        rf_we_W,
    input  logic        branch,
    output logic [1:0]  bypassA_E,
    output logic [1:0]  bypassB_E,
    output logic        stall_fetch_n,
    output logic        stall_decode_n,
    output logic        clear_decode,
    output logic        clear_execute
);

logic load_instr_stall;
logic branch_instr_stall;
logic stall;

// bypass for RAW conflict (simultaneously EXUCUTE and MEMORY|WRITEBACK stages with equal address) 
assign bypassA_E = ((rs1_E != 5'b0) && rf_we_M && (rd_M == rs1_E)) ? `HZ_BYPASS_M2E :
                   ((rs1_E != 5'b0) && rf_we_W && (rd_W == rs1_E)) ? `HZ_BYPASS_W2E : `HZ_BYPASS_NONE;  

assign bypassB_E = ((rs2_E != 5'b0) && rf_we_M && (rd_M == rs2_E)) ? `HZ_BYPASS_M2E : 
                   ((rs2_E != 5'b0) && rf_we_W && (rd_W == rs2_E)) ? `HZ_BYPASS_W2E : `HZ_BYPASS_NONE;


// stall if hazard in load-instructions
assign load_instr_stall = (rf_we_E && (rd_E == rs1_D || rd_E == rs2_D));

// stall for branch instruction
assign branch_instr_stall = branch;

// set stall and clear signals
assign stall_fetch_n = ~load_instr_stall;
assign stall_decode_n = ~load_instr_stall;
assign stall = (load_instr_stall || branch_instr_stall);
assign clear_decode = stall;
assign clear_execute = stall;

    
endmodule