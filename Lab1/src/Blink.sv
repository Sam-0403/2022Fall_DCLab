module Blink (
	input        i_clk,
	input        i_rst_n,
	input        i_state,
	input [3:0]  i_random,
    output [3:0] led_out,
);

// ===== States =====
parameter S_IDLE = 2'b00;
parameter S_PROC = 2'b01;
parameter S_RUNN = 2'b10;

// ===== Constants =====
parameter NUM_PERIOD = 32'b1000_0000_0000;

// ===== Registers & Wires =====

// Regs & Wires for FSM
logic [31:0] counter_r, counter_w;

// ===== Output Buffers =====
logic [3:0] led_out_r, led_out_w;

// ===== Output Assignments =====
assign led_out = led_out_r;

always_comb begin
	// Default Values
	led_out_w = led_out_r;
    counter_w = counter_r;

	// FSM
	case(i_state)
    S_IDLE: begin
        led_out_w = 4'b0;
        counter_w = 32'b0;
    end

    S_PROC: begin
        if(counter_r==NUM_PERIOD) begin
            counter_w = 32'b0;
            led_out_w = !led_out_r;
        end
        else begin
            counter_w = counter_r + 1'b1;
        end
    end

    S_RUNN: begin
        counter_w = 32'b0;
        led_out_w = i_random;
    end
    endcase
end

// ===== Sequential Circuits =====
always_ff @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
		led_out_r   <= led_out_w;
        counter_r   <= 32'b0;
	end
	else begin
		led_out_r   <= led_out_w;
        counter_r   <= counter_w;
	end
end

endmodule