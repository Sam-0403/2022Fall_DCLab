module SevenHexDecoder (
	input        [3:0] i_hex,
	output logic [6:0] o_seven
);

/* The layout of seven segment display, 1: dark
 *    00
 *   5  1
 *    66
 *   4  2
 *    33
 */
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
	case(i_hex)
		4'h0: begin o_seven = D0; end
		4'h1: begin o_seven = D1; end
		4'h2: begin o_seven = D2; end
		4'h3: begin o_seven = D3; end
		4'h4: begin o_seven = D4; end
		4'h5: begin o_seven = D5; end
		4'h6: begin o_seven = D6; end
		4'h7: begin o_seven = D7; end
		4'h8: begin o_seven = D8; end
		4'h9: begin o_seven = D9; end
		default: begin o_seven = D0; end
	endcase
end

endmodule
