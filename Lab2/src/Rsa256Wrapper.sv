module Rsa256Wrapper (
    input         avm_rst,
    input         avm_clk,
    output  [4:0] avm_address,
    output        avm_read,
    input  [31:0] avm_readdata,
    output        avm_write,
    output [31:0] avm_writedata,
    input         avm_waitrequest,
	 output [11:0] dec_file_out,
	 output [23:0] dec_content_out,
	 input         i_type
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

// Check if the data has reached the end
logic data_finished_r, data_finished_w;
// Decide to reset or not
logic rst_r, rst_w;

logic rsa_start_r, rsa_start_w;
logic rsa_finished;
logic [255:0] rsa_dec;

// Add our own reg and wire

// Switch Encryption
logic rail_start_r, rail_start_w;
logic rail_finished;
logic [255:0] rail_dec;

// LCD Display
logic [9:0] file_counter_r, file_counter_w;        // At most 999 files
logic [19:0] content_counter_r, content_counter_w;  // each file can be at most 999,999 bytes(~1MB)

logic [21:0] dec_file_r, dec_file_w;    // 0 ~ 999  (12bit+10bit)
logic [3:0] cntr_file_r, cntr_file_w;   // count for 10 times
logic rst_file_r, rst_file_w;

logic [43:0] dec_content_r, dec_content_w;  // 0 ~ 999,999  (24bit+20bit)
logic [4:0] cntr_content_r, cntr_content_w; // count for 20 times
logic rst_content_r, rst_content_w;

assign avm_address = avm_address_r;
assign avm_read = avm_read_r;
assign avm_write = avm_write_r;
assign avm_writedata = dec_r[247-:8];
assign dec_file_out = dec_file_r[21:10];
assign dec_content_out = dec_content_r[43:20];

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

RailFenceCore rail_fence_core(
	.i_clk(avm_clk),
	.i_rst(rst_r),
	.i_start(rail_start_r),
	.i_enc(enc_r),
	.o_dec(rail_dec),
	.o_finished(rail_finished)
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
	 // Switch Encryption
	 rail_start_w    = rail_start_r;
    // Decimal display
    content_counter_w   = content_counter_r;
    file_counter_w      = file_counter_r;
    rst_file_w      = rst_file_r;
    rst_content_w   = rst_content_r;
	 dec_file_w = dec_file_r;
	 dec_content_w = dec_content_r;
	 cntr_file_w = cntr_file_r;
	 cntr_content_w = cntr_content_r;

    // FSM
    case(state_r)
        S_GET_KEY: begin
            dec_w       = 256'd0;
            if(~avm_waitrequest & avm_readdata[RX_OK_BIT]) begin
                StartRead(RX_BASE);
                bytes_counter_w = bytes_counter_r + 1;
                state_w         = S_GET_DATA;
//					 file_counter_w   = file_counter_r + 1;
//                rst_file_w       = 1'b1;
            end
        end
        S_GET_DATA: begin
            if(~avm_waitrequest) begin
                StartRead(STATUS_BASE);
                // n: 1 ~ 32 bytes
                if(bytes_counter_r<=7'd32) begin
                    n_w     = (n_r<<8) + avm_readdata[7:0];
                    state_w = S_GET_KEY;
                    content_counter_w   = 20'd0;
                    rst_content_w       = 1'b1;
                    if(bytes_counter_r==7'd1) begin
                        file_counter_w  = file_counter_r + 10'd1;
								rst_file_w      = 1'b1;
                    end
                end
                // d: 33 ~ 64 bytes
                else if(bytes_counter_r<=7'd64) begin
                    d_w     = (d_r<<8) + avm_readdata[7:0];
                    state_w = S_GET_KEY;
                end
                // enc: 65 ~ 96 bytes
                else if(bytes_counter_r<7'd96) begin
                    enc_w   = (enc_r<<8) + avm_readdata[7:0];
                    state_w = S_GET_KEY;
                end
                else begin
                    enc_w   = (enc_r<<8) + avm_readdata[7:0];

							// check if the data is the finish signal
							if(enc_w == n_w || enc_w == d_w) begin
								state_w     = S_GET_KEY;
										enc_w       = 256'd0;
								bytes_counter_w = 7'd0;
								data_finished_w = 1'b1;
								
							end
							else begin
								state_w     = S_WAIT_CALCULATE;
								if(i_type) begin
									rail_start_w = 1'd1;
								end
								else begin
									rsa_start_w = 1'd1;
								end
							end
                    
                end
            end
        end
        S_WAIT_CALCULATE: begin
				if(i_type) begin
					rail_start_w     = 1'd0;
				end
				else begin
					rsa_start_w     = 1'd0;
				end
            bytes_counter_w = 7'd0;
				if(i_type) begin
					if(rail_finished) begin
						 StartRead(STATUS_BASE);
						 state_w = S_SEND_DATA;
						 dec_w = rail_dec;
					end
				end
				else begin
					if(rsa_finished) begin
						 StartRead(STATUS_BASE);
						 state_w = S_SEND_DATA;
						 dec_w = rsa_dec;
					end
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
                        content_counter_w   = content_counter_r + 20'd31;
                        rst_content_w       = 1'b1;
								
                	end
                end
            end
        end
    endcase
    if(rst_file_r) begin
        if(cntr_file_r<=4'd10) begin
            if(cntr_file_r==4'd0) begin
                dec_file_w   = {12'd0, file_counter_r};
                cntr_file_w  = cntr_file_r + 4'd1;
            end
            else begin
                cntr_file_w = cntr_file_r + 4'd1;
                dec_file_w[21:18] = (dec_file_r[20:17]>=4'b0101&&cntr_file_r!=4'd10) ? dec_file_r[20:17]+4'b0011 : dec_file_r[20:17];
                dec_file_w[17:14] = (dec_file_r[16:13]>=4'b0101&&cntr_file_r!=4'd10) ? dec_file_r[16:13]+4'b0011 : dec_file_r[16:13];
                dec_file_w[13:10] = (dec_file_r[12:9]>=4'b0101&&cntr_file_r!=4'd10) ? dec_file_r[12:9]+4'b0011 : dec_file_r[12:9];
					 dec_file_w[9:0] = {dec_file_r[8:0], 1'b0};
            end
        end
        else begin
            cntr_file_w = 4'd0;
            rst_file_w  = 1'b0;
        end
    end
    if(rst_content_r) begin
        if(cntr_content_r<=5'd20) begin
            if(cntr_content_r==5'd0) begin
                dec_content_w   = {24'd0, content_counter_r};
                cntr_content_w  = cntr_content_r + 5'd1;
            end
            else begin
                cntr_content_w  = cntr_content_r + 5'd1;
                dec_content_w[43:40] = (dec_content_r[42:39]>=4'b0101&&cntr_content_r!=5'd20) ? dec_content_r[42:39]+4'b0011 : dec_content_r[42:39];
					 dec_content_w[39:36] = (dec_content_r[38:35]>=4'b0101&&cntr_content_r!=5'd20) ? dec_content_r[38:35]+4'b0011 : dec_content_r[38:35];
					 dec_content_w[35:32] = (dec_content_r[34:31]>=4'b0101&&cntr_content_r!=5'd20) ? dec_content_r[34:31]+4'b0011 : dec_content_r[34:31];
					 dec_content_w[31:28] = (dec_content_r[30:27]>=4'b0101&&cntr_content_r!=5'd20) ? dec_content_r[30:27]+4'b0011 : dec_content_r[30:27];
					 dec_content_w[27:24] = (dec_content_r[26:23]>=4'b0101&&cntr_content_r!=5'd20) ? dec_content_r[26:23]+4'b0011 : dec_content_r[26:23];
					 dec_content_w[23:20] = (dec_content_r[22:19]>=4'b0101&&cntr_content_r!=5'd20) ? dec_content_r[22:19]+4'b0011 : dec_content_r[22:19];
					 dec_content_w[19:0] = {dec_content_r[18:0], 1'b0};
            end
        end
        else begin
            cntr_content_w = 5'd0;
            rst_content_w  = 1'b0;
        end
    end
end

always_ff @(posedge avm_clk or posedge rst_w) begin
    if (rst_w) begin
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
		  rail_start_r <= 0;
		data_finished_r <= 0;
        // Dec display
		  if(avm_rst) begin
		  file_counter_r      <= 10'd0;
        content_counter_r   <= 20'd0;
        dec_file_r      <= 22'd0;
        cntr_file_r     <= 4'd0;
        rst_file_r      <= 1'd1;
        dec_content_r   <= 44'd0;
        cntr_content_r  <= 5'd0;
        rst_content_r   <= 1'd1;
		  end
		  else begin
		  file_counter_r      <= file_counter_w;
        content_counter_r   <= content_counter_w;
        dec_file_r      <= dec_file_w;
        cntr_file_r     <= cntr_file_w;
        rst_file_r      <= rst_file_w;
        dec_content_r   <= dec_content_w;
        cntr_content_r  <= cntr_content_w;
        rst_content_r   <= rst_content_w;
		  end
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
		  rail_start_r <= rail_start_w;
		data_finished_r <= data_finished_w;
		rst_r <= rst_w;
        // Dec display
        file_counter_r      <= file_counter_w;
        content_counter_r   <= content_counter_w;
        dec_file_r      <= dec_file_w;
        cntr_file_r     <= cntr_file_w;
        rst_file_r      <= rst_file_w;
        dec_content_r   <= dec_content_w;
        cntr_content_r  <= cntr_content_w;
        rst_content_r   <= rst_content_w;
    end
end

endmodule
