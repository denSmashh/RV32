`include "alu_defines.svh"

module rv32_core 
(
    // sys
    input clk,
    input rstn,

    // instr memory interface
    output logic [31:0] imem_addr,
    input  logic [31:0] imem_rdata,

    // data memory interface
    input  logic [31:0] dmem_ram_rdata,
    output logic [31:0] dmem_ram_addr,
    output logic [31:0] dmem_ram_wdata,
    output logic [3:0]  dmem_ram_be,
    output logic        dmem_ram_req,
    output logic        dmem_ram_we      
);
    

//------------------------------------------ WIRES -----------------------------------------//

// FETCH STAGE wires
logic [31:0] pc_F;
logic [31:0] pc_next_F;
logic [31:0] instr_F;
logic [31:0] imm_sel_F;
logic [0:0] jal_en_F;
logic [31:0] operand_sel_F; 
logic [31:0] pc_incr_F;

// DECODE STAGE wires
logic [31:0] instr_D;
logic [4:0]  rs1_D;
logic [4:0]  rs2_D;
logic [4:0]  rd_D;

logic [1:0] srcA_sel_D;
logic [2:0] srcB_sel_D;
logic [0:0] mem_req_D;
logic [0:0] mem_we_D;
logic [2:0] mem_size_D;
logic [0:0] gpr_we_a_D;
logic [0:0] wb_src_sel_D;       
logic [0:0] branch_D;           
logic [0:0] jal_D;          
logic [0:0] jalr_D;
logic [0:0] illegal_instr_D;
logic [`ALU_OPCODE_WIDTH-1:0] alu_op_D;

logic [31:0] rd1_D;
logic [31:0] rd2_D;

logic [31:0] imm_i_D;
logic [31:0] imm_s_D;
logic [31:0] imm_b_D;

// EXECUTE STAGE wires
logic [31:0] instr_E;
logic [4:0] rs1_E;
logic [4:0] rs2_E;
logic [4:0] rd_E;

logic [31:0] rd1_E;
logic [31:0] rd2_E;
logic [31:0] rd1_hz_E;
logic [31:0] rd2_hz_E;
logic [1:0]  srcA_sel_E;
logic [2:0]  srcB_sel_E;
logic [0:0] mem_req_E;
logic [0:0] mem_we_E;
logic [2:0] mem_size_E;
logic [0:0] gpr_we_a_E;
logic [0:0] wb_src_sel_E;         
logic [0:0] branch_E;           
logic [0:0] jal_E;          
logic [0:0] jalr_E;
logic [`ALU_OPCODE_WIDTH-1:0] alu_op_E;

logic [31:0] srcA_alu_E;
logic [31:0] srcB_alu_E;
logic [0:0]  cmp_result_E;
logic [31:0] alu_result_E;

logic [31:0] srcA_E;
logic [31:0] srcB_E;

logic [31:0] imm_i_E;
logic [31:0] imm_s_E;
logic [31:0] imm_b_E;
logic [31:0] imm_j_D;

// MEMORY STAGE wires
logic [4:0] rd_M;
logic [31:0] rd2_M;
logic [31:0] alu_result_M;
logic [0:0] gpr_we_a_M;
logic [0:0] mem_req_M;
logic [0:0] mem_we_M;
logic [2:0] mem_size_M;
logic [0:0] lsu_stall_req_M;
logic [31:0] rdata_lsu_M;
logic [0:0] wb_src_sel_M;         

// WRITEBACK STAGE wires
logic [4:0] rd_W;
logic [31:0] rdata_lsu_W;
logic [31:0] alu_result_W;
logic [31:0] wb_result_W;
logic [0:0] gpr_we_a_W;
logic [0:0] wb_src_sel_W;

// hazard wires
logic [1:0] bypassA_E_mux;
logic [1:0] bypassB_E_mux;
logic exec_clr;
logic dcd_clr;
logic dcd_stall;
logic fetch_stall;

// others
logic branch_en;

//------------------------------------- PIPELINE REGISTERS ---------------------------------------//

//--------------------- FETCH STAGE -------------------------//
register_en #(.DW(32)) pc_reg_F (.clk(clk), .rstn(rstn), .en(fetch_stall), .d(pc_next_F), .q(pc_F));

//--------------------- DECODE STAGE -------------------------//
register_en_clr #(.DW(32)) instr_reg_D (.clk(clk), .rstn(rstn), .en(dcd_stall), .clr(dcd_clr), .d(instr_F), .q(instr_D));

//--------------------- EXECUTE STAGE -------------------------//

// instr regs
register_clr #(.DW(5)) rd_reg_E (.clk(clk), .rstn(rstn), .clr(exec_clr), .d(rd_D), .q(rd_E));
register_clr #(.DW(5)) rs1_reg_E (.clk(clk), .rstn(rstn), .clr(exec_clr), .d(rs1_D), .q(rs1_E));
register_clr #(.DW(5)) rs2_reg_E (.clk(clk), .rstn(rstn), .clr(exec_clr), .d(rs2_D), .q(rs2_E));
register_clr #(.DW(32)) rd1_reg_E (.clk(clk), .rstn(rstn), .clr(exec_clr), .d(rd1_D), .q(rd1_E));
register_clr #(.DW(32)) rd2_reg_E (.clk(clk), .rstn(rstn), .clr(exec_clr), .d(rd2_D), .q(rd2_E));
register_clr #(.DW(32)) pc_reg_E (.clk(clk), .rstn(rstn), .clr(exec_clr), .d(instr_D), .q(instr_E));
// imm regs
register_clr #(.DW(32)) imm_i_reg_E (.clk(clk), .rstn(rstn), .clr(exec_clr), .d(imm_i_D), .q(imm_i_E));
register_clr #(.DW(32)) imm_b_reg_E (.clk(clk), .rstn(rstn), .clr(exec_clr), .d(imm_b_D), .q(imm_b_E));
register_clr #(.DW(32)) imm_s_reg_E (.clk(clk), .rstn(rstn), .clr(exec_clr), .d(imm_s_D), .q(imm_s_E));
// decoder regs
register_clr #(.DW(2)) ex_op_a_sel_reg_E (.clk(clk), .rstn(rstn), .clr(exec_clr), .d(srcA_sel_D), .q(srcA_sel_E));
register_clr #(.DW(3)) ex_op_b_sel_reg_E (.clk(clk), .rstn(rstn), .clr(exec_clr), .d(srcB_sel_D), .q(srcB_sel_E));
register_clr #(.DW(`ALU_OPCODE_WIDTH)) alu_op_reg_E (.clk(clk), .rstn(rstn), .clr(exec_clr), .d(alu_op_D), .q(alu_op_E));
register_clr #(.DW(1)) mem_req_reg_E (.clk(clk), .rstn(rstn), .clr(exec_clr), .d(mem_req_D), .q(mem_req_E));
register_clr #(.DW(1)) mem_we_reg_E (.clk(clk), .rstn(rstn), .clr(exec_clr), .d(mem_we_D), .q(mem_we_E));
register_clr #(.DW(3)) mem_size_reg_E (.clk(clk), .rstn(rstn), .clr(exec_clr), .d(mem_size_D), .q(mem_size_E));
register_clr #(.DW(1)) grp_we_reg_E (.clk(clk), .rstn(rstn), .clr(exec_clr), .d(gpr_we_a_D), .q(gpr_we_a_E));
register_clr #(.DW(1)) wb_src_sel_reg_E (.clk(clk), .rstn(rstn), .clr(exec_clr), .d(wb_src_sel_D), .q(wb_src_sel_E));
register_clr #(.DW(1)) branch_reg_E (.clk(clk), .rstn(rstn), .clr(exec_clr), .d(branch_D), .q(branch_E));
register_clr #(.DW(1)) jal_reg_E (.clk(clk), .rstn(rstn), .clr(exec_clr), .d(jal_D), .q(jal_E));
register_clr #(.DW(1)) jalr_reg_E (.clk(clk), .rstn(rstn), .clr(exec_clr), .d(jalr_D), .q(jalr_E));


//--------------------- MEMORY STAGE -------------------------//
register #(.DW(5)) rdestination_reg_M (.clk(clk), .rstn(rstn), .d(rd_E), .q(rd_M));
register #(.DW(32)) rd2_reg_M (.clk(clk), .rstn(rstn), .d(rd2_E), .q(rd2_M));
register #(.DW(32)) alu_result_reg_M (.clk(clk), .rstn(rstn), .d(alu_result_E), .q(alu_result_M));
register #(.DW(1)) mem_req_reg_M (.clk(clk), .rstn(rstn), .d(mem_req_E), .q(mem_req_M));
register #(.DW(1)) mem_we_reg_M (.clk(clk), .rstn(rstn), .d(mem_we_E), .q(mem_we_M));
register #(.DW(3)) mem_size_reg_M (.clk(clk), .rstn(rstn), .d(mem_size_E), .q(mem_size_M));
register #(.DW(1)) grp_we_reg_M (.clk(clk), .rstn(rstn), .d(gpr_we_a_E), .q(gpr_we_a_M));
register #(.DW(1)) wb_src_sel_reg_M (.clk(clk), .rstn(rstn), .d(wb_src_sel_E), .q(wb_src_sel_M));


//--------------------- WRITEBACK STAGE -----------------------//
register #(.DW(5)) rdestination_reg_W (.clk(clk), .rstn(rstn), .d(rd_M), .q(rd_W));
register #(.DW(32)) rdata_lsu_reg_W (.clk(clk), .rstn(rstn), .d(rdata_lsu_M), .q(rdata_lsu_W));
register #(.DW(32)) alu_result_reg_W (.clk(clk), .rstn(rstn), .d(alu_result_M), .q(alu_result_W));
register #(.DW(1)) grp_we_reg_W (.clk(clk), .rstn(rstn), .d(gpr_we_a_M), .q(gpr_we_a_W));
register #(.DW(1)) wb_src_sel_reg_W (.clk(clk), .rstn(rstn), .d(wb_src_sel_M), .q(wb_src_sel_W));


//----------------------------------- MUXes, ADDERs ---------------------------------------//

// Fetch stage
mux_2 #(.DW(32)) imm_sel_mux2 (.sel(branch_D), .a1(imm_j_D), .a2(imm_b_E), .y(imm_sel_F));
mux_2 #(.DW(32)) operand_sel_mux2 (.sel(jal_en_F), .a1(32'd4), .a2(imm_sel_F), .y(operand_sel_F));
mux_2 #(.DW(32)) jalr_mux2 (.sel(jalr_E), .a1(pc_incr_F), .a2(rd1_D), .y(pc_next_F));
adder #(.DW(32)) pc_incr_adder (.a1(pc_F), .a2(operand_sel_F), .y(pc_incr_F));

// Execute stage
mux_4 #(.DW(32)) srcA_hazard_mux4 (.sel(bypassA_E_mux), .a1(rd1_E), .a2(wb_result_W), .a3(alu_result_M), .a4('b0), .y(rd1_hz_E));
mux_4 #(.DW(32)) srcB_hazard_mux4 (.sel(bypassB_E_mux), .a1(rd2_E), .a2(wb_result_W), .a3(alu_result_M), .a4('b0), .y(rd2_hz_E));
mux_4 #(.DW(32)) srcA_mux4 (.sel(srcA_sel_E), .a1(rd1_hz_E), .a2(pc_F), .a3('b0), .a4('b0), .y(srcA_alu_E));
mux_5 #(.DW(32)) srcB_mux5 (.sel(srcB_sel_E), .a1(rd2_hz_E), .a2(imm_i_E), .a3({instr_E[31:12],{12{1'b0}}}), .a4(imm_s_E), .a5(32'd4), .y(srcB_alu_E));
// WriteBack stage
mux_2 #(.DW(32)) wb_sel_mux2 (.sel(wb_src_sel_W), .a1(alu_result_W), .a2(rdata_lsu_W), .y(wb_result_W));


// instr
assign rd_D = instr_D[11:7];
assign rs1_D = instr_D[19:15];
assign rs2_D = instr_D[24:20];

// branch enable
assign branch_en = branch_E & cmp_result_E;
assign jal_en_F = branch_en | jal_D;

// sign extend
assign imm_i_D = {{20{instr_D[31]}},instr_D[31:20]};
assign imm_s_D = {{20{instr_D[31]}},instr_D[31:25],instr_D[11:7]};
assign imm_j_D = {{12{instr_D[31]}},instr_D[19:12],instr_D[20],instr_D[30:21],1'b0};
assign imm_b_D = {{20{instr_D[31]}},instr_D[7],instr_D[30:25],instr_D[11:8],1'b0};

// imem access
assign imem_addr = pc_F;
assign instr_F = imem_rdata;

rf i_register_file
(
    .clk(clk),
    .rstn(rstn),
    .we(gpr_we_a_W),
    .a1(instr_D[19:15]),
    .a2(instr_D[24:20]),
    .a3(rd_W),
    .wd(wb_result_W),
    .rd1(rd1_D),
    .rd2(rd2_D)
);

alu i_alu
(
    .srcA(srcA_alu_E),
    .srcB(srcB_alu_E),
    .alu_opcode(alu_op_E),
    .alu_result(alu_result_E),
    .cmp_result(cmp_result_E)
);


decoder i_decoder
(
    .fetched_instr_i(instr_D),    
    .ex_op_a_sel_o(srcA_sel_D),      
    .ex_op_b_sel_o(srcB_sel_D),      
    .alu_op_o(alu_op_D), 
    .mem_req_o(mem_req_D),          
    .mem_we_o(mem_we_D),           
    .mem_size_o(mem_size_D),         
    .gpr_we_a_o(gpr_we_a_D),        
    .wb_src_sel_o(wb_src_sel_D),      
    .illegal_instr_o(illegal_instr_D),   
    .branch_o(branch_D),           
    .jal_o(jal_D),              
    .jalr_o(jalr_D)             
);

lsu i_lsu 
(
    .clk(clk),
    .rstn(rstn),
    // core signals
    .dmem_cpu_addr(alu_result_M),
    .dmem_cpu_we(mem_we_M),
    .dmem_cpu_req(mem_req_M),
    .dmem_cpu_size(mem_size_M),
    .dmem_cpu_wdata(rd2_M),
    .dmem_cpu_rdata(rdata_lsu_M),
    .lsu_stall_req(lsu_stall_req_M),
    // external ram signals
    .dmem_ram_rdata(dmem_ram_rdata),
    .dmem_ram_addr(dmem_ram_addr),
    .dmem_ram_wdata(dmem_ram_wdata),
    .dmem_ram_be(dmem_ram_be),
    .dmem_ram_req(dmem_ram_req),
    .dmem_ram_we(dmem_ram_we)
);

hazard i_hz_unit 
(
    .rs1_D(rs1_D),
    .rs2_D(rs2_D),
    .rs1_E(rs1_E),
    .rs2_E(rs2_E),
    .rd_E(rd_E),
    .rd_M(rd_M),
    .rd_W(rd_W),
    .rf_we_E(wb_src_sel_E),
    .rf_we_M(wb_src_sel_M),
    .rf_we_W(wb_src_sel_W),
    .branch(branch_en),
    .bypassA_E(bypassA_E_mux),
    .bypassB_E(bypassB_E_mux),
    .stall_fetch_n(fetch_stall),
    .stall_decode_n(dcd_stall),
    .clear_decode(dcd_clr),
    .clear_execute(exec_clr)
);

endmodule