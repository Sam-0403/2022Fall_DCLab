`timescale 1ns/10ps
`define CYCLE 10.0
`define HCYCLE 5.0

module tb;
    integer error, num, i;
    parameter pattern_num = 4;

    logic clock, finish, check;
    logic rst, daclrck/*, enable*/;
    logic start, pause, stop, fast, slow_0, slow_1;
    logic [2:0] speed;
    logic [15:0] sram_data;
    logic [19:0] sram_addr;
    logic [15:0] dac_data;

    //clock
    initial begin
        clock = 1'b1;
        daclrck = 1'b1;
    end
    always begin #(`HCYCLE) clock = ~clock;
    end

    AudDSP dsp(
        .i_rst_n(rst),
        .i_clk(clock),
        .i_start(start),
        .i_pause(pause),
        .i_stop(stop),
        .i_speed(speed),
        .i_fast(fast),
        .i_slow_0(slow_0), 
        .i_slow_1(slow_1),
        .i_daclrck(daclrck),
        .i_sram_data(sram_data),
        .o_dac_data (dac_data),
        .o_sram_addr(sram_addr)
    );

    case(sram_addr)
        20'd0: begin
            assign sram_data = 16'b1011_0100_0000_1111;
        end
        20'd1: begin
            assign sram_data = 16'b1001_0100_0000_1111;
        end
        20'd2: begin
            assign sram_data = 16'b0011_0101_1000_1110;
        end
        20'd3: begin
            assign sram_data = 16'b1011_0110_0000_1100;
        end
        20'd4: begin
            assign sram_data = 16'b0010_0100_0011_1101;
        end
        20'd5: begin
            assign sram_data = 16'b1011_0100_0010_1111;
        end
        20'd6: begin
            assign sram_data = 16'b0011_0100_1000_1111;
        end
        20'd7: begin
            assign sram_data = 16'b0100_0100_0101_0000;
        end
        20'd8: begin
            assign sram_data = 16'b1011_0100_0010_1100;
        end
        20'd9: begin
            assign sram_data = 16'b1010_0100_1111_1010;
        end
        20'd10: begin
            assign sram_data = 16'b0011_0101_0000_1111;
        end
        20'd11: begin
            assign sram_data = 16'b1000_0100_0000_1111;
        end
        20'd12: begin
            assign sram_data = 16'b0011_0110_1000_1001;
        end
        20'd13: begin
            assign sram_data = 16'b1001_0100_0100_1101;
        end
        20'd14: begin
            assign sram_data = 16'b1110_0100_1000_1001;
        end
        20'd15: begin
            assign sram_data = 16'b1011_0100_0010_0100;
        end
        default: begin
            assign sram_data = 16'b0000_0000_0000_0000;
        end
    endcase

    //Read file
    initial begin
        error = 0;
        finish = 1'b0;
        i = 1;
        #(`CYCLE * 300) finish = 1'b1;
    end

    // Test
    initial begin
        rst = 1'b1; check = 1'b0; start = 1'b0; 
        stop = 1'b0; pause = 1'b0; speed = 3'b0; fast = 1'b0;
        slow_0 = 1'b0; slow_1 = 1'b0;
        #(`CYCLE * 2.5) rst = 1'b0;
        #(`CYCLE * 3) rst = 1'b1;

        #(`CYCLE * 2) start = 1'b1;
        #(`CYCLE * 1) start = 1'b0;
        #(`CYCLE * 20) stop = 1'b1;
        #(`CYCLE * 1) stop = 1'b0;

        #(`CYCLE * 2) start = 1'b1; fast = 1'b1; speed = 3'd3;
        #(`CYCLE * 1) start = 1'b0;
        #(`CYCLE * 3) pause = 1'b1;
        #(`CYCLE * 1) pause = 1'b0;
        #(`CYCLE * 3) start = 1'b1;
        #(`CYCLE * 1) start = 1'b0;
        #(`CYCLE * 10) stop = 1'b1;
        #(`CYCLE * 1) stop = 1'b0;

        #(`CYCLE * 1) start = 1'b1; fast = 1'b0; slow_0 = 1'b1; speed = 3'd3;
        #(`CYCLE * 1) start = 1'b0;
        #(`CYCLE * 22) pause = 1'b1;
        #(`CYCLE * 1) pause = 1'b0;
        #(`CYCLE * 3) start = 1'b1;
        #(`CYCLE * 1) start = 1'b0;
        #(`CYCLE * 60) stop = 1'b1;
        #(`CYCLE * 1) stop = 1'b0;

        #(`CYCLE * 1) start = 1'b1; slow_0 = 1'b0; slow_1 = 1'b1; speed = 3'd3;
        #(`CYCLE * 1) start = 1'b0;
        #(`CYCLE * 22) pause = 1'b1;
        #(`CYCLE * 1) pause = 1'b0;
        #(`CYCLE * 3) start = 1'b1;
        #(`CYCLE * 1) start = 1'b0;
        #(`CYCLE * 60) stop = 1'b1;
        #(`CYCLE * 1) stop = 1'b0;
    end

    always begin
        #(`CYCLE * 1) daclrck = ~daclrck;
    end

    initial begin
        @(posedge finish) begin
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
        $fsdbDumpfile("AudDSP.fsdb");
        $fsdbDumpvars;
    end

endmodule