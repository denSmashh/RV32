module RV32_top 
#(
    parameter IMEM_SIZE = 512,
    parameter DMEM_SIZE  = 512,
    parameter RAM_INIT_FILE  = ""
) 
(
    input clk,
    input rstn
);


logic [31:0] imem2core_addr;
logic [31:0] imem2core_rdata;
logic [31:0] dmem2core_rdata;    
logic [31:0] dmem2core_addr;
logic [31:0] dmem2core_wdata;  
logic [3:0]  dmem2core_be;
logic        dmem2core_req;
logic        dmem_we;

ram  
#(
    .INSTR_MEM_SIZE(IMEM_SIZE),    // bytes 
    .DATA_MEM_SIZE(DMEM_SIZE),     // bytes
    .RAM_INIT_FILE(RAM_INIT_FILE) 
)
i_ram
(
    .clk    (clk),
    .rstn   (rstn),
    // IMEM Port
    .imem_addr  (imem2core_addr),   // input [31:0]
    .imem_rdata (imem2core_rdata),  // output [31:0]
    // DMEM Port
    .dmem_rdata (dmem2core_rdata),  // output logic [31:0] 
    .dmem_addr  (dmem2core_addr),   // input [31:0]
    .dmem_wdata (dmem2core_wdata),  // input [31:0]
    .dmem_be    (dmem2core_be),     // input [3:0]
    .dmem_req   (dmem2core_req),    // input [0:0]
    .dmem_we    (dmem_we)           // input [0:0]
);

rv32_core i_core 
(
    .clk(clk),
    .rstn(rstn),
    // imem if
    .imem_addr  (imem2core_addr),
    .imem_rdata (imem2core_rdata),
    // dmem if
    .dmem_ram_rdata (dmem2core_rdata),
    .dmem_ram_addr  (dmem2core_addr),
    .dmem_ram_wdata (dmem2core_wdata),
    .dmem_ram_be    (dmem2core_be),
    .dmem_ram_req   (dmem2core_req),
    .dmem_ram_we    (dmem_we)
);



endmodule