module AudDSP(
	input i_rst_n,
	input i_clk,
	input i_start,
	input i_pause,
	input i_stop,
	input [2:0] i_speed,  // 1~8: Speed
	input i_fast,
	input i_slow_0, // constant interpolation
	input i_slow_1, // linear interpolation
	input i_daclrck,
	input [15:0] i_sram_data,
	output [15:0] o_dac_data,
	output [19:0] o_sram_addr
);

// ===== States =====

// ===== Constants =====

// ===== Registers & Wires =====

// ===== Output Assignments =====

// ===== Combinational Circuits =====
always_comb begin
    // Default Values
    // FSM
end

// ===== Sequential Circuits =====
always_ff @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
    end
    else begin
    end
end

endmodule