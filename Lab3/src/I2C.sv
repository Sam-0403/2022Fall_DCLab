module I2cInitializer(
	input i_rst_n,
	input i_clk,
	input i_start,
	output o_finished,
	output o_sclk,
	input o_sdat,
	output o_oen // you are outputing (you are not outputing only when you are "ack"ing.)
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