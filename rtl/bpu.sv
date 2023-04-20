// GSHARE branch predictor
// This predictor is based on array of FSMs with 4 states: 
// strongly not taken, weakly not taken, weakly taken, strongly taken. FSM use state with saturation.
// Index to the array of FSMs is built using xor of global history and lower bits of PC.

module bpu
#(
    parameter PATTERN_NUM_BITS = 10
)    
(
    input  logic        clk,
    input  logic        rstn,
    input  logic        branch_cmd_E,
    input  logic        cmp_result,
    input  logic [PATTERN_NUM_BITS-1:0] pc,
    output logic        prediction,
);
    
localparam PHT_SIZE = 2 ** PATTERN_NUM_BITS ;

logic [1:0] pht [0:PHT_SIZE];   // Pattern History Table (PHT)

logic [PATTERN_NUM_BITS-1:0] pht_addr;
logic [PATTERN_NUM_BITS-1:0] prev_pht_addr;

logic branch_predict_ok;
logic predict_cmp;


// save prediction for compare result in next stage
always_ff @(posedge clk) begin : SAVE_PREDICTION
    if(~rstn) predict_cmp <= 1'b1;                  // default: predict = branch taken
    else predict_cmp <= prediction;
end

assign branch_predict_ok = predict_cmp & cmp_result;



//----------------------- Global History Register (GHR) -------------------------// 
// implemented shift register
logic [PATTERN_NUM_BITS-1:0] ghr_reg;

always_ff @(posedge clk) begin : GHR_SHIFT_REGISTER
    if(~rstn) ghr_reg <= 'b0;
    else begin
        if(branch_cmd_E)
            ghr_reg <= {ghr_reg[PATTERN_NUM_BITS-2:0], cmp_result};
    end
end


//----------------------- FSM Logic for every cell in PHT -------------------------//
typedef enum logic [1:0] 
{
    STRONGLY_NOT_TAKEN  = 2'b00,
    WEAKLY_NOT_TAKEN    = 2'b01,
    WEAKLY_TAKEN        = 2'b10,
    STRONGLY_TAKEN      = 2'b11
} state_t;


// transition logic
always_ff @(posedge clk) begin : TRANS_LOGIC
    if(~rstn) prev_pht_addr <= 'b0;          // default: predict = branch taken
    else begin
        if(branch_cmd_E)
            prev_pht_addr <= pht_addr;
    end
end

// write in PHT 
integer i = 0;
always_ff @(posedge clk) begin
    if(~rstn) begin
         for(i = 0; i < PHT_SIZE; i = i + 1) begin
            pht[i] <= STRONGLY_TAKEN;
         end
    end    
    
    if(branch_predict_ok) begin
        case (pht[prev_pht_addr])
            STRONGLY_NOT_TAKEN  : pht[prev_pht_addr] <= WEAKLY_NOT_TAKEN;     
            WEAKLY_NOT_TAKEN    : pht[prev_pht_addr] <= WEAKLY_TAKEN;
            WEAKLY_TAKEN        : pht[prev_pht_addr] <= STRONGLY_TAKEN;
            STRONGLY_TAKEN:     : pht[prev_pht_addr] <= STRONGLY_TAKEN;
            default             : pht[prev_pht_addr] <= STRONGLY_TAKEN;
        endcase    
    end
    else begin
        case (pht[prev_pht_addr])
            STRONGLY_NOT_TAKEN  : pht[prev_pht_addr] <= STRONGLY_NOT_TAKEN;     
            WEAKLY_NOT_TAKEN    : pht[prev_pht_addr] <= STRONGLY_NOT_TAKEN;
            WEAKLY_TAKEN        : pht[prev_pht_addr] <= WEAKLY_NOT_TAKEN;
            STRONGLY_TAKEN:     : pht[prev_pht_addr] <= WEAKLY_TAKEN;
            default             : pht[prev_pht_addr] <= STRONGLY_TAKEN;
        endcase
    end
end


// calculate address for PHT
assign pht_addr = pc ^ ghr_reg;

// make prediction
assign prediction = pht[pht_addr][1] ? 1'b1 : 1'b0;


endmodule
