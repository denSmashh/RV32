`include "lsu_cmd.svh"

module lsu (
    input clk,
    input rstn,

    // core signals
    input  logic [31:0] dmem_cpu_addr,
    input  logic        dmem_cpu_we,
    input  logic        dmem_cpu_req,
    input  logic [2:0]  dmem_cpu_size,
    input  logic [31:0] dmem_cpu_wdata,
    output logic [31:0] dmem_cpu_rdata,
    output logic        lsu_stall_req,
    
    // external ram signals
    input  logic [31:0] dmem_ram_rdata,
    output logic [31:0] dmem_ram_addr,
    output logic [31:0] dmem_ram_wdata,
    output logic [3:0]  dmem_ram_be,
    output logic        dmem_ram_req,
    output logic        dmem_ram_we
);


logic [1:0] offset;
logic valid; 

assign offset = dmem_cpu_addr[1:0];

always @(posedge clk) begin
    if(~rstn) begin
        valid <= 'b0;
    end
    else begin
        if(dmem_cpu_req && valid) valid <= 1'b0;
        else valid <= 1'b1;    
    end
end


// set address, req, stall_req, we signals
always_comb begin
    if(dmem_cpu_req && valid) begin
        dmem_ram_addr = {dmem_cpu_addr[31:2], 2'b00};
        dmem_ram_req = 1'b1;
        lsu_stall_req = 1'b1;
        if(dmem_cpu_we)
            dmem_ram_we = 1'b1;
        else
            dmem_ram_we = 1'b0;
    end
    else begin
        dmem_ram_addr = 32'b0;
        dmem_ram_req = 1'b0;
        lsu_stall_req = 1'b0;
        dmem_ram_we = 1'b0;
    end
end

// Write in memory
always_comb begin
    if(dmem_cpu_req && valid) begin
        
        case (dmem_cpu_size[1:0])
            `LDST_B: begin
                dmem_ram_wdata = {4{dmem_cpu_wdata[7:0]}};  
                case (offset)
                    2'b00: dmem_ram_be = 4'b0001;  
                    2'b01: dmem_ram_be = 4'b0010;
                    2'b10: dmem_ram_be = 4'b0100;
                    2'b11: dmem_ram_be = 4'b1000;
                    default: dmem_ram_be = 4'b0000;
                endcase
            end 
             
            `LDST_H: begin
                dmem_ram_wdata = {2{dmem_cpu_wdata[15:0]}};
                case (offset)
                    2'b00: dmem_ram_be = 4'b0011;  
                    2'b10: dmem_ram_be = 4'b1100;
                    default: dmem_ram_be = 4'b1000;
                endcase
            end
            
            `LDST_W: begin
                dmem_ram_wdata = dmem_cpu_wdata[31:0];
                dmem_ram_be = 4'b1111;
            end

            default: begin 
                 dmem_ram_wdata = 'b0;
                 dmem_ram_be = 4'b0000;
             end
        endcase    

    end

    else  begin
        dmem_ram_wdata = 'b0;
        dmem_ram_be = 4'b0000;
    end

end


// Read memory
always_comb begin
    if(dmem_cpu_req && valid) begin
        case (dmem_cpu_size)
            `LDST_B: begin  
                 case (offset)
                    2'b00: dmem_cpu_rdata = {{24{dmem_ram_rdata[7]}}, dmem_ram_rdata[7:0]};  // sign extend
                    2'b01: dmem_cpu_rdata = {{24{dmem_ram_rdata[15]}}, dmem_ram_rdata[15:8]};
                    2'b10: dmem_cpu_rdata = {{24{dmem_ram_rdata[23]}}, dmem_ram_rdata[23:16]};
                    2'b11: dmem_cpu_rdata = {{24{dmem_ram_rdata[31]}}, dmem_ram_rdata[31:24]};
                    default: dmem_cpu_rdata = 'b0;
                endcase    
            end 
             
            `LDST_H: begin
                case (offset)
                    2'b00: dmem_cpu_rdata = {{16{dmem_ram_rdata[15]}}, dmem_ram_rdata[15:0]}; 
                    2'b10: dmem_cpu_rdata = {{16{dmem_ram_rdata[31]}}, dmem_ram_rdata[31:16]};
                    default: dmem_cpu_rdata = 'b0;
                endcase
            end 

            `LDST_W: dmem_cpu_rdata = dmem_ram_rdata;
            
            `LDST_BU: begin
                case (offset)
                    2'b00: dmem_cpu_rdata = {24'b0, dmem_ram_rdata[7:0]};  // sign extend
                    2'b01: dmem_cpu_rdata = {24'b0, dmem_ram_rdata[15:8]};
                    2'b10: dmem_cpu_rdata = {24'b0, dmem_ram_rdata[23:16]};
                    2'b11: dmem_cpu_rdata = {24'b0, dmem_ram_rdata[31:24]};
                    default: dmem_cpu_rdata = 'b0;
                endcase
            end

            `LDST_HU: begin
                case (offset)
                    2'b00: dmem_cpu_rdata = {16'b0, dmem_ram_rdata[15:0]}; 
                    2'b10: dmem_cpu_rdata = {16'b0, dmem_ram_rdata[31:16]};
                    default: dmem_cpu_rdata = 'b0;
                endcase
            end

            default: dmem_cpu_rdata = 'b0;
        endcase
    end

    else dmem_cpu_rdata = 'b0;
end

endmodule