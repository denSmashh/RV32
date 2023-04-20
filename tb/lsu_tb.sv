`timescale 1ns / 1ps

`include "lsu_cmd.svh"

module lsu_tb();

  parameter     CYCLE = 5;  
  parameter     TWO_CYCLE = 10;
  parameter     HF_CYCLE = 2.5;       // 200 MHz clock
  parameter     RST_WAIT = 10;        // 10 ns reset

  

  // wires
  logic clk;
  logic rst_n;
  logic [31:0] dbg_dmem_cpu_addr;
  logic        dbg_dmem_cpu_we;
  logic        dbg_dmem_cpu_req;
  logic [2:0]  dbg_dmem_cpu_size;
  logic [31:0] dbg_dmem_cpu_wdata;
  logic [31:0] dbg_dmem_cpu_rdata;
  logic        dbg_lsu_stall_req;



RV32_top 
#(
    .IMEM_SIZE(128),
    .DMEM_SIZE(128),
    .RAM_INIT_FILE()
)
i_rv32_top 
(
    .clk(clk),
    .rstn(rst_n),
     // debug
    .dbg_dmem_cpu_addr(dbg_dmem_cpu_addr),
    .dbg_dmem_cpu_we(dbg_dmem_cpu_we),
    .dbg_dmem_cpu_req(dbg_dmem_cpu_req),
    .dbg_dmem_cpu_size(dbg_dmem_cpu_size),
    .dbg_dmem_cpu_wdata(dbg_dmem_cpu_wdata),
    .dbg_dmem_cpu_rdata(dbg_dmem_cpu_rdata),
    .dbg_lsu_stall_req(dbg_lsu_stall_req)
);


  task write_data(input [31:0] addr, data, size);
    dbg_dmem_cpu_req = 1'b1;
    dbg_dmem_cpu_we = 1'b1;
    dbg_dmem_cpu_addr = addr;
    dbg_dmem_cpu_wdata = data;
    dbg_dmem_cpu_size = size;
    $display("write %h in address %h", dbg_dmem_cpu_wdata, dbg_dmem_cpu_addr);
    #CYCLE;
    #CYCLE;
    dbg_dmem_cpu_req = 1'b0;
    dbg_dmem_cpu_we = 1'b0;
  endtask

  task read_data(input [31:0] addr, size);
    dbg_dmem_cpu_req = 1'b1;
    dbg_dmem_cpu_we = 1'b0;
    dbg_dmem_cpu_addr = addr;
    dbg_dmem_cpu_size = size;
    #CYCLE;
    #CYCLE;
    dbg_dmem_cpu_req = 1'b0;
    $display("read(%h) = %h", dbg_dmem_cpu_addr, dbg_dmem_cpu_rdata);
  endtask


  initial begin
    clk   = 1'b0;
    rst_n = 1'b0;
    #RST_WAIT;
    rst_n = 1'b1;
  end

  always begin
    #HF_CYCLE;
    clk = ~clk;
  end

  initial begin
    #RST_WAIT;
    #HF_CYCLE;
    
    write_data(32'h00, 32'h111111AA, `LDST_B);  // input addr, data, size
    write_data(32'h01, 32'h222222CC, `LDST_B);
    write_data(32'h02, 32'h3333BBBB, `LDST_H);
    write_data(32'h04, 32'h1111FAFB, `LDST_W);

    #CYCLE;
    #CYCLE;
    
    read_data(32'h00, `LDST_HU);  // input addr, size
    read_data(32'h05, `LDST_B); 
  end

endmodule
