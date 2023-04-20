module rf (
    input clk,
    input rstn,

    input logic         we,
    input logic [4:0]   a1,
    input logic [4:0]   a2,
    input logic [4:0]   a3,
    input logic [31:0]  wd,

    output logic [31:0] rd1,
    output logic [31:0] rd2
);

logic [31:0] rf_mem [0:31];

// read logic 
assign rd1 = (a1 == 'b0) ? 'b0 : (we && a1 == a3) ? wd : rf_mem[a1];
assign rd2 = (a2 == 'b0) ? 'b0 : (we && a2 == a3) ? wd : rf_mem[a2];



// write logic
always @(posedge clk or negedge rstn) begin 
    if(~rstn) begin
        for(int i = 0; i < 32; i = i + 1) rf_mem[i] <= 'b0;	
    end
    else begin
        if(we) rf_mem[a3] <= wd;
    end
end

    
endmodule