module I2cInitializer(
	input i_rst_n,
	input i_clk,
	input i_start,
	output o_finished,
	output o_sclk,
	inout o_sdat,
	output o_oen // you are outputing (you are not outputing only when you are "ack"ing.)
);

// ===== States =====
// State of I2C
localparam S_IDLE   = 2'd0;
localparam S_READY  = 2'd1;
localparam S_PROC   = 2'd2;
localparam S_SETUP  = 2'd3;
// State of SCLK
localparam SCLK_READY   = 2'd0;
localparam SCLK_MOD     = 2'd1;

// ===== Constants =====
localparam [240-1: 0] SETUP_DATA = {
    // ADDR(7bits)+R/W(1bit)+REG_ADDR(7bits)+REG_DATA(9bits)
    24'b00110100_000_0000_0_1001_0111,
    24'b00110100_000_0001_0_1001_0111,
    24'b00110100_000_0010_0_0111_1001,
    24'b00110100_000_0011_0_0111_1001,
    24'b00110100_000_0100_0_0001_0101,
    24'b00110100_000_0101_0_0000_0000,
    24'b00110100_000_0110_0_0000_0000,
    24'b00110100_000_0111_0_0100_0010,
    24'b00110100_000_1000_0_0001_1001,
    24'b00110100_000_1001_0_0000_0001
};

// ===== Registers & Wires =====
logic [1:0] state_r, state_w;
logic state_sclk_r, state_sclk_w;
logic [240-1: 0] data_r, data_w;
logic oen;
logic sdat_r, sdat_w;
logic sclk_r, sclk_w;
logic finish_r, finish_w;
logic [1:0] counter1_r, counter1_w; // 0~3: 3rd means 3 bytes are sent
logic [3:0] counter2_r, counter2_w; // 0~8: 8th cycle send high impedence(oen=1)
logic is_setup_r, is_setup_w;

logic [3:0] counter_test_r, counter_test_w; 

// ===== Output Assignments =====
assign o_finished   = finish_r;
assign o_sclk       = sclk_r;
assign o_sdat       = o_oen ? sdat_r : 1'bz;
assign o_oen        = oen;

// ===== Combinational Circuits =====
always_comb begin
    // Default Values
    state_w         = state_r;
    state_sclk_w    = state_sclk_r;
    data_w          = data_r;
    oen             = 1'b1;
    sdat_w          = sdat_r;
    sclk_w          = sclk_r;
    finish_w        = finish_r;
    counter1_w      = counter1_r;
    counter2_w      = counter2_r;
    is_setup_w      = is_setup_r;
	 
	 counter_test_w = counter_test_r+4'd1;
//	 if(counter_test_r==4'b1111) begin
//		finish_w = 1'b1;
//	 end
	 
    // FSM
	 
    case(state_r)
        S_IDLE: begin
            if(i_start) begin
				state_w = S_READY;
				data_w = SETUP_DATA;
				sclk_w = 1;
				sdat_w = 0;
				state_sclk_w = SCLK_READY;
			end
			finish_w = 1'b0;
			oen = 1'b1;
			counter1_w = 2'b0;
			counter2_w = 4'b0;
        end
        S_READY: begin
            state_w = S_SETUP;
			data_w = data_r << 1;
			sdat_w = data_r[240-1];
			sclk_w = 1'b0;
			state_sclk_w = SCLK_READY;
			finish_w = finish_r;
			oen = 1'b1;
			counter1_w = 2'b0;
			counter2_w = 4'b0;
            is_setup_w = 1'b1;
        end
        S_SETUP: begin
            counter2_w      = 4'b0;
            counter1_w      = 2'b0;
            state_sclk_w    = SCLK_READY;
            oen             = 1'b1;
            finish_w = 1'b0;
            if(is_setup_r) begin
                sdat_w      = 1'b1;
                sclk_w      = 1'b1;
                is_setup_w  = 1'b0;
            end
            else begin
                if(sdat_r==1'b1 && sclk_w==1'b1) begin
                    sdat_w  = 1'b0;
                    sclk_w  = 1'b1;
                end
                else if(sdat_r==1'b0 && sclk_w==1'b1) begin
                    sdat_w  = 1'b0;
                    sclk_w  = 1'b0;
                end
                else begin
                    if(data_r!=240'd0) begin
                        state_w     = S_PROC;
                        sclk_w      = 1'b1;
                    end
                    else begin
                        sdat_w      = 1'b0;
                        sclk_w      = 1'b0;
                        finish_w    = 1'b1;
                    end
                end
            end
        end
        S_PROC: begin
            if(counter1_r<2'd3) begin
				case(state_sclk_r)
					SCLK_READY: begin
                        counter2_w = (counter2_r==4'd8)? 4'b0 : counter2_r + 4'd1;
						counter1_w = (counter2_r==4'd8)? counter1_r+2'd1 : counter1_r;
						sdat_w = data_r[240-1];
						sclk_w          = 1'b0;
                        state_sclk_w    = SCLK_MOD;
                        data_w = (counter2_r==4'd7) ? data_r : data_r<<1;
					end
					SCLK_MOD: begin
						sclk_w = 1'b1;
						state_sclk_w = SCLK_READY;
					end
				endcase
				oen = (counter2_r==4'd8)? 1'b0 : 1'b1;
				finish_w = 1'b0;
			end
			else begin
				counter2_w      = 4'b0;
				counter1_w      = 2'b0;
				sdat_w          = 1'b0;
				sclk_w          = 1'b1;
				state_sclk_w    = SCLK_READY;
				oen             = 1'b1;
				state_w       = S_SETUP;
                is_setup_w      = 1'b1;
				finish_w        = 1'b0;
			end
        end
    endcase
	 
end

// ===== Sequential Circuits =====
always_ff @(posedge i_clk or negedge i_rst_n) begin
    if(~i_rst_n) begin
		state_r         <= S_IDLE;
		data_r          <= SETUP_DATA;
		counter1_r      <= 2'b0;
		counter2_r      <= 4'b0;
		sdat_r          <= 1'b1;
		sclk_r          <= 1'b1;
		state_sclk_r    <= SCLK_READY;
		finish_r        <= 1'b0;
        is_setup_r      <= 1'b0;
		  counter_test_r <= 4'b0;
	end
    else begin
        state_r         <= state_w;
		data_r          <= data_w;
		counter1_r      <= counter1_w;
		counter2_r      <= counter2_w;
		sdat_r          <= sdat_w;
		sclk_r          <= sclk_w;
		state_sclk_r    <= state_sclk_w;
		finish_r        <= finish_w;
        is_setup_r      <= is_setup_w;
		  counter_test_r <= counter_test_w;
	end
end

endmodule