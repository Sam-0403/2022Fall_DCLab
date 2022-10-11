// Rail-Fence Cipher
module RailFenceCore (
	input          i_clk,
	input          i_rst,
	input          i_start,
	input  [255:0] i_enc, // cipher text y
	output [255:0] o_dec, // plain text x
	output         o_finished
);
// ===== States =====
localparam S_IDLE = 1'd0;
localparam S_CALC = 1'd1;

// ===== Output Buffers =====
logic [255:0] dec_r, dec_w;
logic o_finish_r, o_finish_w;

// ===== Registers & Wires =====

// Regs & Wires for State
logic [1:0] state_r, state_w;
// Regs & Wires for Counter (0~128)
logic [7:0] counter_r, counter_w;
// Regs & Wires for Storing i_enc
logic [255:0] enc_r, enc_w;
logic [127:0] rail_1_r, rail_1_w, rail_2_r, rail_2_w;
// Wires for Delay Reset Signal
logic i_rst_delay, i_rst_new;

// ===== Output Assignments =====
assign o_dec = dec_r;
assign o_finished = o_finish_r;
assign i_rst_new = ~(i_rst_delay^i_rst);

// ===== Combinational Circuits =====
always_comb begin
	// Defaults
	state_w			= state_r;
	counter_w		= counter_r;
	enc_w			= enc_r;
	dec_w			= dec_r;
	rail_1_w		= rail_1_r;
	rail_2_w		= rail_2_r;
	o_finish_w		= o_finish_r;
	// FSM
	case(state_r)
	S_IDLE: begin
		if(i_start) begin
			state_w		= S_CALC;
			enc_w		= i_enc;
			rail_1_w	= i_enc[255:128];
			rail_2_w	= i_enc[127:0];
		end
		counter_w		= 8'd0;
		o_finish_w		= 1'b0;
	end
	S_CALC: begin
		if(counter_r == 8'd128) begin
			state_w			= S_IDLE;
			counter_w		= 8'd0;
			o_finish_w		= 1'd1;
		end
		else begin
			state_w			= S_CALC;
			counter_w		= counter_r + 8'd1;
			o_finish_w		= 1'd0;
			dec_w			= (dec_r << 2) + {253'd0, rail_1_r[127], rail_2_r[127]};
			rail_1_w 		= rail_1_r << 1;
			rail_2_w		= rail_2_r << 1;
		end
	end
	endcase
end

always_ff @(posedge i_clk) begin
	i_rst_delay <= i_rst;
end

// ===== Sequential Circuits =====
always_ff @(posedge i_clk or negedge i_rst_new) begin
	if(~i_rst_new) begin
		state_r			<= S_IDLE;
		counter_r		<= 8'd0;
		o_finish_r		<= 1'd0;
		enc_r			<= enc_w;
		rail_1_r		<= 127'd0;
		rail_2_r		<= 127'd0;
		dec_r			<= 256'd0;
	end
	else begin
		state_r			<= state_w;
		counter_r		<= counter_w;
		o_finish_r		<= o_finish_w;
		enc_r			<= enc_w;
		rail_1_r		<= rail_1_w;
		rail_2_r		<= rail_2_w;
		dec_r			<= dec_w;
	end
end

endmodule
