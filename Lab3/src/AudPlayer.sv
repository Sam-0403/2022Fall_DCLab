module AudPlayer(
	input i_rst_n,
	input i_bclk,
	input i_daclrck,
	input i_en,                     // enable AudPlayer only when playing audio, work with AudDSP
	input signed [15:0] i_dac_data, // dac_data
	output o_aud_dacdat
);

// ===== States =====
localparam S_IDLE = 2'd0;
localparam S_PLAY = 2'd1;
localparam S_WAIT = 2'd2;

// ===== Constants =====
// Skipped

// ===== Registers & Wires =====
logic [1:0] state_r, state_w;
logic [4:0] counter_r, counter_w;
logic o_aud_dacdat_r, o_aud_dacdat_w;

// ===== Output Assignments =====
assign o_aud_dacdat = o_aud_dacdat_r;

// ===== Combinational Circuits =====
always_comb begin
    // Default Values
    state_w = state_r;
    counter_w = counter_r;
    o_aud_dacdat_w = o_aud_dacdat_r;
    // FSM
    case (state_r)
        S_IDLE: begin
            if(i_en & !i_daclrck) begin
                state_w = S_PLAY;
                counter_w = 5'd1;
                o_aud_dacdat_w = i_dac_data[5'd15-counter_r];
            end
            else begin
                counter_w = 5'd0;
                o_aud_dacdat_w = o_aud_dacdat_r;
            end
        end
        S_PLAY: begin
            if(counter_r == 5'd15) begin
                state_w = S_WAIT;
                counter_w = 5'd0;
                o_aud_dacdat_w = i_dac_data[5'd15-counter_r];
            end
            else begin
                counter_w = counter_r + 5'd1;
                o_aud_dacdat_w = i_dac_data[5'd15-counter_r];
            end
        end
        S_WAIT: begin
            if(i_daclrck) begin
                state_w = S_IDLE;
            end
        end
    endcase
end

// ===== Sequential Circuits =====
always_ff @(posedge i_bclk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        state_r <= S_IDLE;
        counter_r <= 5'd0;
        o_aud_dacdat_r <= 1'b0;
    end
    else begin
        state_r <= state_w;
        counter_r <= counter_w;
        o_aud_dacdat_r <= o_aud_dacdat_w;
    end
end

endmodule