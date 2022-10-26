module    LCD_TEST (
    //    Host Side                    
    input iCLK,
    input iRST_N,
    input [2:0] i_state,
    //    LCD Side
    output [7:0] LCD_DATA,
    output LCD_RW,
    output LCD_EN,
    output LCD_RS
);
//    Internal Wires/Registers
reg    [5:0]    LUT_INDEX;
reg    [8:0]    LUT_DATA;
reg    [5:0]    mLCD_ST;
reg    [17:0]    mDLY;
reg            mLCD_Start;
reg    [7:0]    mLCD_DATA;
reg            mLCD_RS;
wire        mLCD_Done;

parameter    LCD_INTIAL    =    0;
parameter    LCD_LINE1    =    5;
parameter    LCD_CH_LINE    =    LCD_LINE1+16;
parameter    LCD_LINE2    =    LCD_LINE1+16+1;
parameter    LUT_SIZE    =    LCD_LINE1+32+1;

parameter S_IDLE       = 0;
parameter S_I2C        = 1;
parameter S_RECD       = 2;
parameter S_RECD_PAUSE = 3;
parameter S_PLAY       = 4;
parameter S_PLAY_PAUSE = 5;

always@(posedge iCLK or negedge iRST_N)
begin
    if(!iRST_N)
    begin
        LUT_INDEX    <=    0;
        mLCD_ST        <=    0;
        mDLY        <=    0;
        mLCD_Start    <=    0;
        mLCD_DATA    <=    0;
        mLCD_RS        <=    0;
    end
    else
    begin
        if(LUT_INDEX<LUT_SIZE)
        begin
            case(mLCD_ST)
            0:    begin
                    mLCD_DATA    <=    LUT_DATA[7:0];
                    mLCD_RS        <=    LUT_DATA[8];
                    mLCD_Start    <=    1;
                    mLCD_ST        <=    1;
                end
            1:    begin
                    if(mLCD_Done)
                    begin
                        mLCD_Start    <=    0;
                        mLCD_ST        <=    2;                    
                    end
                end
            2:    begin
                    if(mDLY<18'h3FFFE)    // 5.2ms
                    mDLY    <=    mDLY+1;
                    else
                    begin
                        mDLY    <=    0;
                        mLCD_ST    <=    3;
                    end
                end
            3:    begin
                    LUT_INDEX    <=    LUT_INDEX+1;
                    mLCD_ST    <=    0;
                end
            endcase
        end
		  else begin
			LUT_INDEX    <=    LCD_LINE1-1;
		  end
    end
end

always
begin
    if(i_state == S_IDLE) begin
        case(LUT_INDEX)
		//    Initial
        LCD_INTIAL+0:    LUT_DATA    <=    9'h038; //Fun set
        LCD_INTIAL+1:    LUT_DATA    <=    9'h00C; //dis on
        LCD_INTIAL+2:    LUT_DATA    <=    9'h001; //clr dis
        LCD_INTIAL+3:    LUT_DATA    <=    9'h006; //Ent mode
        LCD_INTIAL+4:    LUT_DATA    <=    9'h080; //set ddram address
        //    Line 1
        LCD_LINE1+0:    LUT_DATA    <=    9'h154; // T
        LCD_LINE1+1:    LUT_DATA    <=    9'h165; // e
        LCD_LINE1+2:    LUT_DATA    <=    9'h161; // a
        LCD_LINE1+3:    LUT_DATA    <=    9'h16d; // m
        LCD_LINE1+4:    LUT_DATA    <=    9'h133; // 3
        LCD_LINE1+5:    LUT_DATA    <=    9'h120; // SP
        LCD_LINE1+6:    LUT_DATA    <=    9'h169; // i
        LCD_LINE1+7:    LUT_DATA    <=    9'h173; // s
        LCD_LINE1+8:    LUT_DATA    <=    9'h120; // SP
        LCD_LINE1+9:    LUT_DATA    <=    9'h161; // a
        LCD_LINE1+10:    LUT_DATA    <=    9'h177; // w
        LCD_LINE1+11:    LUT_DATA    <=    9'h165; // e
        LCD_LINE1+12:    LUT_DATA    <=    9'h173; // s
        LCD_LINE1+13:    LUT_DATA    <=    9'h16f; // o
        LCD_LINE1+14:    LUT_DATA    <=    9'h16d;  // m
        LCD_LINE1+15:    LUT_DATA    <=    9'h165;  // e
        //    Change Line
        LCD_CH_LINE:    LUT_DATA    <=    9'h0C0;
        //    Line 2
        LCD_LINE2+0:    LUT_DATA    <=    9'h153; // S
        LCD_LINE2+1:    LUT_DATA    <=    9'h174; // t
        LCD_LINE2+2:    LUT_DATA    <=    9'h161; // a
        LCD_LINE2+3:    LUT_DATA    <=    9'h174; // t
        LCD_LINE2+4:    LUT_DATA    <=    9'h165; // e
        LCD_LINE2+5:    LUT_DATA    <=    9'h13a; // :
        LCD_LINE2+6:    LUT_DATA    <=    9'h120; // SP
        LCD_LINE2+7:    LUT_DATA    <=    9'h120; // SP
        LCD_LINE2+8:    LUT_DATA    <=    9'h120; // SP
        LCD_LINE2+9:    LUT_DATA    <=    9'h120; // SP
        LCD_LINE2+10:    LUT_DATA    <=    9'h120 // SP
        LCD_LINE2+11:    LUT_DATA    <=    9'h120 // SP
        LCD_LINE2+12:    LUT_DATA    <=    9'h149 // I
        LCD_LINE2+13:    LUT_DATA    <=    9'h144 // D
        LCD_LINE2+14:    LUT_DATA    <=    9'h14c // L
        LCD_LINE2+15:    LUT_DATA    <=    9'h145 // E
        default:        LUT_DATA    <=    9'h000;
	endcase
    end
    else if(i_state == S_I2C) begin
        case(LUT_INDEX)
		//    Initial
        LCD_INTIAL+0:    LUT_DATA    <=    9'h038; //Fun set
        LCD_INTIAL+1:    LUT_DATA    <=    9'h00C; //dis on
        LCD_INTIAL+2:    LUT_DATA    <=    9'h001; //clr dis
        LCD_INTIAL+3:    LUT_DATA    <=    9'h006; //Ent mode
        LCD_INTIAL+4:    LUT_DATA    <=    9'h080; //set ddram address
        //    Line 1
        LCD_LINE1+0:    LUT_DATA    <=    9'h154; // T
        LCD_LINE1+1:    LUT_DATA    <=    9'h165; // e
        LCD_LINE1+2:    LUT_DATA    <=    9'h161; // a
        LCD_LINE1+3:    LUT_DATA    <=    9'h16d; // m
        LCD_LINE1+4:    LUT_DATA    <=    9'h133; // 3
        LCD_LINE1+5:    LUT_DATA    <=    9'h120; // SP
        LCD_LINE1+6:    LUT_DATA    <=    9'h169; // i
        LCD_LINE1+7:    LUT_DATA    <=    9'h173; // s
        LCD_LINE1+8:    LUT_DATA    <=    9'h120; // SP
        LCD_LINE1+9:    LUT_DATA    <=    9'h161; // a
        LCD_LINE1+10:    LUT_DATA    <=    9'h177; // w
        LCD_LINE1+11:    LUT_DATA    <=    9'h165; // e
        LCD_LINE1+12:    LUT_DATA    <=    9'h173; // s
        LCD_LINE1+13:    LUT_DATA    <=    9'h16f; // o
        LCD_LINE1+14:    LUT_DATA    <=    9'h16d;  // m
        LCD_LINE1+15:    LUT_DATA    <=    9'h165;  // e
        //    Change Line
        LCD_CH_LINE:    LUT_DATA    <=    9'h0C0;
        //    Line 2
        LCD_LINE2+0:    LUT_DATA    <=    9'h153; // S
        LCD_LINE2+1:    LUT_DATA    <=    9'h174; // t
        LCD_LINE2+2:    LUT_DATA    <=    9'h161; // a
        LCD_LINE2+3:    LUT_DATA    <=    9'h174; // t
        LCD_LINE2+4:    LUT_DATA    <=    9'h165; // e
        LCD_LINE2+5:    LUT_DATA    <=    9'h13a; // :
        LCD_LINE2+6:    LUT_DATA    <=    9'h120; // SP
        LCD_LINE2+7:    LUT_DATA    <=    9'h120; // SP
        LCD_LINE2+8:    LUT_DATA    <=    9'h120; // SP
        LCD_LINE2+9:    LUT_DATA    <=    9'h120; // SP
        LCD_LINE2+10:    LUT_DATA    <=    9'h120 // SP
        LCD_LINE2+11:    LUT_DATA    <=    9'h120 // SP
        LCD_LINE2+12:    LUT_DATA    <=    9'h120 // SP
        LCD_LINE2+13:    LUT_DATA    <=    9'h149 // I
        LCD_LINE2+14:    LUT_DATA    <=    9'h132 // 2
        LCD_LINE2+15:    LUT_DATA    <=    9'h143 // C
        default:        LUT_DATA    <=    9'h000;
	endcase
    end
    else if(i_state == S_RECD) begin
        case(LUT_INDEX)
		//    Initial
        LCD_INTIAL+0:    LUT_DATA    <=    9'h038; //Fun set
        LCD_INTIAL+1:    LUT_DATA    <=    9'h00C; //dis on
        LCD_INTIAL+2:    LUT_DATA    <=    9'h001; //clr dis
        LCD_INTIAL+3:    LUT_DATA    <=    9'h006; //Ent mode
        LCD_INTIAL+4:    LUT_DATA    <=    9'h080; //set ddram address
        //    Line 1
        LCD_LINE1+0:    LUT_DATA    <=    9'h154; // T
        LCD_LINE1+1:    LUT_DATA    <=    9'h165; // e
        LCD_LINE1+2:    LUT_DATA    <=    9'h161; // a
        LCD_LINE1+3:    LUT_DATA    <=    9'h16d; // m
        LCD_LINE1+4:    LUT_DATA    <=    9'h133; // 3
        LCD_LINE1+5:    LUT_DATA    <=    9'h120; // SP
        LCD_LINE1+6:    LUT_DATA    <=    9'h169; // i
        LCD_LINE1+7:    LUT_DATA    <=    9'h173; // s
        LCD_LINE1+8:    LUT_DATA    <=    9'h120; // SP
        LCD_LINE1+9:    LUT_DATA    <=    9'h161; // a
        LCD_LINE1+10:    LUT_DATA    <=    9'h177; // w
        LCD_LINE1+11:    LUT_DATA    <=    9'h165; // e
        LCD_LINE1+12:    LUT_DATA    <=    9'h173; // s
        LCD_LINE1+13:    LUT_DATA    <=    9'h16f; // o
        LCD_LINE1+14:    LUT_DATA    <=    9'h16d;  // m
        LCD_LINE1+15:    LUT_DATA    <=    9'h165;  // e
        //    Change Line
        LCD_CH_LINE:    LUT_DATA    <=    9'h0C0;
        //    Line 2
        LCD_LINE2+0:    LUT_DATA    <=    9'h153; // S
        LCD_LINE2+1:    LUT_DATA    <=    9'h174; // t
        LCD_LINE2+2:    LUT_DATA    <=    9'h161; // a
        LCD_LINE2+3:    LUT_DATA    <=    9'h174; // t
        LCD_LINE2+4:    LUT_DATA    <=    9'h165; // e
        LCD_LINE2+5:    LUT_DATA    <=    9'h13a; // :
        LCD_LINE2+6:    LUT_DATA    <=    9'h120; // SP
        LCD_LINE2+7:    LUT_DATA    <=    9'h120; // SP
        LCD_LINE2+8:    LUT_DATA    <=    9'h120; // SP
        LCD_LINE2+9:    LUT_DATA    <=    9'h120; // SP
        LCD_LINE2+10:    LUT_DATA    <=    9'h120 // SP
        LCD_LINE2+11:    LUT_DATA    <=    9'h120 // SP
        LCD_LINE2+12:    LUT_DATA    <=    9'h152 // R
        LCD_LINE2+13:    LUT_DATA    <=    9'h145 // E
        LCD_LINE2+14:    LUT_DATA    <=    9'h143 // C
        LCD_LINE2+15:    LUT_DATA    <=    9'h144 // D
        default:        LUT_DATA    <=    9'h000;
	endcase
    end
    else if(i_state == S_RECD_PAUSE) begin
        case(LUT_INDEX)
		//    Initial
        LCD_INTIAL+0:    LUT_DATA    <=    9'h038; //Fun set
        LCD_INTIAL+1:    LUT_DATA    <=    9'h00C; //dis on
        LCD_INTIAL+2:    LUT_DATA    <=    9'h001; //clr dis
        LCD_INTIAL+3:    LUT_DATA    <=    9'h006; //Ent mode
        LCD_INTIAL+4:    LUT_DATA    <=    9'h080; //set ddram address
        //    Line 1
        LCD_LINE1+0:    LUT_DATA    <=    9'h154; // T
        LCD_LINE1+1:    LUT_DATA    <=    9'h165; // e
        LCD_LINE1+2:    LUT_DATA    <=    9'h161; // a
        LCD_LINE1+3:    LUT_DATA    <=    9'h16d; // m
        LCD_LINE1+4:    LUT_DATA    <=    9'h133; // 3
        LCD_LINE1+5:    LUT_DATA    <=    9'h120; // SP
        LCD_LINE1+6:    LUT_DATA    <=    9'h169; // i
        LCD_LINE1+7:    LUT_DATA    <=    9'h173; // s
        LCD_LINE1+8:    LUT_DATA    <=    9'h120; // SP
        LCD_LINE1+9:    LUT_DATA    <=    9'h161; // a
        LCD_LINE1+10:    LUT_DATA    <=    9'h177; // w
        LCD_LINE1+11:    LUT_DATA    <=    9'h165; // e
        LCD_LINE1+12:    LUT_DATA    <=    9'h173; // s
        LCD_LINE1+13:    LUT_DATA    <=    9'h16f; // o
        LCD_LINE1+14:    LUT_DATA    <=    9'h16d;  // m
        LCD_LINE1+15:    LUT_DATA    <=    9'h165;  // e
        //    Change Line
        LCD_CH_LINE:    LUT_DATA    <=    9'h0C0;
        //    Line 2
        LCD_LINE2+0:    LUT_DATA    <=    9'h153; // S
        LCD_LINE2+1:    LUT_DATA    <=    9'h174; // t
        LCD_LINE2+2:    LUT_DATA    <=    9'h161; // a
        LCD_LINE2+3:    LUT_DATA    <=    9'h174; // t
        LCD_LINE2+4:    LUT_DATA    <=    9'h165; // e
        LCD_LINE2+5:    LUT_DATA    <=    9'h13a; // :
        LCD_LINE2+6:    LUT_DATA    <=    9'h152; // R
        LCD_LINE2+7:    LUT_DATA    <=    9'h145; // E
        LCD_LINE2+8:    LUT_DATA    <=    9'h143; // C
        LCD_LINE2+9:    LUT_DATA    <=    9'h144; // D
        LCD_LINE2+10:    LUT_DATA    <=    9'h120 // SP
        LCD_LINE2+11:    LUT_DATA    <=    9'h150 // P
        LCD_LINE2+12:    LUT_DATA    <=    9'h141 // A
        LCD_LINE2+13:    LUT_DATA    <=    9'h155 // U
        LCD_LINE2+14:    LUT_DATA    <=    9'h153 // S
        LCD_LINE2+15:    LUT_DATA    <=    9'h145 // E
        default:        LUT_DATA    <=    9'h000;
	endcase
    end
    else if(i_state == S_PLAY) begin
        case(LUT_INDEX)
		//    Initial
        LCD_INTIAL+0:    LUT_DATA    <=    9'h038; //Fun set
        LCD_INTIAL+1:    LUT_DATA    <=    9'h00C; //dis on
        LCD_INTIAL+2:    LUT_DATA    <=    9'h001; //clr dis
        LCD_INTIAL+3:    LUT_DATA    <=    9'h006; //Ent mode
        LCD_INTIAL+4:    LUT_DATA    <=    9'h080; //set ddram address
        //    Line 1
        LCD_LINE1+0:    LUT_DATA    <=    9'h154; // T
        LCD_LINE1+1:    LUT_DATA    <=    9'h165; // e
        LCD_LINE1+2:    LUT_DATA    <=    9'h161; // a
        LCD_LINE1+3:    LUT_DATA    <=    9'h16d; // m
        LCD_LINE1+4:    LUT_DATA    <=    9'h133; // 3
        LCD_LINE1+5:    LUT_DATA    <=    9'h120; // SP
        LCD_LINE1+6:    LUT_DATA    <=    9'h169; // i
        LCD_LINE1+7:    LUT_DATA    <=    9'h173; // s
        LCD_LINE1+8:    LUT_DATA    <=    9'h120; // SP
        LCD_LINE1+9:    LUT_DATA    <=    9'h161; // a
        LCD_LINE1+10:    LUT_DATA    <=    9'h177; // w
        LCD_LINE1+11:    LUT_DATA    <=    9'h165; // e
        LCD_LINE1+12:    LUT_DATA    <=    9'h173; // s
        LCD_LINE1+13:    LUT_DATA    <=    9'h16f; // o
        LCD_LINE1+14:    LUT_DATA    <=    9'h16d;  // m
        LCD_LINE1+15:    LUT_DATA    <=    9'h165;  // e
        //    Change Line
        LCD_CH_LINE:    LUT_DATA    <=    9'h0C0;
        //    Line 2
        LCD_LINE2+0:    LUT_DATA    <=    9'h153; // S
        LCD_LINE2+1:    LUT_DATA    <=    9'h174; // t
        LCD_LINE2+2:    LUT_DATA    <=    9'h161; // a
        LCD_LINE2+3:    LUT_DATA    <=    9'h174; // t
        LCD_LINE2+4:    LUT_DATA    <=    9'h165; // e
        LCD_LINE2+5:    LUT_DATA    <=    9'h13a; // :
        LCD_LINE2+6:    LUT_DATA    <=    9'h120; // SP
        LCD_LINE2+7:    LUT_DATA    <=    9'h120; // SP
        LCD_LINE2+8:    LUT_DATA    <=    9'h120; // SP
        LCD_LINE2+9:    LUT_DATA    <=    9'h120; // SP
        LCD_LINE2+10:    LUT_DATA    <=    9'h120 // SP
        LCD_LINE2+11:    LUT_DATA    <=    9'h120 // SP
        LCD_LINE2+12:    LUT_DATA    <=    9'h150 // P
        LCD_LINE2+13:    LUT_DATA    <=    9'h14c // L
        LCD_LINE2+14:    LUT_DATA    <=    9'h141 // A
        LCD_LINE2+15:    LUT_DATA    <=    9'h159 // Y
        default:        LUT_DATA    <=    9'h000;
	endcase
    end
    else if(i_state == S_PLAY_PAUSE) begin
        case(LUT_INDEX)
		//    Initial
        LCD_INTIAL+0:    LUT_DATA    <=    9'h038; //Fun set
        LCD_INTIAL+1:    LUT_DATA    <=    9'h00C; //dis on
        LCD_INTIAL+2:    LUT_DATA    <=    9'h001; //clr dis
        LCD_INTIAL+3:    LUT_DATA    <=    9'h006; //Ent mode
        LCD_INTIAL+4:    LUT_DATA    <=    9'h080; //set ddram address
        //    Line 1
        LCD_LINE1+0:    LUT_DATA    <=    9'h154; // T
        LCD_LINE1+1:    LUT_DATA    <=    9'h165; // e
        LCD_LINE1+2:    LUT_DATA    <=    9'h161; // a
        LCD_LINE1+3:    LUT_DATA    <=    9'h16d; // m
        LCD_LINE1+4:    LUT_DATA    <=    9'h133; // 3
        LCD_LINE1+5:    LUT_DATA    <=    9'h120; // SP
        LCD_LINE1+6:    LUT_DATA    <=    9'h169; // i
        LCD_LINE1+7:    LUT_DATA    <=    9'h173; // s
        LCD_LINE1+8:    LUT_DATA    <=    9'h120; // SP
        LCD_LINE1+9:    LUT_DATA    <=    9'h161; // a
        LCD_LINE1+10:    LUT_DATA    <=    9'h177; // w
        LCD_LINE1+11:    LUT_DATA    <=    9'h165; // e
        LCD_LINE1+12:    LUT_DATA    <=    9'h173; // s
        LCD_LINE1+13:    LUT_DATA    <=    9'h16f; // o
        LCD_LINE1+14:    LUT_DATA    <=    9'h16d;  // m
        LCD_LINE1+15:    LUT_DATA    <=    9'h165;  // e
        //    Change Line
        LCD_CH_LINE:    LUT_DATA    <=    9'h0C0;
        //    Line 2
        LCD_LINE2+0:    LUT_DATA    <=    9'h153; // S
        LCD_LINE2+1:    LUT_DATA    <=    9'h174; // t
        LCD_LINE2+2:    LUT_DATA    <=    9'h161; // a
        LCD_LINE2+3:    LUT_DATA    <=    9'h174; // t
        LCD_LINE2+4:    LUT_DATA    <=    9'h165; // e
        LCD_LINE2+5:    LUT_DATA    <=    9'h13a; // :
        LCD_LINE2+6:    LUT_DATA    <=    9'h150; // P
        LCD_LINE2+7:    LUT_DATA    <=    9'h14c; // L
        LCD_LINE2+8:    LUT_DATA    <=    9'h141; // A
        LCD_LINE2+9:    LUT_DATA    <=    9'h159; // Y
        LCD_LINE2+10:    LUT_DATA    <=    9'h120 // SP
        LCD_LINE2+11:    LUT_DATA    <=    9'h150 // P
        LCD_LINE2+12:    LUT_DATA    <=    9'h141 // A
        LCD_LINE2+13:    LUT_DATA    <=    9'h155 // U
        LCD_LINE2+14:    LUT_DATA    <=    9'h153 // S
        LCD_LINE2+15:    LUT_DATA    <=    9'h145 // E
        default:        LUT_DATA    <=    9'h000;
	endcase
    end
    else begin
	case(LUT_INDEX)
		//    Initial
        LCD_INTIAL+0:    LUT_DATA    <=    9'h038; //Fun set
        LCD_INTIAL+1:    LUT_DATA    <=    9'h00C; //dis on
        LCD_INTIAL+2:    LUT_DATA    <=    9'h001; //clr dis
        LCD_INTIAL+3:    LUT_DATA    <=    9'h006; //Ent mode
        LCD_INTIAL+4:    LUT_DATA    <=    9'h080; //set ddram address
        //    Line 1
        LCD_LINE1+0:    LUT_DATA    <=    9'h154; // T
        LCD_LINE1+1:    LUT_DATA    <=    9'h165; // e
        LCD_LINE1+2:    LUT_DATA    <=    9'h161; // a
        LCD_LINE1+3:    LUT_DATA    <=    9'h16d; // m
        LCD_LINE1+4:    LUT_DATA    <=    9'h133; // 3
        LCD_LINE1+5:    LUT_DATA    <=    9'h120; // SP
        LCD_LINE1+6:    LUT_DATA    <=    9'h169; // i
        LCD_LINE1+7:    LUT_DATA    <=    9'h173; // s
        LCD_LINE1+8:    LUT_DATA    <=    9'h120; // SP
        LCD_LINE1+9:    LUT_DATA    <=    9'h161; // a
        LCD_LINE1+10:    LUT_DATA    <=    9'h177; // w
        LCD_LINE1+11:    LUT_DATA    <=    9'h165; // e
        LCD_LINE1+12:    LUT_DATA    <=    9'h173; // s
        LCD_LINE1+13:    LUT_DATA    <=    9'h16f; // o
        LCD_LINE1+14:    LUT_DATA    <=    9'h16d;  // m
        LCD_LINE1+15:    LUT_DATA    <=    9'h165;  // e
        //    Change Line
        LCD_CH_LINE:    LUT_DATA    <=    9'h0C0;
        //    Line 2
        LCD_LINE2+0:    LUT_DATA    <=    9'h153; // S
        LCD_LINE2+1:    LUT_DATA    <=    9'h174; // t
        LCD_LINE2+2:    LUT_DATA    <=    9'h161; // a
        LCD_LINE2+3:    LUT_DATA    <=    9'h174; // t
        LCD_LINE2+4:    LUT_DATA    <=    9'h165; // e
        LCD_LINE2+5:    LUT_DATA    <=    9'h13a; // :
        LCD_LINE2+6:    LUT_DATA    <=    9'h120; // SP
        LCD_LINE2+7:    LUT_DATA    <=    9'h120; // SP
        LCD_LINE2+8:    LUT_DATA    <=    9'h120; // SP
        LCD_LINE2+9:    LUT_DATA    <=    9'h120; // SP
        LCD_LINE2+10:    LUT_DATA    <=    9'h120 // SP
        LCD_LINE2+11:    LUT_DATA    <=    9'h120 // SP
        LCD_LINE2+12:    LUT_DATA    <=    9'h120 // SP
        LCD_LINE2+13:    LUT_DATA    <=    9'h120 // SP
        LCD_LINE2+14:    LUT_DATA    <=    9'h120 // SP
        LCD_LINE2+15:    LUT_DATA    <=    9'h120 // SP
        default:        LUT_DATA    <=    9'h000;
	endcase
    end
end

LCD_Controller  LCD_controller0 (
    //    Host Side
    .iDATA(mLCD_DATA),
    .iRS(mLCD_RS),
    .iStart(mLCD_Start),
    .oDone(mLCD_Done),
    .iCLK(iCLK),
    .iRST_N(iRST_N),
    //    LCD Interface
    .LCD_DATA(LCD_DATA),
    .LCD_RW(LCD_RW),
    .LCD_EN(LCD_EN),
    .LCD_RS(LCD_RS)
);

endmodule