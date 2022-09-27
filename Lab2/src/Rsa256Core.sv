// Operations for RSA256 decryption
// namely, the Montgomery algorithm
module Rsa256Core (
	input          i_clk,
	input          i_rst,
	input          i_start,
	input  [255:0] i_a, // cipher text y
	input  [255:0] i_d, // private key
	input  [255:0] i_n,
	output [255:0] o_a_pow_d, // plain text x
	output         o_finished
);
// ===== States =====
parameter S_IDLE = 2'd0;
parameter S_PREP = 2'd1;
parameter S_MONT = 2'd2;
parameter S_CALC = 2'd3;

// ===== Output Buffers =====
logic [255:0] m_r, m_w;
logic o_finish_r, o_finish_w;

// ===== Registers & Wires =====
logic [1:0] state_r, state_w;
logic [7:0] counter_r, counter_w;
logic [255:0] t_r, t_w;
logic [255:0] d_index_r, d_index_w;
logic [255:0] a_store_r, a_store_w;

endmodule

// ==============================
// Module for Modulo of Products
// ==============================
module RsaPrep (
	input          i_clk,
	input          i_rst,
	input          i_start,
	input  [255:0] i_a, 
	input  [255:0] i_n,
	output [255:0] o_mod,
	output         o_finish
);
// ===== States =====
localparam S_IDLE = 1'b0;
localparam S_PROC = 1'b1;

// ===== Output Buffers =====
logic [256:0] data_r, data_w;
logic o_finish_r, o_finish_w;

// ===== Registers & Wires =====

// Regs & Wires for State
logic state_r, state_w;
// Regs & Wires for Counter (0~255)
logic [7:0] counter_r, counter_w
// Wires for Temporary Value
logic [256:0] temp1_w, temp2_w;

// ===== Output Assignments =====
assign o_mod	= data_r[255:0];
assign o_finish	= o_finish_r;

// ===== Combinational Circuits =====
always_comb begin
	// Default Values
	temp1_w		= data_r << 1;
	temp2_w		= (temp1_w > i_n)? temp1_w - i_n : temp1_w; 
	data_w		= data_r;
	o_finish_w	= o_finish_r;
	state_w		= state_r;
	counter_w	= counter_r;

	// FSM
	case (state_r)
		S_IDLE: begin
			if(i_start) begin
				state_w		= S_PROC;
				data_w		= {1'b0, i_a};
			end
			counter_w		= 8'b0;
			o_finish_w		= 1'b0;
		end
		S_PROC: begin
			if(counter_r == 8'd255) begin
				state_w		= S_IDLE;
				counter_w	= 8'b0;
				o_finish_w	= 1'b1;
			end
			else begin
				state_w		= state_r;
				counter_w	= counter_r + 1'b1;
				o_finish_w	= 1'b0;
			end
			data_w	= temp2_w;
		end
	endcase
end

// ===== Sequential Circuits =====
always_ff @(posedge i_clk or negedge i_rst) begin
	if(~i_rst) begin
		state_r		<= S_IDLE;
		counter_r	<= 8'd0;
		data_r		<= 257'd0;
		o_finish_r	<= 1'd0;
	end 
	else begin
		state_r		<= state_w;
		counter_r 	<= counter_w;
		data_r		<= data_w;
		o_finish_r	<= o_finish_w;
	end
end

endmodule

// ==============================
// Module for Montgomery Algorithm
// ==============================
module RsaMont (
	input          i_clk,
	input          i_rst,
	input          i_start,
	input  [255:0] i_a, 
	input  [255:0] i_b,
	input  [255:0] i_n,
	output [255:0] o_mod,
	output         o_finish
);

// ===== States =====
localparam S_IDLE = 1'b0;
localparam S_PROC = 1'b1;

// ===== Output Buffers =====
logic [257:0] data_r, data_w;
logic o_finish_r, o_finish_w;

// ===== Registers & Wires =====

// Regs & Wires for State
logic state_r, state_w;
// Regs & Wires for Counter (0~255)
logic [7:0] counter_r, counter_w
// Wires for Temporary Value
logic [256:0] temp1_w, temp2_w, temp3_w;
// Regs & Wires for Index of a (0~255)
logic [255:0] a_index_r, a_index_w;

// ===== Output Assignments =====
assign o_mod	= data_r[255:0];
assign o_finish	= o_finish_r;

// ===== Combinational Circuits =====
always_comb begin
	// Default Values
	if(a_index_r[0]) begin
		temp1_w = data_r + {2'b0,i_b};
	end
	else begin
		temp1_w = data_r;
	end
	if(temp1_w[0]) begin
		temp2_w = temp1_w + {2'b0,i_n};
	end
	else begin
		temp2_w = temp1_w;
	end
	temp3_w = temp2_w >> 1;

	data_w		= data_r;
	o_finish_w	= o_finish_r;
	state_w		= state_r;
	counter_w	= counter_r;
	a_index_w	= a_index_r;

	// FSM
	case (state_r)
		S_IDLE: begin
			if(i_start) begin
				state_w		= S_PROC;
			end
			counter_w		= 8'b0;
			o_finish_w		= 1'b0;
			data_w			= 257'd0;
			a_index_w		= i_a;
		end
		S_PROC: begin
			if(counter_r == 8'd255) begin
				state_w		= S_IDLE;
				counter_w	= 8'b0;
				data_w		= (temp3_w >= {2'b0,i_n})? temp3_w - {2'b0,i_n} : temp3_w;
				o_finish_w	= 1'b1;
			end
			else begin
				state_w		= state_r;
				counter_w	= counter_r + 1'b1;
				data_w		= temp3_w;
				o_finish_w	= 1'b0;
			end
			a_index_w		= a_index_r >> 1;
		end
	endcase
end

// ===== Sequential Circuits =====
always_ff @(posedge i_clk or negedge i_rst) begin
	if(~i_rst) begin
		state_r		<= S_IDLE;
		counter_r	<= 8'd0;
		data_r		<= 257'd0;
		o_finish_r	<= 1'd0;
		a_index_r	<= i_a;
	end 
	else begin
		state_r		<= state_w;
		counter_r 	<= counter_w;
		data_r		<= data_w;
		o_finish_r	<= o_finish_w;
		a_index_r	<= a_index_w;
	end
end

endmodule