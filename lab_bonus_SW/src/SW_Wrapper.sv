
`define REF_MAX_LENGTH              128
`define READ_MAX_LENGTH             128

`define REF_LENGTH                  128
`define READ_LENGTH                 128

//* Score parameters
`define DP_SW_SCORE_BITWIDTH        10

`define CONST_MATCH_SCORE           1
`define CONST_MISMATCH_SCORE        -4
`define CONST_GAP_OPEN              -6
`define CONST_GAP_EXTEND            -1

`define CONST_OUT_LENGTH            31
`define CONST_OUT_COLUMN_LENGTH     64-$clog2(`REF_MAX_LENGTH)
`define CONST_OUT_ROW_LENGTH        64-$clog2(`READ_MAX_LENGTH)


module SW_Wrapper (
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

logic [2*`REF_MAX_LENGTH-1:0] sequence_ref_r, sequence_ref_w;
logic [2*`READ_MAX_LENGTH-1:0] sequence_read_r, sequence_read_w;

logic [$clog2(`REF_MAX_LENGTH):0] seq_ref_length_r, seq_ref_length_w;
logic [$clog2(`READ_MAX_LENGTH):0] seq_read_length_r, seq_read_length_w;

logic [1:0] state_r, state_w;
logic [6:0] bytes_counter_r, bytes_counter_w;   // 0 ~ 127

logic [4:0] avm_address_r, avm_address_w;
logic avm_read_r, avm_read_w, avm_write_r, avm_write_w;

reg signed [`DP_SW_SCORE_BITWIDTH-1:0]              highest_score_r, highest_score_w;
reg signed [`DP_SW_SCORE_BITWIDTH-1:0]              sw_highest_score;

reg [$clog2(`REF_MAX_LENGTH)-1:0]                   column_r, column_w;
reg [$clog2(`REF_MAX_LENGTH)-1:0]                   sw_column;

reg [$clog2(`READ_MAX_LENGTH)-1:0]                  row_r, row_w;
reg [$clog2(`READ_MAX_LENGTH)-1:0]                  sw_row;

reg [`CONST_OUT_LENGTH*8-1:0] writedata_r, writedata_w;

logic wrapper_valid_r, wrapper_valid_w;
logic sw_ready_r, sw_ready_w;

logic wrapper_ready_r, wrapper_ready_w;
logic sw_valid_r, sw_valid_w;

assign avm_address = avm_address_r;
assign avm_read = avm_read_r;
assign avm_write = avm_write_r;
assign avm_writedata = writedata_r[(`CONST_OUT_LENGTH*8-1)-:8];
// assign avm_writedata = writedata_r[7:0];


// Remember to complete the port connection
SW_core sw_core(
    .clk				(avm_clk),
    .rst				(avm_rst),

	.o_ready			(sw_ready_w),
    .i_valid			(wrapper_valid_r),
    .i_sequence_ref		(sequence_ref_r),
    .i_sequence_read	(sequence_read_r),
    .i_seq_ref_length	(seq_ref_length_r),
    .i_seq_read_length	(seq_read_length_r),
    
    .i_ready			(wrapper_ready_r),
    .o_valid			(sw_valid_w),
    .o_alignment_score	(sw_highest_score),
    .o_column			(sw_column),
    .o_row				(sw_row)
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

// TODO
always_comb begin
    sequence_ref_w = sequence_ref_r;
    sequence_read_w = sequence_read_r;

    seq_ref_length_w = seq_ref_length_r;
    seq_read_length_w = seq_read_length_r;

    state_w = state_r;
    bytes_counter_w = bytes_counter_r;

    avm_address_w = avm_address_r;
    avm_read_w = avm_read_r;
    avm_write_w = avm_write_r;

    highest_score_w = highest_score_r;
    column_w = column_r;
    row_w = row_r;
    writedata_w = writedata_r;

    wrapper_valid_w = wrapper_valid_r;

    wrapper_ready_w = wrapper_ready_r;

    // FSM
    case(state_r)
        S_GET_KEY: begin
            if(~avm_waitrequest & avm_readdata[RX_OK_BIT]) begin
                StartRead(RX_BASE);
                bytes_counter_w = bytes_counter_r + 1;
                state_w         = S_GET_DATA;
            end
        end
        S_GET_DATA: begin
            if(~avm_waitrequest) begin
                StartRead(STATUS_BASE);
                // n: 1 ~ 32 bytes
                if(bytes_counter_r<=7'd32) begin
                    sequence_ref_w = (sequence_ref_r<<8) + avm_readdata[7:0];
                    state_w = S_GET_KEY;
                end
                // d: 33 ~ 64 bytes
                else if(bytes_counter_r<7'd64) begin
                    sequence_read_w     = (sequence_read_r<<8) + avm_readdata[7:0];
                    state_w = S_GET_KEY;
                end
                else begin
                    sequence_read_w   = (sequence_read_r<<8) + avm_readdata[7:0];
                    
                    seq_ref_length_w = `REF_LENGTH;
                    seq_read_length_w = `READ_LENGTH;

                    if(sw_ready_r) begin
                        wrapper_valid_w = 1'd1;
                        bytes_counter_w = 7'd0; 
                        state_w     = S_WAIT_CALCULATE;
                        
                        wrapper_ready_w = 1'd1;
                    end
                end
            end
        end
        S_WAIT_CALCULATE: begin
            bytes_counter_w = 7'd0;
            if(sw_valid_w) begin
                wrapper_valid_w = 1'd0;
                StartRead(STATUS_BASE);
                state_w = S_SEND_DATA;
                highest_score_w = sw_highest_score;
                column_w = sw_column;
                row_w = sw_row;
                writedata_w[247:192] = 56'd0;
                writedata_w[191:128] = sw_column;
                writedata_w[127:64] = sw_row;
                writedata_w[63:0] = sw_highest_score;
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
                // NULL: 0 ~ 6
            	if(bytes_counter_r<=7'd7) begin
            		if(~avm_waitrequest) begin
	                    StartRead(STATUS_BASE);
                        writedata_w = writedata_r << 8;
                	end
                end
                // Column: 7 ~ 14
                else if(bytes_counter_r<=7'd15) begin
            		if(~avm_waitrequest) begin
	                    StartRead(STATUS_BASE);
	                    // column_w = column_r << 8;  
                        writedata_w = writedata_r << 8;
                	end
                end
                // Row: 15 ~ 22
                else if(bytes_counter_r<=7'd23) begin
            		if(~avm_waitrequest) begin
	                    StartRead(STATUS_BASE);
	                    // row_w = row_r << 8;  
                        writedata_w = writedata_r << 8;
                	end
                end
                // Score: 23 ~ 29(30 is the last)
                else if(bytes_counter_r<=7'd30) begin
            		if(~avm_waitrequest) begin
	                    StartRead(STATUS_BASE);
	                    // highest_score_w = highest_score_r << 8; 
                        writedata_w = writedata_r << 8; 
                	end
                end
                else begin
                    if(~avm_waitrequest) begin
	                    StartRead(STATUS_BASE);
	                    // highest_score_w = highest_score_r << 8;
                        writedata_w = writedata_r << 8;
                        highest_score_w = 0;
                        column_w = 0;
                        row_w = 0;
                        state_w = S_GET_KEY;
                        bytes_counter_w = 7'd0;
                	end
                end
            end
        end
    endcase
end

// TODO
always_ff @(posedge avm_clk or posedge avm_rst) begin
    if (avm_rst) begin
    	sequence_ref_r <= 0;
        sequence_read_r <= 0;

        seq_ref_length_r <= 0;
        seq_read_length_r <= 0;

        state_r <= S_GET_KEY;
        bytes_counter_r <= 0;

        avm_address_r <= STATUS_BASE;
        avm_read_r <= 1;
        avm_write_r <= 0;

        highest_score_r <= 0;
        column_r <= 0;
        row_r <= 0;
        writedata_r <= 0;

        wrapper_valid_r <= 0;
        sw_ready_r <= 0;

        wrapper_ready_r <= 0;
        sw_valid_r <= 0;
    end
	else begin
    	sequence_ref_r <= sequence_ref_w;
        sequence_read_r <= sequence_read_w;

        seq_ref_length_r <= seq_ref_length_w;
        seq_read_length_r <= seq_read_length_w;

        state_r <= state_w;
        bytes_counter_r <= bytes_counter_w;

        avm_address_r <= avm_address_w;
        avm_read_r <= avm_read_w;
        avm_write_r <= avm_write_w;

        highest_score_r <= highest_score_w;
        column_r <= column_w;
        row_r <= row_w;
        writedata_r <= writedata_w;

        wrapper_valid_r <= wrapper_valid_w;
        sw_ready_r <= sw_ready_w;

        wrapper_ready_r <= wrapper_ready_w;
        sw_valid_r <= sw_valid_w;
    end
end

endmodule
