`timescale 1ns/10ps
`define CYCLE 10.0
`define HCYCLE 5.0

module tb;
    // Variable
    logic error, stop;
    logic rst_n, clk;
    wire sclk, sdat;    // wire for inout
    logic oen;
    logic finished;
    logic start;

    // Initial a clock
    initial begin
        clk = 1'b1;
    end
    always begin #(`HCYCLE) clk = ~clk;
    end

    I2cInitializer i2c(
        .i_rst_n(rst_n),
        .i_clk(clk),
        .i_start(start),
        .o_finished(finished),
        .o_sclk(sclk),
        .o_sdat(sdat),
        .o_oen(oen)
    );

    // Read file
    initial begin
        error = 0;
        stop  = 1'b0;
        #(`CYCLE * 2000) stop = 1'b1;
    end

    // Test
    initial begin
        rst_n = 1'b1;
        start = 1'b0;
        #(`CYCLE * 2.5)
        rst_n = 1'b0;
        #(`CYCLE * 3)
        rst_n = 1'b1;

        #(`CYCLE * 10)
        start = 1'b1;
    end

    // Finish
    initial begin
        @(posedge stop) begin
            if(error == 0) begin
                $display("==========================================\n");
				$display("======  Congratulation! You Pass!  =======\n");
				$display("==========================================\n");
            end
            else begin
                $display("===============================\n");
				$display("There are %d errors.", error);
				$display("===============================\n");
            end
            $finish;
        end
    end

    //Dumping waveform files
    initial begin
        $fsdbDumpfile("I2C.fsdb");
        $fsdbDumpvars;
    end

endmodule