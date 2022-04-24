/******************************************

    Filename:stopwatch.v
    Autnor:Sherrysama
    Data:2022/4/12

******************************************/

module stopwatch (
    clk, //输入时钟信号
    KeyA,KeyB,KeyC, //输入按键信号
    HEX0,HEX1,HEX2,HEX3,HEX4,HEX5,HEX6,HEX7, //输出数码管控制信号
    led_g,led_r1,led_r2 //输出LED控制信号
);
    parameter time_min = 500_000;
//数码管控制信号位宽为7
    parameter _0 = 7'b100_0000, _1 = 7'b111_1001, _2 = 7'b010_0100,
        _3 = 7'b011_0000, _4 = 7'b001_1001, _5 = 7'b001_0010, _6 = 7'b000_0010,
        _7 = 7'b111_1000, _8 = 7'b000_0000, _9 = 7'b001_0000;
//输入信号
    input clk;
	reg rstn; //异步复位信号
    input KeyA;
    input KeyB;
	input KeyC;
//由KeyC按键信号提供异步复位信号
	always @(KeyC) begin
		rstn <= KeyC;
	end
//用于循环语句
	reg [3:0] i;
//按键工作状态判断辅助信号
    reg [6:0] KeyA_press = 7'd0;
    reg [6:0] KeyB_press = 7'd0;
//按键消抖后得到的信号
    reg KeyA_short = 'b0;
    reg KeyA_long = 'b0;
    reg KeyB_short = 'b0;
    reg KeyB_long = 'b0;
//计数器
    reg [12:0] count = 13'd0;
//数码管输出相关信号
//display控制右边四个数码管，display2控制左边四个数码管
    reg [12:0] display = 13'd0;
    reg [12:0] display2 = 13'd0;
    reg [3:0] display_a = 4'd0,display_b = 4'd0,display_c = 4'd0,display_d = 4'd0;
    reg [3:0] display_e = 4'd0,display_f = 4'd0,display_g = 4'd0,display_h = 4'd0;
    output [6:0] HEX3 = 7'd0,HEX2 = 7'd0,HEX1 = 7'd0,HEX0 = 7'd0;
    reg [6:0] HEX3 = 7'd0,HEX2 = 7'd0,HEX1 = 7'd0,HEX0 = 7'd0;
    output [6:0] HEX7 = 7'd0,HEX6 = 7'd0,HEX5 = 7'd0,HEX4 = 7'd0;
    reg [6:0] HEX7 = 7'd0,HEX6 = 7'd0,HEX5 = 7'd0,HEX4 = 7'd0;
//记录存储功能所需寄存器数组及其初始化
	reg [12:0] storage[0:8];
	initial begin
		for(i=0;i<9;i=i+1) begin
			storage[i] <= 13'd0;
		end
	end
//记录存储功能辅助信号
	reg [9:0] storage_count = 10'd0;
    reg [3:0] storage_display_count = 4'd0;
    reg [3:0] storage_sum = 4'd0;
//LED输出控制信号
    output [8:0] led_r1 = 9'd0;
    reg [8:0] led_r1 = 9'd0;
    output [8:0] led_r2 = 9'd0;
    reg [8:0] led_r2 = 9'd0;
    output [2:0] led_g = 3'b000;
    reg [2:0] led_g = 3'b000;
//秒表工作状态控制信号
    reg on_off = 'b0;
    reg reset = 'b0;
    reg pause = 'b0;

//时钟分频
    reg [18:0] clk_count;
    always @(posedge clk) begin
        if (clk_count==249_999) begin
            clk_count <= 'b0;
        end
        else begin
            clk_count <= clk_count + 1;
        end
    end
    reg clk_min;
    always @(posedge clk) begin
        if (clk_count==249_999) begin
            clk_min <= ~clk_min;
        end
    end

//状态转换与工作逻辑
    always @(posedge clk_min or negedge rstn) begin
        if (!rstn) begin
			reset <= 1;
		end
		else begin
        //计数器工作逻辑
		    if (count==13'b1_0111_0111_0000) begin
                pause <= 1;
                storage_display_count <= 4'd0;
            end
            else if (reset) begin
                count <= 13'd0;
            end
            else if (pause) begin
                count <= count;
            end
            else if (on_off) begin
                count <= count + 1;
            end
        //按键A消抖
            if (KeyA==0) begin
                if (KeyA_press<100) begin
                    KeyA_press <= KeyA_press + 1;
                end
                else if (KeyA_press==100) begin
                    KeyA_long <= 1;
                    KeyA_press <= KeyA_press + 1;
                end
            end
            else begin
                if (KeyA_press>99) begin
                    KeyA_press <= 7'd0;
                end
                else if (KeyA_press>1) begin
                    KeyA_short <= 1;
                    KeyA_press <= 7'd0;
                end
                else begin
                    KeyA_press <= 7'd0;
                end
            end
        //按键B消抖
            if (KeyB==0) begin
                if (KeyB_press<100) begin
                    KeyB_press <= KeyB_press + 1;
                end
                else if (KeyB_press==100) begin
                    KeyB_long <= 1;
                    KeyB_press <= KeyB_press + 1;
                end
            end
            else begin
                if (KeyB_press>99) begin
                    KeyB_press <= 7'd0;
                end
                else if (KeyB_press>1) begin
                    KeyB_short <= 1;
                    KeyB_press <= 7'd0;
                end
                else begin
                    KeyB_press <= 7'd0;
                end
            end
        //复位状态下的按键工作逻辑
            if (reset) begin
                if (KeyA_short) begin
                    reset <= 0;
                    on_off <= 1;
                    KeyA_short <= ~KeyA_short;
                end
            end
        //计数状态下的按键工作逻辑
            else if (on_off) begin
                if (KeyA_short) begin
                    on_off <= 0;
                    pause <= 1;
                    storage_display_count <= 4'd0;
                    KeyA_short <= ~KeyA_short;
                end
                else if (KeyA_long) begin
                    on_off <= 0;
                    reset <= 1;
                    KeyA_long <= ~KeyA_long;
                end
                else if (KeyB_short) begin
                    storage[storage_count%9] <= count;
                    case (storage_count)
                        10'd0:storage_sum <= 4'd1;
                        10'd1:storage_sum <= 4'd2;
                        10'd2:storage_sum <= 4'd3;
                        10'd3:storage_sum <= 4'd4;
                        10'd4:storage_sum <= 4'd5;
                        10'd5:storage_sum <= 4'd6;
                        10'd6:storage_sum <= 4'd7;
                        10'd7:storage_sum <= 4'd8;
                        10'd8:storage_sum <= 4'd9;
                        default:storage_sum <= 4'd9;
                    endcase
                    storage_count <= storage_count + 1;
                    KeyB_short <= ~KeyB_short;
                end
            end
        //暂停状态下的按键工作逻辑
            else if (pause) begin
                if (KeyA_short) begin
                    pause <= 0;
                    on_off <= 1;
                    KeyA_short <= ~KeyA_short;
                end
                else if (KeyA_long) begin
                    pause <= 0;
                    reset <= 1;
                    KeyA_long <= ~KeyA_long;
                end
                else if (KeyB_short) begin
                    if (storage_display_count==storage_sum) begin
                        storage_display_count <= 4'd0;
                    end
                    else begin
                        storage_display_count <= storage_display_count + 1;
                    end
                    KeyB_short <= ~KeyB_short;
                end
                else if (KeyB_long) begin
                    if (!storage_count) begin
                        KeyB_long <= ~KeyB_long;
                    end
                    else begin
                        case (storage_count)
                            10'd1:storage_display_count <= 4'd1;
                            10'd2:storage_display_count <= 4'd1;
                            10'd3:storage_display_count <= 4'd1;
                            10'd4:storage_display_count <= 4'd1;
                            10'd5:storage_display_count <= 4'd1;
                            10'd6:storage_display_count <= 4'd1;
                            10'd7:storage_display_count <= 4'd1;
                            10'd8:storage_display_count <= 4'd1;
                            10'd9:storage_display_count <= 4'd1;
                            default:storage_display_count <= storage_count%9+1;
                        endcase
                        KeyB_long <= ~KeyB_long;
                    end
                end
            end
        //暂停状态下的工作逻辑
            if (reset) begin
                display <= 13'd0;
				display2 <= 13'd0;
                storage_count <= 10'd0;
                storage_sum <= 4'd0;
                storage_display_count <= 4'd0;
                for(i=0;i<9;i=i+1) begin
                    storage[i] <= 13'd0;
                end
            end
        //计数状态下的工作逻辑
            if (on_off) begin
                display <= count;
            end
        //暂停状态下的工作逻辑
            if (pause) begin
                case (storage_display_count)
                    4'd0:display2 <= 13'd0;
                    4'd1:display2 <= storage[0];
                    4'd2:display2 <= storage[1];
                    4'd3:display2 <= storage[2];
                    4'd4:display2 <= storage[3];
                    4'd5:display2 <= storage[4];
                    4'd6:display2 <= storage[5];
                    4'd7:display2 <= storage[6];
                    4'd8:display2 <= storage[7];
                    4'd9:display2 <= storage[8];
                    default:storage_display_count <= 4'd0;
                endcase
            end
		end
    end

//数码管引脚输出
    always @(display) begin
        display_a = display/1000;
        case (display_a)
            4'd0:HEX3 = _0;
            4'd1:HEX3 = _1;
            4'd2:HEX3 = _2;
            4'd3:HEX3 = _3;
            4'd4:HEX3 = _4;
            4'd5:HEX3 = _5;
            4'd6:HEX3 = _6;
            default:HEX3 = _0;
        endcase    
    end
    always @(display) begin
        display_b = (display/100)%10;
        case (display_b)
            4'd0:HEX2 = _0;
            4'd1:HEX2 = _1;
            4'd2:HEX2 = _2;
            4'd3:HEX2 = _3;
            4'd4:HEX2 = _4;
            4'd5:HEX2 = _5;
            4'd6:HEX2 = _6;
            4'd7:HEX2 = _7;
            4'd8:HEX2 = _8;
            4'd9:HEX2 = _9;
        endcase
    end
    always @(display) begin
        display_c = (display/10)%10;
        case (display_c)
            4'd0:HEX1 = _0;
            4'd1:HEX1 = _1;
            4'd2:HEX1 = _2;
            4'd3:HEX1 = _3;
            4'd4:HEX1 = _4;
            4'd5:HEX1 = _5;
            4'd6:HEX1 = _6;
            4'd7:HEX1 = _7;
            4'd8:HEX1 = _8;
            4'd9:HEX1 = _9;
        endcase
    end
    always @(display) begin
        display_d = display%10;
        case (display_d)
            4'd0:HEX0 = _0;
            4'd1:HEX0 = _1;
            4'd2:HEX0 = _2;
            4'd3:HEX0 = _3;
            4'd4:HEX0 = _4;
            4'd5:HEX0 = _5;
            4'd6:HEX0 = _6;
            4'd7:HEX0 = _7;
            4'd8:HEX0 = _8;
            4'd9:HEX0 = _9;
        endcase
    end

    always @(display2) begin
        display_e = display2/1000;
        case (display_e)
            4'd0:HEX7 = _0;
            4'd1:HEX7 = _1;
            4'd2:HEX7 = _2;
            4'd3:HEX7 = _3;
            4'd4:HEX7 = _4;
            4'd5:HEX7 = _5;
            4'd6:HEX7 = _6;
            default:HEX7 = _0;
        endcase    
    end
    always @(display2) begin
        display_f = (display2/100)%10;
        case (display_f)
            4'd0:HEX6 = _0;
            4'd1:HEX6 = _1;
            4'd2:HEX6 = _2;
            4'd3:HEX6 = _3;
            4'd4:HEX6 = _4;
            4'd5:HEX6 = _5;
            4'd6:HEX6 = _6;
            4'd7:HEX6 = _7;
            4'd8:HEX6 = _8;
            4'd9:HEX6 = _9;
        endcase
    end
    always @(display2) begin
        display_g = (display2/10)%10;
        case (display_g)
            4'd0:HEX5 = _0;
            4'd1:HEX5 = _1;
            4'd2:HEX5 = _2;
            4'd3:HEX5 = _3;
            4'd4:HEX5 = _4;
            4'd5:HEX5 = _5;
            4'd6:HEX5 = _6;
            4'd7:HEX5 = _7;
            4'd8:HEX5 = _8;
            4'd9:HEX5 = _9;
        endcase
    end
    always @(display2) begin
        display_h = display2%10;
        case (display_h)
            4'd0:HEX4 = _0;
            4'd1:HEX4 = _1;
            4'd2:HEX4 = _2;
            4'd3:HEX4 = _3;
            4'd4:HEX4 = _4;
            4'd5:HEX4 = _5;
            4'd6:HEX4 = _6;
            4'd7:HEX4 = _7;
            4'd8:HEX4 = _8;
            4'd9:HEX4 = _9;
        endcase
    end

//绿色LED指示灯：工作状态
    always @(reset or on_off or pause) begin
        if (reset) begin
            led_g = 3'b100;
        end
        else if (on_off) begin
            led_g = 3'b010;
        end
        else if (pause) begin
            led_g = 3'b001;
        end
        else begin
            led_g = 3'b000;
        end
    end
//红色LED灯 前9个：保存的时间记录条数
    always @(storage_sum) begin
        case (storage_sum)
            4'd0:led_r1 = 9'b0_0000_0000;
            4'd1:led_r1 = 9'b1_0000_0000;
            4'd2:led_r1 = 9'b0_1000_0000;
            4'd3:led_r1 = 9'b0_0100_0000;
            4'd4:led_r1 = 9'b0_0010_0000;
            4'd5:led_r1 = 9'b0_0001_0000;
            4'd6:led_r1 = 9'b0_0000_1000;
            4'd7:led_r1 = 9'b0_0000_0100;
            4'd8:led_r1 = 9'b0_0000_0010;
            4'd9:led_r1 = 9'b0_0000_0001;
            default:led_r1 = 9'b0_0000_0000;
        endcase
    end
//红色LED灯 后9个：显示的时间记录序号
    always @(storage_display_count) begin
        case (storage_display_count)
            4'd0:led_r2 = 9'b0_0000_0000;
            4'd1:led_r2 = 9'b1_0000_0000;
            4'd2:led_r2 = 9'b0_1000_0000;
            4'd3:led_r2 = 9'b0_0100_0000;
            4'd4:led_r2 = 9'b0_0010_0000;
            4'd5:led_r2 = 9'b0_0001_0000;
            4'd6:led_r2 = 9'b0_0000_1000;
            4'd7:led_r2 = 9'b0_0000_0100;
            4'd8:led_r2 = 9'b0_0000_0010;
            4'd9:led_r2 = 9'b0_0000_0001;
            default:led_r2 = 9'b0_0000_0000;
        endcase
    end

endmodule //stopwatch