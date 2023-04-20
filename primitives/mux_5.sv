module mux_5
#(parameter DW = 32)
(
    input  logic  [2:0]     sel,
    input  logic  [DW-1:0]  a1,
    input  logic  [DW-1:0]  a2,
    input  logic  [DW-1:0]  a3,
    input  logic  [DW-1:0]  a4,
    input  logic  [DW-1:0]  a5,
    output logic  [DW-1:0]  y
);

always_comb begin 
    case (sel)
        3'b000: y <= a1;
        3'b001: y <= a2;
        3'b010: y <= a3;
        3'b011: y <= a4;
        3'b100: y <= a5;
        default: y <= 'b0;
    endcase
end

endmodule
