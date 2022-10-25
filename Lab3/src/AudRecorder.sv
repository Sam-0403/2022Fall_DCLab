module AudRecorder(
	input i_rst_n, 
	input i_clk,
	input i_lrc,
	input i_start,
	input i_pause,
	input i_stop,
	input i_data,
	output [19:0] o_address,
	output [15:0] o_data
);

// ===== States =====
localparam S_IDLE   = 2'd0;
localparam S_WAIT   = 2'd1;
localparam S_DATA   = 2'd2;
localparam S_PAUSE  = 2'd3;

// ===== Constants =====
localparam BASE = 20'b11111111111111111111; // BASE0 = -1

// ===== Registers & Wires =====
logic [1:0] state_r, state_w;
logic [4:0] counter_r, counter_w;   // bit counter for 16 bit audio
logic [19:0] addr_r, addr_w;
logic [15:0] data_r, data_w;

// ===== Output Assignments =====
assign o_address    = addr_r;
assign o_data       = data_r;

// ===== Combinational Circuits =====
always_comb begin
    // Default Values
    state_w     = state_r;
    counter_w   = counter_r;
    addr_w      = addr_r;
    data_w      = data_r;
    // FSM
    case(state_r)
        S_IDLE: begin
            if(i_start) begin
                state_w = S_WAIT;
                addr_w  = BASE;
            end
            counter_w   = 5'd0;
			data_w      = 16'd0;
        end
        S_WAIT: begin
            if(i_stop) begin
                state_w = S_IDLE;
            end
            else if(i_pause) begin
                state_w = S_PAUSE;
            end
            else if(i_lrc) begin //record right channel
                state_w = S_DATA;
            end
            counter_w   = 5'd0;
            data_w      = 16'd0;
        end
        S_DATA: begin
            if(i_stop) begin
                state_w     = S_IDLE;
                counter_w   = 5'd0;
                addr_w      = addr_r;
                data_w      = 16'd0;
            end
            else if(i_pause) begin
                state_w     = S_PAUSE;
                counter_w   = 5'd0;
                addr_w      = addr_r;
                data_w      = 16'd0;
            end
            else if(counter_r<5'd16) begin //record right channel
                state_w     = S_DATA;
                counter_w   = counter_r + 5'd1;
                addr_w      = addr_r;
                data_w      = {data_r[15:0],i_data};
            end
            else if(!i_lrc) begin
                state_w     = S_WAIT;
                counter_w   = 5'd0;
                addr_w      = addr_r + 20'd1; //only change o_address when output(i_lrc=1=right channel)
                data_w      = data_r;
            end
        end
        S_PAUSE: begin
            if(i_start) begin
                state_w = S_WAIT;
            end
            counter_w   = 5'd0;
            data_w      = 16'd0;
        end
    endcase
end

// ===== Sequential Circuits =====
always_ff @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        state_r     <= S_IDLE;
        counter_r   <= 5'd0;
        addr_r      <= BASE;
        data_r      <= 16'd0;
    end
    else begin
        state_r     <= state_w;
        counter_r   <= counter_w;
        addr_r      <= addr_w;
        data_r      <= data_w;
    end
end

endmodule