module adder
#(parameter DW = 32)
(
    input  logic [DW-1:0]   a1,
    input  logic [DW-1:0]   a2,
    output logic [DW-1:0]   y
    
);
    
assign y = a1 + a2;  
    
endmodule
