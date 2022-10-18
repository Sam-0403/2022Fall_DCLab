module AudPlayer(
	input i_rst_n,
	input i_bclk,
	input i_daclrck,
	input i_en,                     // enable AudPlayer only when playing audio, work with AudDSP
	input signed [15:0] i_dac_data, // dac_data
	output o_aud_dacdat
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
always_ff @(posedge i_bclk or negedge i_rst_n) begin
    if (!i_rst_n) begin
    end
    else begin
    end
end

endmodule