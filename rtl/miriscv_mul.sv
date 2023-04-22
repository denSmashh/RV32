
module miriscv_mul
  import miriscv_pkg::XLEN;
  import miriscv_mdu_pkg::*;
#(
  parameter MUL_IMPLEMENTATION = "GENERIC" // GENERIC or XILINX_7_SERIES
) (
  // Clock, reset
  input  logic                clk_i,
  input  logic                arstn_i,

  // Div control
  input  logic                mul_start_i,
  input  logic [XLEN-1:0]     port_a_i,
  input  logic [XLEN-1:0]     port_b_i,
  input  logic [MDU_OP_W-1:0] mdu_op_i,
  input  logic                zero_i,
  input  logic                kill_i,
  input  logic                keep_i,

  // Div results
  output logic [XLEN-1:0]     mul_result_o,
  //output logic [XLEN-1:0]     rem_result_o,
  output logic                mul_stall_req_o
);


  ////////////////////////
  // Local declarations //
  ////////////////////////

  enum logic [2:0] {MUL_IDLE, MUL_FIRST, MUL_COMP, MUL_LAST,
                    MUL_SIGN_CHANGE, MUL_FINISH} d_state_ff, d_next_state;

  logic        [XLEN-1:0]         mul_result_ff;
  logic signed [2*XLEN:0]         rem_result_ff;
  logic        [XLEN-1:0]         mul_operand_a_ff;
  logic        [XLEN-1:0]         mul_operand_b_ff;
  logic                           sign_inv_ff;
  logic        [$clog2(XLEN)-1:0] iter_ff;

  logic                           sign_a;
  logic                           sign_b;
  logic                           mul_done;

  assign sign_a = port_a_i[XLEN-1];
  assign sign_b = port_b_i[XLEN-1];

  assign mul_done = (d_state_ff == MUL_FINISH);
  assign mul_stall_req_o = (mul_start_i && !mul_done);


  /////////////////////////
  // Next state decision //
  /////////////////////////

  always_ff @(posedge clk_i) begin
    if (~arstn_i) begin
      d_state_ff <= MUL_IDLE;
    end
    else begin
      if (kill_i)
        d_state_ff <= MUL_IDLE;
      else
        d_state_ff <= d_next_state;
    end
  end

  always_comb begin
    case (d_state_ff)

      MUL_IDLE: begin
        if (mul_start_i)
          d_next_state = MUL_FIRST;
        else
          d_next_state = MUL_IDLE;
      end

      MUL_FIRST: begin
        if (zero_i)
          d_next_state = MUL_FINISH;
        else
          d_next_state = MUL_COMP;
      end

      MUL_COMP: begin
        if (iter_ff == 'd1)
          d_next_state = MUL_LAST;
        else
          d_next_state = MUL_COMP;
      end

      MUL_LAST: begin
        if (sign_inv_ff) begin
          d_next_state = MUL_SIGN_CHANGE;
        end
        else begin
          d_next_state = MUL_FINISH;
        end
      end

      MUL_SIGN_CHANGE: begin
        d_next_state = MUL_FINISH;
      end

      MUL_FINISH: begin
        if (~keep_i)
          d_next_state = MUL_IDLE;
        else
          d_next_state = MUL_FINISH;
      end

      default: begin
        d_next_state = MUL_IDLE;
      end

    endcase
  end


  //////////////////////////////////
  // Multiplication state machine //
  //////////////////////////////////

  generate
    if (MUL_IMPLEMENTATION == "XILINX_7_SERIES") begin : dsp_div

      logic        [6:0]  dsp48_opmode;
      logic        [3:0]  dsp48_alumode;
      logic signed [29:0] dsp48_A;
      logic signed [17:0] dsp48_B;
      logic signed [47:0] dsp48_C;
      logic signed [47:0] dsp48_P;

      localparam [1:0] OPMODE_X_AB_CONCAT = 2'b11;
      localparam [1:0] OPMODE_Y_ZERO      = 2'b00;
      localparam [2:0] OPMODE_Z_C         = 3'b011;
      localparam [3:0] ALUMODE_SUM        = 4'b0000;
      localparam [3:0] ALUMODE_INV_Z      = 4'b0001;
      localparam [3:0] ALUMODE_SUB        = 4'b0011;

      mrv1f_dsp48_wrapper
      #(
        .A_INPUT_SOURCE ( "DIRECT" ),
        .B_INPUT_SOURCE ( "DIRECT" ),
        .USE_MULT       ( "NONE"   ),
        .A_REG          ( 2'b0     ),
        .B_REG          ( 2'b0     ),
        .P_REG          ( 1'b0     )
      )
      i_dsp48
      (
        .clk_i   ( clk_i         ),
        .srstn_i ( arstn_i       ),
        .enable  ( 1'b1          ),
        .OPMODE  ( dsp48_opmode  ),
        .ALUMODE ( dsp48_alumode ),
        .A       ( dsp48_A       ),
        .B       ( dsp48_B       ),
        .C       ( dsp48_C       ),
        .P       ( dsp48_P       )
      );

      assign dsp48_opmode[6:4] = OPMODE_Z_C;
      assign dsp48_opmode[3:2] = OPMODE_Y_ZERO;
      assign dsp48_opmode[1:0] = OPMODE_X_AB_CONCAT;

      always_comb begin
        case ({rem_result_ff[2*XLEN], d_state_ff}) inside
          {1'b0, DIV_LAST},
          {1'b?, DIV_SIGN_CHANGE}: dsp48_A = 'd0;
          default:                 dsp48_A = {'0, div_operand_b_ff[XLEN-1:18]};
        endcase

        case ({rem_result_ff[2*XLEN], d_state_ff}) inside
          {1'b0, DIV_LAST}:        dsp48_B = 'd0;
          {1'b?, DIV_SIGN_CHANGE}: dsp48_B = 'd1;
          default:                 dsp48_B = div_operand_b_ff[17:0];
        endcase

        case (d_state_ff)
          DIV_FIRST: dsp48_C = div_operand_a_ff[XLEN-1];
          DIV_COMP:  dsp48_C = rem_result_ff[2*XLEN-1:XLEN-1];
          default:   dsp48_C = rem_result_ff[2*XLEN:XLEN];
        endcase

        case ({rem_result_ff[2*XLEN], d_state_ff}) inside
          {1'b1, DIV_COMP},
          {1'b1, DIV_LAST}:        dsp48_alumode = ALUMODE_SUM;
          {1'b?, DIV_SIGN_CHANGE}: dsp48_alumode = ALUMODE_INV_Z;
          default:                 dsp48_alumode = ALUMODE_SUB;
        endcase
      end

      always_ff @(posedge clk_i) begin
        if (~arstn_i) begin
          mul_result_ff    <= {XLEN{1'b0}};
          //rem_result_ff    <= {(2*XLEN+1){1'b0}};
          div_operand_a_ff <= {(XLEN){1'b0}};
          div_operand_b_ff <= {(XLEN){1'b0}};
          sign_inv_ff      <= 1'b0;
          iter_ff          <= {($clog2(XLEN)){1'b0}};
        end
        else begin
          rem_result_ff[2*XLEN:XLEN] <= dsp48_P[XLEN:0];

          case (d_state_ff)

            DIV_IDLE: begin
              case (mdu_op_i)
                MDU_DIV,
                MDU_REM:  begin
                  div_operand_a_ff <= sign_a ? (~port_a_i + 'd1) : (port_a_i);
                  div_operand_b_ff <= sign_b ? (~port_b_i + 'd1) : (port_b_i);
                end
                MDU_DIVU,
                MDU_REMU: begin
                  div_operand_a_ff <= port_a_i;
                  div_operand_b_ff <= port_b_i;
                end
                default: ;
              endcase

              case (mdu_op_i)
                MDU_DIV: sign_inv_ff <= (sign_a ^ sign_b);
                MDU_REM: sign_inv_ff <= sign_a;
                default: sign_inv_ff <= 1'b0;
              endcase
            end

            DIV_FIRST: begin
              iter_ff <= XLEN - 1;
              if (zero_i) begin
                div_result_ff <= '1;
                rem_result_ff[2*XLEN-1:XLEN] <= port_a_i;
              end
              else begin
                div_result_ff           <= {{(XLEN-1){~sign_inv_ff}}, 1'b1};
                rem_result_ff[XLEN-1:0] <= {div_operand_a_ff[XLEN-2:0], 1'b0};
              end
            end

            DIV_COMP,
            DIV_LAST: begin
              iter_ff <= iter_ff - 1;
              rem_result_ff[XLEN-1:0] <= {rem_result_ff[XLEN-2:0], 1'b0};
              div_result_ff[iter_ff]  <= !rem_result_ff[2*XLEN];
            end

            DIV_SIGN_CHANGE: begin
              div_result_ff <= ~div_result_ff + 'd1;
            end

            default: ;
          endcase
        end
      end

    end
    else if (MUL_IMPLEMENTATION == "GENERIC") begin

      always_ff @(posedge clk_i) begin
        if (~arstn_i) begin
          div_result_ff    <= {XLEN{1'b0}};
          rem_result_ff    <= {(2*XLEN+1){1'b0}};
          mul_operand_a_ff <= {(XLEN){1'b0}};
          mul_operand_b_ff <= {(XLEN){1'b0}};
          sign_inv_ff      <= 1'b0;
          iter_ff          <= {($clog2(XLEN)){1'b0}};
        end
        else begin
          case (d_state_ff)
    
            MUL_IDLE: begin
              case (mdu_op_i)
                MDU_MUL, MDU_MULH: begin
                  mul_operand_a_ff <= sign_a ? (~port_a_i + 'd1) : port_a_i;
                  mul_operand_b_ff <= sign_b ? (~port_b_i + 'd1) : port_b_i;
                end
                MDU_MULHU: begin
                  mul_operand_a_ff <= port_a_i;
                  mul_operand_b_ff <= port_b_i;
                end
                MDU_MULHSU: begin
                  mul_operand_a_ff <= sign_a ? (~port_a_i + 'd1) : port_a_i;
                  mul_operand_b_ff <= port_b_i;
                end
                default: ;
              endcase

              case (mdu_op_i)
                MDU_MUL, MDU_MULH, MDU_MULHSU: sign_inv_ff <= (sign_a ^ sign_b);
                default: sign_inv_ff <= 1'b0;
              endcase
            end

            MUL_FIRST: begin
              iter_ff <= XLEN - 'd1;
              if (zero_i) begin
                mul_result_ff <= '0;
                //rem_result_ff[2*XLEN-1:XLEN] <= port_a_i;
              end
              else begin
                mul_result_ff <= {{(XLEN-1){~sign_inv_ff}}, 1'b1};
                rem_result_ff[2*XLEN:XLEN] <= div_operand_a_ff[XLEN-1] - div_operand_b_ff[XLEN-1:0];
                rem_result_ff[XLEN-1:0] <= {div_operand_a_ff[XLEN-2:0], 1'b0};
              end
            end

            MUL_COMP: begin
              iter_ff <= iter_ff - 'd1;
              div_result_ff[iter_ff] <= !rem_result_ff[2*XLEN];
              rem_result_ff[XLEN-1:0] <= {rem_result_ff[XLEN-2:0], 1'b0};
              if (rem_result_ff[2*XLEN]) begin
                rem_result_ff[2*XLEN:XLEN] <= rem_result_ff[2*XLEN-1:XLEN-1] + div_operand_b_ff[XLEN-1:0];
              end
              else begin
                rem_result_ff[2*XLEN:XLEN] <= rem_result_ff[2*XLEN-1:XLEN-1] - div_operand_b_ff[XLEN-1:0];
              end
            end

            MUL_LAST: begin
              div_result_ff[0] <= !rem_result_ff[2*XLEN];
              if (rem_result_ff[2*XLEN]) begin
                rem_result_ff[2*XLEN:XLEN] <= rem_result_ff[2*XLEN:XLEN] + div_operand_b_ff[XLEN-1:0];
              end
            end

            MUL_SIGN_CHANGE: begin
              rem_result_ff[2*XLEN:XLEN] <= ~rem_result_ff[2*XLEN:XLEN] + 'd1;
              mul_result_ff <= ~mul_result_ff + 'd1;
            end

            default: ;
          endcase
        end
      end

    end
  endgenerate

  assign div_result_o = div_result_ff;
  //assign rem_result_o = rem_result_ff[2*XLEN-1:XLEN];

  initial begin
    if ((MUL_IMPLEMENTATION != "XILINX_7_SERIES") &&
         (MUL_IMPLEMENTATION != "GENERIC")) begin
      $error("Illegal parameter 'MUL_IMPLEMENTATION' in module 'mrv1f_div': %s", MUL_IMPLEMENTATION);
    end
  end

endmodule
