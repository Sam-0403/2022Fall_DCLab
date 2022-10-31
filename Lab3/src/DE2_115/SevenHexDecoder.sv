module SevenHexDecoder (
	input i_clk,
	input i_rst_n,
	input        [5:0] i_hex,
	output logic [6:0] o_seven_ten,
	output logic [6:0] o_seven_one
);

/* The layout of seven segment display, 1: dark
 *    00
 *   5  1
 *    66
 *   4  2
 *    33
 */
 
logic [3:0] counter_hex_w, counter_hex_r;
logic [13:0] dec_hex_w, dec_hex_r; 
logic [6:0] o_seven_ten_r, o_seven_ten_w;
logic [6:0] o_seven_one_r, o_seven_one_w;
 
parameter D0 = 7'b1000000;
parameter D1 = 7'b1111001;
parameter D2 = 7'b0100100;
parameter D3 = 7'b0110000;
parameter D4 = 7'b0011001;
parameter D5 = 7'b0010010;
parameter D6 = 7'b0000010;
parameter D7 = 7'b1011000;
parameter D8 = 7'b0000000;
parameter D9 = 7'b0010000;

always_comb begin
	counter_hex_w = counter_hex_r;
	dec_hex_w = dec_hex_r;
	
	o_seven_ten_w = o_seven_ten_r;
	o_seven_one_w = o_seven_one_r;
	
	o_seven_ten = o_seven_ten_r;
	o_seven_one = o_seven_one_r;
	
	if(counter_hex_r<=4'd6) begin
		if(counter_hex_r==4'd1) begin
			dec_hex_w = {8'b0, i_hex};
		end
		else begin
			dec_hex_w[13:10] = (dec_hex_r[12:9]>=4'b0101 && counter_hex_r!=4'd6) ? dec_hex_r[12:9]+4'b0011 : dec_hex_r[12:9];
			dec_hex_w[9:6] = (dec_hex_r[8:5]>=4'b0101 && counter_hex_r!=4'd6) ? dec_hex_r[8:5]+4'b0011 : dec_hex_r[8:5];
			dec_hex_w[5:0] = {dec_hex_r[4:0], 1'b0};
		end
		counter_hex_w = counter_hex_r + 4'd1;
	end
	else begin
		case(dec_hex_r[13:10])
			4'h0: begin o_seven_ten_w = D0; end
			4'h1: begin o_seven_ten_w = D1; end
			4'h2: begin o_seven_ten_w = D2; end
			4'h3: begin o_seven_ten_w = D3; end
			4'h4: begin o_seven_ten_w = D4; end
			4'h5: begin o_seven_ten_w = D5; end
			4'h6: begin o_seven_ten_w = D6; end
			4'h7: begin o_seven_ten_w = D7; end
			4'h8: begin o_seven_ten_w = D8; end
			4'h9: begin o_seven_ten_w = D9; end
			default: begin o_seven_ten_w = D0; end
		endcase
		case(dec_hex_r[9:6])
			4'h0: begin o_seven_one_w = D0; end
			4'h1: begin o_seven_one_w = D1; end
			4'h2: begin o_seven_one_w = D2; end
			4'h3: begin o_seven_one_w = D3; end
			4'h4: begin o_seven_one_w = D4; end
			4'h5: begin o_seven_one_w = D5; end
			4'h6: begin o_seven_one_w = D6; end
			4'h7: begin o_seven_one_w = D7; end
			4'h8: begin o_seven_one_w = D8; end
			4'h9: begin o_seven_one_w = D9; end
			default: begin o_seven_one_w = D0; end
		endcase
		counter_hex_w = 4'b0;
	end
end

always_ff @(posedge i_clk or negedge i_rst_n) begin
	if(!i_rst_n) begin
		counter_hex_r <= 4'b0;
		dec_hex_r <= 14'b0;
		o_seven_ten_r <= D0;
		o_seven_one_r <= D0;
	end
	else begin
		counter_hex_r <= counter_hex_w;
		dec_hex_r <= dec_hex_w;
		o_seven_ten_r <= o_seven_ten_w;
		o_seven_one_r <= o_seven_one_w;
	end
end

endmodule
