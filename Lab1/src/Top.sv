module Top (
	input        i_clk,
	input        i_rst_n,
	input        i_start,
	output [3:0] o_random_out
);

// please check out the working example in lab1 README (or Top_exmaple.sv) first

// ===== States =====
parameter S_IDLE = 2'b00;
parameter S_PROC = 2'b01;
parameter S_RUNN = 2'b10;

// ===== Constants =====
parameter NUM_PERIOD = 32'b1000_0000_0000;

// ===== Output Buffers =====
logic [3:0] o_random_out_r, o_random_out_w;

// ===== Registers & Wires =====

// Regs & Wires for FSM
logic [1:0] state_r, state_w;

// Regs & Wires for Counter Comparator
logic [31:0] counter_r, counter_w;
logic [31:0] compare_r, compare_w;

// Regs & Wires for LFSR
// http://www.xilinx.com/support/documentation/application_notes/xapp052.pdf
logic [9:0] LFSR_r, LFSR_w;

// ===== Output Assignments =====
assign o_random_out = o_random_out_r;

// ===== Combinational Circuits =====
always_comb begin
	// Default Values
	o_random_out_w = o_random_out_r;
	state_w        = state_r;
	counter_w      = counter_r;
	compare_w      = compare_r;
	LFSR_w         = LFSR_r;

	// FSM
	case(state_r)
	S_IDLE: begin
		if (i_start) begin
			state_w         = S_PROC;
			o_random_out_w  = {LFSR_r[3], LFSR_r[2], LFSR_r[1], LFSR_r[0]};
			counter_w       = 32'b0;
			compare_w       = NUM_PERIOD;
		end
	end

	S_PROC: begin
		if (i_start && counter_r > 10) begin
			state_w         = S_RUNN;
			o_random_out_w  = {LFSR_r[3], LFSR_r[2], LFSR_r[1], LFSR_r[0]};
			// o_random_out_w  = {counter_r[3], counter_r[2], counter_r[1], counter_r[0]};
			counter_w       = 32'b0;
			compare_w 		= NUM_PERIOD;
		end
		else begin
			counter_w       = counter_r + 1'b1;
		end
	end

	S_RUNN: begin
		// if (i_start) begin
		// 	// TODO: 截取亂數
		// end
		
		// else if (counter_r == compare_r) begin
		if (counter_r == compare_r) begin
			state_w         = S_RUNN;
			LFSR_w          = {~(LFSR_r[0]^LFSR_r[3]), LFSR_r[9], LFSR_r[8], LFSR_r[7], LFSR_r[6], 
			                    LFSR_r[5], LFSR_r[4], LFSR_r[3], LFSR_r[2], LFSR_r[1]};
			o_random_out_w  = {LFSR_r[3], LFSR_r[2], LFSR_r[1], LFSR_r[0]};
			counter_w       = counter_r + 1'b1;
			compare_w       = compare_r << 1;
		end

		else if (counter_r == 32'b111_1111_1111_1111_1111_1111_1111) begin
			state_w         = S_IDLE;
			LFSR_w          = {~(LFSR_r[0]^LFSR_r[3]), LFSR_r[9], LFSR_r[8], LFSR_r[7], LFSR_r[6], 
			                    LFSR_r[5], LFSR_r[4], LFSR_r[3], LFSR_r[2], LFSR_r[1]};
			o_random_out_w  = {LFSR_r[3], LFSR_r[2], LFSR_r[1], LFSR_r[0]};           
		end

		else begin
			state_w         = S_RUNN;
			o_random_out_w  = {LFSR_r[3], LFSR_r[2], LFSR_r[1], LFSR_r[0]};
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
		state_r        <= S_IDLE;
		counter_r      <= 32'b0;
		compare_r      <= NUM_PERIOD;
		LFSR_r         <= 10'b0;
	end

	else begin
		o_random_out_r <= o_random_out_w;
		state_r        <= state_w;
		counter_r      <= counter_w;
		compare_r      <= compare_w;
		LFSR_r         <= LFSR_w;
	end
end

endmodule
