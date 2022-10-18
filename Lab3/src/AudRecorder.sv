module AudRecorder(
	input i_rst_n, 
	input i_clk,
	input i_lrc,
	input i_start,
	input i_pause,
	input i_stop,
	input i_data,
	output [19:0] o_address,
	output [15:0] o_data,
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