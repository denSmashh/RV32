module register 
#(parameter DW = 32)
(
    input  logic            clk,
    input  logic            rstn,
    input  logic [DW-1:0]   d,
    output logic [DW-1:0]   q
);

always @ (posedge clk) begin
    if(~rstn) q <= 0;
    else      q <= d;
end

endmodule
