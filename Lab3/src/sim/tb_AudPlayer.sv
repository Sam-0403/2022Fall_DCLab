`timescale 1ns/10ps
`define CYCLE 10.0
`define HCYCLE 5.0

module tb;
    logic [15:0] data_base1;
    logic        data_base2;
    logic clock, stop, check;
    integer error, num, i;
    parameter pattern_num = 4;

    logic rst, daclrck, enable;
    logic [15:0] dac_data;
    logic o_aud_dacdat;

    integer cnt1, cnt2;
    logic [63:0] DATA = {
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

    //DUT
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
        error = 0; stop = 1'b0; i = 1;
        #(`CYCLE * (44 * pattern_num + 10)) stop = 1'b1;
    end

    //Test
    initial begin
        rst = 1'b1; check = 1'b0; enable = 1'b0; daclrck = 1'b1;
        #(`CYCLE * 2.5) rst = 1'b0;
        #(`CYCLE * 3) rst = 1'b1;

        #(`CYCLE * 2) enable = 1'b1;
        #(`CYCLE * 2) daclrck = 1'b0;
        dac_data = DATA[63:48];
        #(`CYCLE * 1) check = 1'b1;
        #(`CYCLE * 16) check = 1'b0;
        #(`CYCLE * 3) daclrck = 1'b1; 
        #(`CYCLE * 20) enable = 1'b0;

        #(`CYCLE * 2) enable = 1'b1;
        #(`CYCLE * 2) daclrck = 1'b0;
        dac_data = DATA[47:32];
        #(`CYCLE * 1) check = 1'b1;
        #(`CYCLE * 16) check = 1'b0;
        #(`CYCLE * 3) daclrck = 1'b1; 
        #(`CYCLE * 20) enable = 1'b0;

        #(`CYCLE * 2) enable = 1'b1;
        #(`CYCLE * 2) daclrck = 1'b0;
        dac_data = DATA[31:16];
        #(`CYCLE * 1) check = 1'b1;
        #(`CYCLE * 16) check = 1'b0;
        #(`CYCLE * 3) daclrck = 1'b1; 
        #(`CYCLE * 20) enable = 1'b0;

        #(`CYCLE * 2) enable = 1'b1;
        #(`CYCLE * 2) daclrck = 1'b0;
        dac_data = DATA[15:0];
        #(`CYCLE * 1) check = 1'b1;
        #(`CYCLE * 16) check = 1'b0;
        #(`CYCLE * 3) daclrck = 1'b1; 
        #(`CYCLE * 20) enable = 1'b0;
    end

    //Check
    initial begin
        #(`CYCLE * 6)


        // for(cnt1=3, cnt2=15; cnt1>=0; cnt1--) begin
        //     #(`CYCLE * 5) data_base2 = DATA[cnt1*16+cnt2];
        //     for(cnt2=14; cnt2>=0; cnt2--) begin
        //         #(`CYCLE * 1) data_base2 = DATA[cnt1*16+cnt2];
        //     end
        //     #(`CYCLE * 24)
        // end

        #(`CYCLE * 5) data_base2 = 1;
        #(`CYCLE * 1) data_base2 = 0;
        #(`CYCLE * 1) data_base2 = 1;
        #(`CYCLE * 1) data_base2 = 1;
        #(`CYCLE * 1) data_base2 = 1;
        #(`CYCLE * 1) data_base2 = 0;
        #(`CYCLE * 1) data_base2 = 1;
        #(`CYCLE * 1) data_base2 = 0;
        #(`CYCLE * 1) data_base2 = 0;
        #(`CYCLE * 1) data_base2 = 0;
        #(`CYCLE * 1) data_base2 = 0;
        #(`CYCLE * 1) data_base2 = 0;
        #(`CYCLE * 1) data_base2 = 1;
        #(`CYCLE * 1) data_base2 = 1;
        #(`CYCLE * 1) data_base2 = 1;
        #(`CYCLE * 1) data_base2 = 0;
        #(`CYCLE * 24)

        #(`CYCLE * 5) data_base2 = 0;
        #(`CYCLE * 1) data_base2 = 1;
        #(`CYCLE * 1) data_base2 = 0;
        #(`CYCLE * 1) data_base2 = 1;
        #(`CYCLE * 1) data_base2 = 1;
        #(`CYCLE * 1) data_base2 = 1;
        #(`CYCLE * 1) data_base2 = 1;
        #(`CYCLE * 1) data_base2 = 0;
        #(`CYCLE * 1) data_base2 = 0;
        #(`CYCLE * 1) data_base2 = 0;
        #(`CYCLE * 1) data_base2 = 1;
        #(`CYCLE * 1) data_base2 = 1;
        #(`CYCLE * 1) data_base2 = 1;
        #(`CYCLE * 1) data_base2 = 0;
        #(`CYCLE * 1) data_base2 = 1;
        #(`CYCLE * 1) data_base2 = 0;
        #(`CYCLE * 24)

        #(`CYCLE * 5) data_base2 = 1;
        #(`CYCLE * 1) data_base2 = 1;
        #(`CYCLE * 1) data_base2 = 1;
        #(`CYCLE * 1) data_base2 = 0;
        #(`CYCLE * 1) data_base2 = 1;
        #(`CYCLE * 1) data_base2 = 0;
        #(`CYCLE * 1) data_base2 = 1;
        #(`CYCLE * 1) data_base2 = 0;
        #(`CYCLE * 1) data_base2 = 0;
        #(`CYCLE * 1) data_base2 = 0;
        #(`CYCLE * 1) data_base2 = 0;
        #(`CYCLE * 1) data_base2 = 1;
        #(`CYCLE * 1) data_base2 = 1;
        #(`CYCLE * 1) data_base2 = 0;
        #(`CYCLE * 1) data_base2 = 0;
        #(`CYCLE * 1) data_base2 = 1;
        #(`CYCLE * 24)

        #(`CYCLE * 5) data_base2 = 1;
        #(`CYCLE * 1) data_base2 = 1;
        #(`CYCLE * 1) data_base2 = 1;
        #(`CYCLE * 1) data_base2 = 1;
        #(`CYCLE * 1) data_base2 = 1;
        #(`CYCLE * 1) data_base2 = 0;
        #(`CYCLE * 1) data_base2 = 0;
        #(`CYCLE * 1) data_base2 = 0;
        #(`CYCLE * 1) data_base2 = 0;
        #(`CYCLE * 1) data_base2 = 0;
        #(`CYCLE * 1) data_base2 = 0;
        #(`CYCLE * 1) data_base2 = 1;
        #(`CYCLE * 1) data_base2 = 0;
        #(`CYCLE * 1) data_base2 = 1;
        #(`CYCLE * 1) data_base2 = 0;
        #(`CYCLE * 1) data_base2 = 1;
    end

    always@(negedge clock) begin
        if(check) begin
            i <= i + 1;
            if(o_aud_dacdat !== data_base2) begin
                error <= error + 1;
                $display("An ERROR occurs at no.%d pattern: player_out %b != answer %b.\n", i, o_aud_dacdat, data_base2);
            end
        end
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