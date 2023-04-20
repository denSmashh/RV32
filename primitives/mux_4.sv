module mux_4
#(parameter DW = 32)
(
    input  logic  [1:0]     sel,
    input  logic  [DW-1:0]  a1,
    input  logic  [DW-1:0]  a2,
    input  logic  [DW-1:0]  a3,
    input  logic  [DW-1:0]  a4,
    output logic  [DW-1:0]  y
);

always_comb begin 
    case (sel)
        2'b00: y <= a1;
        2'b01: y <= a2;
        2'b10: y <= a3;
        2'b11: y <= a4;
        default: y <= 'b0;
    endcase
end

endmodule
