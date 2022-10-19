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
localparam S_IDLE = 2'd0;
localparam S_PLAY = 2'd1;
localparam S_PAUSE = 2'd2;

// ===== Constants =====
// Skipped

// ===== Registers & Wires =====
logic [1:0]  state_r, state_w;
logic signed [15:0] o_dac_data_r, o_dac_data_w;
logic signed [15:0] prev_data_r, prev_data_w;
logic [19:0] o_sram_addr_r, o_sram_addr_w;
logic [3:0]  counter_r, counter_w;
logic [3:0]  ratio;
logic        prev_daclrck_r, prev_daclrck_w;

// ===== Output Assignments =====
assign o_dac_data = (i_daclrck == 0) ? o_dac_data_w : 16'bZ;
assign o_sram_addr = o_sram_addr_w;

// ===== Combinational Circuits =====
always_comb begin
    // Default Values
    state_w = state_r;
    o_dac_data_w = o_dac_data_r;
    prev_data_w = prev_data_r;
    o_sram_addr_w = o_sram_addr_r;
    counter_w = counter_r;
    prev_daclrck_w = i_daclrck;
    // FSM
    case(state_r)
        S_IDLE: begin
            if(i_start) begin
                state_w = S_PLAY;
                o_dac_data_w = i_sram_data;
                o_sram_addr_w = o_sram_addr_r;
                prev_data_w = 16'd0;
                counter_w = 4'd0;
            end
            else begin
                state_w = S_IDLE;
                o_dac_data_w = 16'bZ;
                o_sram_addr_w = 20'd0;
                prev_data_w = 16'b0;
                counter_w = 4'd0;
            end
        end
        S_PLAY: begin
            if(i_stop) begin
                state_w = S_IDLE;
                o_dac_data_w = (i_slow_1) ? prev_data_r : 16'bZ ;
                o_sram_addr_w = 20'd0;
                prev_data_w = 16'b0;
                counter_w = 4'd0;
            end
            else if(i_pause) begin
                state_w = S_PAUSE;
                o_dac_data_w = 16'bZ;
            end
            else begin
                if(i_fast) begin
                    o_dac_data_w = i_sram_data;
                    o_sram_addr_w = (prev_daclrck_r && !i_daclrck) ? (o_sram_addr_r + (i_speed + 20'd1)) : o_sram_addr_r;
                    prev_data_w = 16'b0;
                    counter_w = 4'd0;
                end
                else if(i_slow_0) begin
                    o_dac_data_w = i_sram_data;
                    prev_data_w = 16'b0;
                    if(counter_r > i_speed) begin
                        o_sram_addr_w = (prev_daclrck_r && !i_daclrck)? o_sram_addr_r + 20'd1 : o_sram_addr_r;
                        counter_w = (prev_daclrck_r && !i_daclrck)? 4'd1 : counter_r;
                    end
                    else begin
                        o_sram_addr_w = o_sram_addr_r;
                        counter_w = (prev_daclrck_r && !i_daclrck)? (counter_r + 4'd1) : counter_r;
                    end
                end
                else if(i_slow_1) begin
                    o_dac_data_w = (prev_data_r * (1 + $signed(i_speed) - $signed(counter_r)) + $signed(i_sram_data) * $signed(counter_r)) / (1 + $signed(i_speed));
                    if(counter_r > i_speed) begin
                        prev_data_w = (!prev_daclrck_r && i_daclrck)? $signed(i_sram_data) : prev_data_r;
                        o_sram_addr_w = (prev_daclrck_r && !i_daclrck)? o_sram_addr_r + 20'd1 : o_sram_addr_r;
                        counter_w = (prev_daclrck_r && !i_daclrck)? 4'd1 : counter_r;
                    end
                    else begin
                        o_sram_addr_w = o_sram_addr_r;
                        prev_data_w = prev_data_r;
                        counter_w = (prev_daclrck_r && !i_daclrck)? (counter_r + 4'd1) : counter_r;
                    end
                end
                else begin
                    o_dac_data_w = i_sram_data;
                    o_sram_addr_w = (prev_daclrck_r && !i_daclrck)? (o_sram_addr_r + 20'd1) : o_sram_addr_r;
                    prev_data_w = 16'b0;
                    counter_w = 4'd0;
                end
            end
        end
        S_PAUSE: begin
            if(i_start) begin
                state_w = S_PLAY;
                o_dac_data_w = 16'bZ;
            end
            else if(i_stop) begin
                state_w = S_IDLE;
                o_dac_data_w = 16'bZ;
                o_sram_addr_w = 20'd0;
                prev_data_w = 16'b0;
                counter_w = 4'd0;
            end
            else begin
                state_w = S_PAUSE;
                o_dac_data_w = 16'bZ;
            end
        end
    endcase
end

// ===== Sequential Circuits =====
always_ff @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        state_r         <= S_IDLE;
        o_dac_data_r    <= 16'bZ;
        o_sram_addr_r   <= 20'd0;
        prev_data_r     <= 16'b0;
        counter_r       <= 4'd0;
        prev_daclrck_r  <= 1'b0;
    end
    else begin
        state_r         <= state_w;
        o_dac_data_r    <= o_dac_data_w;
        o_sram_addr_r   <= o_sram_addr_w;
        prev_data_r     <= prev_data_w;
        counter_r       <= counter_w;
        prev_daclrck_r  <= prev_daclrck_w;
    end
end

endmodule