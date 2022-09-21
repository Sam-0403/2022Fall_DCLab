module Blink (
	input        i_clk,
	input        i_rst_n,
	input        i_state,
	input [3:0]  i_random,
   output logic [15:0] led_out
);

// ===== States =====
parameter S_IDLE = 2'b00;
parameter S_PROC = 2'b01;
parameter S_RUNN = 2'b10;

parameter D0 = 16'b0000_0000_0000_0001;
parameter D1 = 16'b0000_0000_0000_0010;
parameter D2 = 16'b0000_0000_0000_0100;
parameter D3 = 16'b0000_0000_0000_1000;
parameter D4 = 16'b0000_0000_0001_0000;
parameter D5 = 16'b0000_0000_0010_0000;
parameter D6 = 16'b0000_0000_0100_0000;
parameter D7 = 16'b0000_0000_1000_0000;
parameter D8 = 16'b0000_0001_0000_0000;
parameter D9 = 16'b0000_0010_0000_0000;
parameter Da = 16'b0000_0100_0000_0000;
parameter Db = 16'b0000_1000_0000_0000;
parameter Dc = 16'b0001_0000_0000_0000;
parameter Dd = 16'b0010_0000_0000_0000;
parameter De = 16'b0100_0000_0000_0000;
parameter Df = 16'b1000_0000_0000_0000;
parameter Dnone = 16'b0000_0000_0000_0000;
parameter Dall = 16'b1111_1111_1111_1111;

// ===== Constants =====
parameter NUM_PERIOD = 32'b10_0000_0000_0000_0000_0000;
parameter NUM_TOTAL_PERIOD = 32'b100_0000_0000_0000_0000_0000;

// ===== Registers & Wires =====

// Regs & Wires for FSM
logic [31:0] counter_r, counter_w;

// ===== Output Buffers =====
logic [15:0] led_out_r, led_out_w;

// ===== Output Assignments =====

always_comb begin
	case(i_random)
		4'h0: begin led_out = D0; end
		4'h1: begin led_out = D1; end
		4'h2: begin led_out = D2; end
		4'h3: begin led_out = D3; end
		4'h4: begin led_out = D4; end
		4'h5: begin led_out = D5; end
		4'h6: begin led_out = D6; end
		4'h7: begin led_out = D7; end
		4'h8: begin led_out = D8; end
		4'h9: begin led_out = D9; end
		4'ha: begin led_out = Da; end
		4'hb: begin led_out = Db; end
		4'hc: begin led_out = Dc; end
		4'hd: begin led_out = Dd; end
		4'he: begin led_out = De; end
		4'hf: begin led_out = Df; end
	endcase
end

// ===== Sequential Circuits =====
always_ff @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
		led_out_r   <= 16'b0;
        counter_r   <= 32'b0;
	end
	else begin
		led_out_r   <= led_out_w;
        counter_r   <= counter_w;
	end
end

endmodule