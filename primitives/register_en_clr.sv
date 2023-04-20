module register_en_clr 
#(parameter DW = 32)
(
    input  logic            clk,
    input  logic            rstn,
    input  logic            en,
    input  logic            clr,
    input  logic [DW-1:0]   d, 
    output logic [DW-1:0]   q
);

always @ (posedge clk) begin
    if(~rstn)    
        q <= 0;
    else if (clr) 
        q <= 0;   
    else 
        if (en)  q <= d;
end

endmodule
