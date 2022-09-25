`timescale 1us/1us

module Top_test;

parameter	cycle = 100.0;

logic 		i_clk;
logic 		i_rst_n, i_start;
logic 		i_control;
logic 		i_index_0, i_index_1, i_index_2, i_index_3;
logic [3:0] o_random_out;
logic [3:0] o_stored_out;

initial i_clk = 0;
always #(cycle/2.0) i_clk = ~i_clk;

Top top0(
	.i_clk(i_clk),
	.i_rst_n(i_rst_n),
	.i_start(i_start),
	.i_control(i_control),
	.i_index_0(i_index_0),
	.i_index_1(i_index_1),
	.i_index_2(i_index_2),
	.i_index_3(i_index_3),
	.o_random_out(o_random_out),
	.o_stored_out(o_stored_out)
);

initial begin
	$fsdbDumpfile("Lab1_test.fsdb");
	$fsdbDumpvars(0, Top_test, "+all");
end

initial begin	
	i_clk 	= 0;
	i_rst_n = 1;
	i_start	= 0;

	i_control = 0;
	i_index_0 = 1;
	i_index_1 = 0;
	i_index_2 = 0;
	i_index_3 = 0;

	@(negedge i_clk);
	@(negedge i_clk);
	@(negedge i_clk) i_rst_n = 0;
	@(negedge i_clk) i_rst_n = 1; 


	@(negedge i_clk);
	@(negedge i_clk);
	@(negedge i_clk);
	@(negedge i_clk) i_start = 1;
	@(negedge i_clk);
	@(negedge i_clk) i_start = 0;
	#20000
	@(negedge i_clk) i_start = 1;
	@(negedge i_clk);
	@(negedge i_clk) i_start = 0;
	#800000000
	@(negedge i_clk) i_control = 1;
	@(negedge i_clk);
	@(negedge i_clk) i_control = 0;
end

initial #(cycle*10000000) $finish;

endmodule
