module Top (
	input        i_clk,
	input        i_rst_n,
	input        i_start,
	input        i_control,
	input  		 i_index_0, //SW 0
	input  		 i_index_1, //SW 1
	input  		 i_index_2, //SW 2
	input  		 i_index_3, //SW 3
	output [3:0] o_random_out,
	output [3:0] o_stored_out
);

// please check out the working example in lab1 README (or Top_exmaple.sv) first

// ===== States =====
parameter S_IDLE = 2'b00;
parameter S_PROC = 2'b01;
parameter S_RUNN = 2'b10;

// ===== Constants =====
parameter NUM_PERIOD = 32'b10_0000_0000_0000_0000_0000;

// ===== Output Buffers =====
logic [3:0] o_random_out_r, o_random_out_w;
logic [3:0] o_stored_out_r, o_stored_out_w;

// ===== Registers & Wires =====

// Regs & Wires for FSM
logic [1:0] state_r, state_w;

// Regs & Wires for Counter Comparator
logic [9:0] counter_seed_r, counter_seed_w;
logic [31:0] counter_r, counter_w;
logic [31:0] compare_r, compare_w;

// Regs & Wires for Stored Value Index
logic [63:0] stored_out_r, stored_out_w;
logic [9:0] counter_index_r, counter_index_w;
logic [5:0] stored_index_r, stored_index_w;

// Regs & Wires for LFSR
// http://www.xilinx.com/support/documentation/application_notes/xapp052.pdf
logic [9:0] LFSR_r, LFSR_w;

// // ===== Modules =====
// Blink blink0 (
// 	.i_clk(i_clk),
// 	.i_rst_n(i_rst_n),
// 	.i_state(state_r),
// 	.i_random(o_random_out_r),
//     .led_out(LEDG[3:0]),
// );

// ===== Output Assignments =====
assign o_random_out = o_random_out_r;
assign o_stored_out  = o_stored_out_r;

// ===== Combinational Circuits =====
always_comb begin
	// Default Values
	o_random_out_w = o_random_out_r;

	state_w        = state_r;
	counter_seed_w = counter_seed_r;
	counter_w      = counter_r;
	compare_w      = compare_r;

	LFSR_w         = LFSR_r;

	o_stored_out_w  = o_stored_out_r;
	stored_out_w  = stored_out_r;
	counter_index_w = counter_index_r;
	stored_index_w = stored_index_r;

	// FSM
	case(state_r)
	S_IDLE: begin
		if (i_start) begin
			state_w         = S_PROC;
			o_random_out_w  = 4'b0;
			o_stored_out_w  = 4'b0;
			stored_out_w  = 64'b0;
			counter_index_w = 10'b0;
			counter_seed_w  = 10'b0;
			counter_w       = 32'b0;
			compare_w       = NUM_PERIOD;
		end
	end

	S_PROC: begin
		if (i_start && counter_seed_r > 10) begin
			state_w         = S_RUNN;
			o_random_out_w  = 4'b0;
			o_stored_out_w  = 4'b0;
			stored_out_w  = 64'b0;
			counter_index_w = 10'b0;
			LFSR_w 			= counter_seed_r;
			counter_w       = 32'b0;
			compare_w 		= NUM_PERIOD;
		end
		else begin
			counter_seed_w       = counter_seed_r + 1'b1;
		end
	end

	S_RUNN: begin
		if (counter_r == compare_r) begin
			state_w         = S_RUNN;
			LFSR_w          = {~(LFSR_r[0]^LFSR_r[3]), LFSR_r[9:1]};
			o_random_out_w  = LFSR_r[3:0];
			stored_out_w[counter_index_r +: 4] = LFSR_r[3:0];
			counter_w       = 32'b0;
			compare_w       = compare_r + NUM_PERIOD;
			counter_index_w = counter_index_r + 10'b100;
		end

		else if (compare_r == 32'b10_0000_0000_0000_0000_0000_0000) begin
			state_w         = S_IDLE;
			LFSR_w          = {~(LFSR_r[0]^LFSR_r[3]), LFSR_r[9:1]};      
			o_random_out_w  = LFSR_r[3:0];   
			counter_index_w = 10'b0;
		end

		else if (i_control) begin
			o_stored_out_w = stored_out_r[stored_index_r +: 4];
		end

		else begin
			state_w         = S_RUNN;
			o_random_out_w  = LFSR_r[3:0];
			counter_w       = counter_r + 1'b1;
		end
	end

	endcase
end

// ===== Sequential Circuits =====
always_ff @(posedge i_clk or negedge i_rst_n) begin
	// reset
	if (!i_rst_n) begin
		o_random_out_r <= 4'd0;
		o_stored_out_r <= 4'd0;
		stored_out_r   <= 64'd0;
		state_r        <= S_IDLE;
		counter_seed_r <= counter_seed_w;
		counter_r      <= 32'b0;
		compare_r      <= NUM_PERIOD;
		counter_index_r <= 10'b0;
		stored_index_r <= 6'b0;
		LFSR_r         <= 10'b0;
	end

	else begin
		o_random_out_r <= o_random_out_w;
		o_stored_out_r <= o_stored_out_w;
		stored_out_r   <= stored_out_w;
		state_r        <= state_w;
		counter_seed_r <= counter_seed_w;
		counter_r      <= counter_w;
		compare_r      <= compare_w;
		counter_index_r <= counter_index_w;
		stored_index_r <= {i_index_3, i_index_2, i_index_1, i_index_0, 1'b0, 1'b0};
		LFSR_r         <= LFSR_w;
	end
end

endmodule
