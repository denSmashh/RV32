`timescale 1ns / 1ps
module rv32_top_tb();


  parameter     CYCLE = 5;  
  parameter     TWO_CYCLE = 10;
  parameter     HF_CYCLE = 2.5;       // 200 MHz clock
  parameter     RST_WAIT = 10;        // 10 ns reset

  
  // wires
  logic clk;
  logic rst_n;

RV32_top 
#(
    .IMEM_SIZE(512),
    .DMEM_SIZE(512),
    .RAM_INIT_FILE("program.txt")
)
i_rv32_top 
(
    .clk(clk),
    .rstn(rst_n)
);


  always begin
    #HF_CYCLE;
    clk = ~clk;
  end

   initial begin
    clk   = 1'b0;
    rst_n = 1'b0;
    #RST_WAIT;
    rst_n = 1'b1;
  end



endmodule