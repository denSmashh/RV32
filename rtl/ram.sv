module ram 
#(
    parameter INSTR_MEM_SIZE = 256,     // bytes 
    parameter DATA_MEM_SIZE  = 256,     // bytes
    parameter RAM_INIT_FILE  = ""
)
(
    input clk,
    input rstn,

    // IMEM Port
    input  logic [31:0] imem_addr,
    output logic [31:0] imem_rdata,

    // DMEM Port
    output logic [31:0] dmem_rdata,
    input  logic [31:0] dmem_addr,
    input  logic [31:0] dmem_wdata,
    input  logic [3:0]  dmem_be,    
    input  logic        dmem_req,
    input  logic        dmem_we
);


logic [31:0] ram [0:(INSTR_MEM_SIZE + DATA_MEM_SIZE)/4 - 1];   // default: 1kB 


// load INIT file
initial begin
    if(RAM_INIT_FILE != "") begin
        $readmemh(RAM_INIT_FILE, ram);    
    end
    else begin
        for(int i = 0; i < (INSTR_MEM_SIZE+DATA_MEM_SIZE)/4; i = i + 1) begin
            ram[i] = 'b0;
        end
    end 
end 

// IMEM read data
assign imem_rdata = ram[(imem_addr % (INSTR_MEM_SIZE + DATA_MEM_SIZE) / 4)];


// DMEM write data
always @(posedge clk) begin
    if(dmem_req) begin
        if(dmem_we && dmem_be[0]) begin
            ram[dmem_addr[31:2]][7:0] <= dmem_wdata[7:0];       // [31:2] for array ram[] access
        end
        if(dmem_we && dmem_be[1]) begin
            ram[dmem_addr[31:2]][15:8] <= dmem_wdata[15:8];
        end
        if(dmem_we && dmem_be[2]) begin
            ram[dmem_addr[31:2]][23:16] <= dmem_wdata[23:16];
        end
        if(dmem_we && dmem_be[3]) begin
            ram[dmem_addr[31:2]][31:24] <= dmem_wdata[31:24];
        end
    end
end


// DMEM read data   *sync reset
always @(posedge clk) begin
    if (~rstn) begin
        dmem_rdata <= 'b0;    
    end 
    else if(dmem_req) begin
        dmem_rdata <= ram[(dmem_addr % (INSTR_MEM_SIZE + DATA_MEM_SIZE) / 4)];    
    end 
end

endmodule