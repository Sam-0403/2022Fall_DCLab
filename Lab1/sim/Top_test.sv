`timescale 1us/1us
`define FAST_SIM
`include "LAB1_include.sv"

module Top_test;

logic i_clk;
`Pos(ck_ev, i_clk)
`WithFinish
logic [5:0] rand;

always #50 i_clk = ~i_clk;
initial begin
	$fsdbDumpfile("Lab1_test.fsdb");
	$fsdbDumpvars(0, Top_test, "+mda");
	i_clk = 0;
	rand = $urandom%32;
	#rand;
	i_start = 1;
	#1;
	i_start = 0;
	#1 $NicotbInit();
	#120000000;
	$NicotbFinal();
	$finish;
end

DE2_115 dut(.CLOCK_50(i_clk));

endmodule
