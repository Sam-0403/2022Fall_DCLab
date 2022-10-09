module Rsa256Wrapper (
    input         avm_rst,
    input         avm_clk,
    output  [4:0] avm_address,
    output        avm_read,
    input  [31:0] avm_readdata,
    output        avm_write,
    output [31:0] avm_writedata,
    input         avm_waitrequest
);

localparam RX_BASE     = 0*4;
localparam TX_BASE     = 1*4;
localparam STATUS_BASE = 2*4;
localparam TX_OK_BIT   = 6;
localparam RX_OK_BIT   = 7;

// Feel free to design your own FSM!
localparam S_GET_KEY = 0;
localparam S_GET_DATA = 1;
localparam S_WAIT_CALCULATE = 2;
localparam S_SEND_DATA = 3;

logic [255:0] n_r, n_w, d_r, d_w, enc_r, enc_w, dec_r, dec_w;
logic [1:0] state_r, state_w;
logic [6:0] bytes_counter_r, bytes_counter_w;   // 0 ~ 127
logic [4:0] avm_address_r, avm_address_w;
logic avm_read_r, avm_read_w, avm_write_r, avm_write_w;

// check if the data has reached the end
logic data_finished_r, data_finished_w;
// decide to reset or not
logic rst_r, rst_w;

logic rsa_start_r, rsa_start_w;
logic rsa_finished;
logic [255:0] rsa_dec;

assign avm_address = avm_address_r;
assign avm_read = avm_read_r;
assign avm_write = avm_write_r;
assign avm_writedata = dec_r[247-:8];

Rsa256Core rsa256_core(
    .i_clk(avm_clk),
    .i_rst(rst_r),
    .i_start(rsa_start_r),
    .i_a(enc_r),
    .i_d(d_r),
    .i_n(n_r),
    .o_a_pow_d(rsa_dec),
    .o_finished(rsa_finished)
);

task StartRead;
    input [4:0] addr;
    begin
        avm_read_w = 1;
        avm_write_w = 0;
        avm_address_w = addr;
    end
endtask
task StartWrite;
    input [4:0] addr;
    begin
        avm_read_w = 0;
        avm_write_w = 1;
        avm_address_w = addr;
    end
endtask

always_comb begin
    // TODO
    avm_read_w = avm_read_r;
    avm_write_w = avm_write_r;
    avm_address_w = avm_address_r;
    // Default
    n_w             = n_r;
    d_w             = d_r;
    enc_w           = enc_r;
    dec_w           = dec_r;
    state_w         = state_r;
    bytes_counter_w = bytes_counter_r;
    rsa_start_w     = rsa_start_r;
	data_finished_w = data_finished_r;
	rst_w = data_finished_r | avm_rst;
    // FSM
    case(state_r)
        S_GET_KEY: begin
            dec_w       = 256'd0;
            if(~avm_waitrequest & avm_readdata[RX_OK_BIT]) begin
                StartRead(RX_BASE);
                bytes_counter_w = bytes_counter_r + 1;
                state_w         = S_GET_DATA;
            end
        end
        S_GET_DATA: begin
            if(~avm_waitrequest) begin
                StartRead(STATUS_BASE);
                // n: 0 ~ 31 bytes
                if(bytes_counter_r<=7'd32) begin
                    n_w     = (n_r<<8) + avm_readdata[7:0];
                    state_w = S_GET_KEY;
                end
                // d: 32 ~ 63 bytes
                else if(bytes_counter_r<=7'd64) begin
                    d_w     = (d_r<<8) + avm_readdata[7:0];
                    state_w = S_GET_KEY;
                end
                // enc: 64 ~ 95 bytes
                else if(bytes_counter_r<7'd96) begin
                    enc_w   = (enc_r<<8) + avm_readdata[7:0];
                    state_w = S_GET_KEY;
                end
                else begin
                    enc_w   = (enc_r<<8) + avm_readdata[7:0];

					// check if the data is the finish signal
					if(enc_w == n_w) begin
						state_w     = S_GET_KEY;
                        enc_w       = 256'd0;
						bytes_counter_w = 7'd0;
						data_finished_w = 1'b1;
					end
					else begin
						state_w     = S_WAIT_CALCULATE;
                    	rsa_start_w = 1'd1;
					end
                    
                end
            end
        end
        S_WAIT_CALCULATE: begin
            rsa_start_w     = 1'd0;
            bytes_counter_w = 7'd0;
            if(rsa_finished) begin
                StartRead(STATUS_BASE);
                state_w = S_SEND_DATA;
                dec_w = rsa_dec;
            end
        end
        S_SEND_DATA: begin
            if(avm_address == STATUS_BASE) begin
                if(~avm_waitrequest & avm_readdata[TX_OK_BIT]) begin
                    StartWrite(TX_BASE);
                    bytes_counter_w = bytes_counter_r + 7'd1;
                end
            end
            else begin
                // dec: 0 ~ 30
            	if(bytes_counter_r<7'd31) begin
            		if(~avm_waitrequest) begin
	                    StartRead(STATUS_BASE);
	                    dec_w = dec_r << 8;  
                	end
                end
                else begin
                    if(~avm_waitrequest) begin
	                    StartRead(STATUS_BASE);
	                    dec_w = dec_r << 8;
                        enc_w = 256'd0;
                        state_w = S_GET_KEY;
                        // Get enc data
                        bytes_counter_w = 7'd64;
                	end
                end
            end
        end
    endcase
end

always_ff @(posedge avm_clk or posedge rst) begin
    if (rst) begin
        n_r <= 0;
        d_r <= 0;
        enc_r <= 0;
        dec_r <= 0;
        avm_address_r <= STATUS_BASE;
        avm_read_r <= 1;
        avm_write_r <= 0;
        state_r <= S_GET_KEY;
        bytes_counter_r <= 0;
        rsa_start_r <= 0;
		data_finished_r <= 0;
    end
	else begin
        n_r <= n_w;
        d_r <= d_w;
        enc_r <= enc_w;
        dec_r <= dec_w;
        avm_address_r <= avm_address_w;
        avm_read_r <= avm_read_w;
        avm_write_r <= avm_write_w;
        state_r <= state_w;
        bytes_counter_r <= bytes_counter_w;
        rsa_start_r <= rsa_start_w;
		data_finished_r <= data_finished_w;
		rst_r <= rst_w;
    end
end

endmodule
