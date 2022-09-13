module alu(
             clk_p_i,
             reset_n_i,
             data_a_i,
             data_b_i,
             inst_i,
             data_o
             );
  /* ============================================ */
      input           clk_p_i;
      input           reset_n_i;
      input   [7:0]   data_a_i;
      input   [7:0]   data_b_i;
      input   [2:0]   inst_i;

      output  [15:0]  data_o;

  /* ============================================ */
      logic    [15:0]  out_inst_0;
      logic    [15:0]  out_inst_1;
      logic    [15:0]  out_inst_2;
      logic    [15:0]  out_inst_3;
      logic    [15:0]  out_inst_4;
      logic    [15:0]  out_inst_5;
      logic    [15:0]  out_inst_6;
      logic    [15:0]  out_inst_7;

      logic    [15:0]  ALU_out_inst;
      logic    [15:0]  ALU_d2_w;

      logic    [15:0]  ALU_d2_r;
    
      logic    [7:0]   logic_data_a;
      logic    [7:0]   logic_data_b;
      logic    [2:0]   logic_inst;
      logic    [15:0]  logic_subtraction;

      assign ALU_d2_w = ALU_out_inst;
      assign data_o   = ALU_d2_r;
  
      assign out_inst_0 = {8'b0 , logic_data_a[7:0]} + {8'b0 , logic_data_b[7:0]};
      assign out_inst_1 = {8'b0 , logic_data_b[7:0]} - {8'b0 , logic_data_a[7:0]};
      assign out_inst_2 = {8'b0 , logic_data_a[7:0]} * {8'b0 , logic_data_b[7:0]};
      assign out_inst_3[15:8] = 8'b0;
      assign out_inst_3[ 7:0] = ~logic_data_a[7:0];
      assign out_inst_4[15:8] = 8'b0;
      assign out_inst_4[ 7:0] = logic_data_a[7:0] ^ logic_data_b[7:0];
      assign out_inst_5[15:8] = 8'b0;
      assign out_inst_5[ 7:0] = logic_data_a[7] ? ~logic_data_a[ 7:0]+1 : logic_data_a[ 7:0];
      assign logic_subtraction  = {8'b0 , logic_data_b[7:0]} - {8'b0 , logic_data_a[7:0]};
      assign out_inst_6 = {logic_subtraction[15] , logic_subtraction[15:1]};

  /* ============================================ */
  // The output MUX
      always_comb
      begin
          case(logic_inst)
           3'b000:    ALU_out_inst = out_inst_0;           
           3'b001:    ALU_out_inst = out_inst_1;
           3'b010:    ALU_out_inst = out_inst_2;
           3'b011:    ALU_out_inst = out_inst_3;
           3'b100:    ALU_out_inst = out_inst_4;
           3'b101:    ALU_out_inst = out_inst_5;
           3'b110:    ALU_out_inst = out_inst_6;
           3'b111:    ALU_out_inst = out_inst_7;
           default:   ALU_out_inst = 0;
          endcase
      end

  /* ============================================ */
      always_ff @(posedge clk_p_i or negedge reset_n_i)
      begin
          if (reset_n_i == 1'b0)
          begin
              logic_inst   <= 8'd0;
              logic_data_a <= 8'd0;
              logic_data_b <= 8'd0;
              ALU_d2_r   <= 16'd0;
          end
          else
          begin
              ALU_d2_r   <= ALU_d2_w;
              logic_inst   <= inst_i;
              logic_data_a <= data_a_i;
              logic_data_b <= data_b_i;
          end
      end
  /* ============================================ */

endmodule

