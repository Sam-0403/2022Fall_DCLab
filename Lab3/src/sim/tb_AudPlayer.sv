`timescale 1ns/10ps
`define CYCLE 10.0
`define HCYCLE 5.0

module tb;
    parameter NUM_DATA = 4;
    integer error, num;

    logic clock, stop, check;

    logic rst, daclrck, enable;
    logic [15:0] dac_data;
    logic o_aud_dacdat;

    integer cnt;
    logic [16*NUM_DATA-1:0] DATA = {
        16'b1011_1010_0000_1110,
        16'b0101_1110_0011_1010,
        16'b1110_1010_0001_1001,
        16'b1111_1000_0001_0101
    };

    //clock
    initial begin
        clock = 1'b1;
    end
    always begin #(`HCYCLE) clock = ~clock;
    end

    AudPlayer player(
        .i_rst_n      (rst),
        .i_bclk       (clock),
        .i_daclrck    (daclrck),
        .i_en         (enable),
        .i_dac_data   (dac_data),
        .o_aud_dacdat (o_aud_dacdat)
    );

    //Read file
    initial begin
        error = 0; stop = 1'b0;
        #(`CYCLE * (44 * NUM_DATA + 10)) stop = 1'b1;
    end

    //Test
    initial begin
        rst = 1'b1; check = 1'b0; enable = 1'b0; daclrck = 1'b1; cnt = NUM_DATA
        #(`CYCLE * 2.5) rst = 1'b0;
        #(`CYCLE * 3) rst = 1'b1;

        #(`CYCLE * 2) enable = 1'b1;
        #(`CYCLE * 2) daclrck = 1'b0;
        dac_data = DATA[16*cnt - 1 : 16*(cnt-1)];
        cnt--;
        #(`CYCLE * 1) check = 1'b1;
        #(`CYCLE * 16) check = 1'b0;
        #(`CYCLE * 3) daclrck = 1'b1; 
        #(`CYCLE * 20) enable = 1'b0;

        #(`CYCLE * 2) enable = 1'b1;
        #(`CYCLE * 2) daclrck = 1'b0;
        dac_data = DATA[16*cnt - 1 : 16*(cnt-1)];
        cnt--;
        #(`CYCLE * 1) check = 1'b1;
        #(`CYCLE * 16) check = 1'b0;
        #(`CYCLE * 3) daclrck = 1'b1; 
        #(`CYCLE * 20) enable = 1'b0;

        #(`CYCLE * 2) enable = 1'b1;
        #(`CYCLE * 2) daclrck = 1'b0;
        dac_data = DATA[16*cnt - 1 : 16*(cnt-1)];
        cnt--;
        #(`CYCLE * 1) check = 1'b1;
        #(`CYCLE * 16) check = 1'b0;
        #(`CYCLE * 3) daclrck = 1'b1; 
        #(`CYCLE * 20) enable = 1'b0;

        #(`CYCLE * 2) enable = 1'b1;
        #(`CYCLE * 2) daclrck = 1'b0;
        dac_data = DATA[16*cnt - 1 : 16*(cnt-1)];
        cnt--;
        #(`CYCLE * 1) check = 1'b1;
        #(`CYCLE * 16) check = 1'b0;
        #(`CYCLE * 3) daclrck = 1'b1; 
        #(`CYCLE * 20) enable = 1'b0;
    end

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
        $fsdbDumpfile("AudPlayer.fsdb");
        $fsdbDumpvars;
    end

endmodule