`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Dept. of Computer Science, National Chiao Tung University
// Engineer: Chun-Jen Tsai 
// 
// Create Date: 2018/12/11 16:04:41
// Design Name: 
// Module Name: lab9
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: A circuit that show the animation of a fish swimming in a seabed
//              scene on a screen through the VGA interface of the Arty I/O card.
// 
// Dependencies: vga_sync, clk_divider, sram 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module lab10(
    input  clk,
    input  reset_n,
    input  [3:0] usr_btn,
    input  [3:0] usr_sw,
    output [3:0] usr_led,
    
    // VGA specific I/O ports
    output VGA_HSYNC,
    output VGA_VSYNC,
    output [3:0] VGA_RED,
    output [3:0] VGA_GREEN,
    output [3:0] VGA_BLUE
    );

// Declare system variables
reg  [31:0] pika_animation_clock;
reg  [31:0] ball_animation_clock;
reg  [1:0] ball_animation_index;
reg  [31:0] pika_clock1_x;
reg  [31:0] pika_clock2_x;
reg  [31:0] pika_clock1_y;
reg  [31:0] pika_clock2_y;
reg  [33:0] pika_positive_speed_clock1_y;
reg  [33:0] pika_negative_speed_clock1_y;
reg  [33:0] pika_positive_speed_clock2_y;
reg  [33:0] pika_negative_speed_clock2_y;
reg  [31:0] ball_clock_x;
reg  [31:0] ball_clock_y;
reg  [33:0] ball_positive_speed_clock_y;
reg  [33:0] ball_negative_speed_clock_y;
reg  [33:0] ball_right_speed_clock_x;
reg  [33:0] ball_left_speed_clock_x;
reg  [31:0] cloud_clock1;
reg  [31:0] cloud_clock2;
reg  [3:0] color_rage;
reg  [31:0] ducks_clock_x;
reg  [31:0] ducks_clock_y;

wire [9:0]  xpos_pika1;
wire [9:0]  xpos_pika2;
wire [9:0]  ypos_pika1;
wire [9:0]  ypos_pika2;
wire [9:0]  xpos_ball;
wire [9:0]  ypos_ball;
wire [9:0]  xpos_cloud1;
wire [9:0]  xpos_cloud2;
wire [9:0]  xpos_ducks;
wire [9:0]  ypos_ducks;

wire        pika_region1;
wire        pika_region2;
wire        cloud_region1;
wire        cloud_region2;
wire        stick_region;
wire        ball_region;
wire        score_region1;
wire        score_region2;
wire        ducks_region;

// declare SRAM control signals
wire [16:0] sram_addr_background;
wire [16:0] sram_addr_pika;
wire [16:0] sram_addr_stick;
wire [16:0] sram_addr_ball;
wire [16:0] sram_addr_cloud;
wire [16:0] sram_addr_score1; //score of pika1
wire [16:0] sram_addr_score2; //score of pika2
wire [16:0] sram_addr_gameset;
wire [16:0] sram_addr_ducks;

wire [11:0] data_in;
wire [11:0] data_out_background;
wire [11:0] data_out_pika;
wire [11:0] data_out_stick;
wire [11:0] data_out_ball;
wire [11:0] data_out_cloud;
wire [11:0] data_out_score1;
wire [11:0] data_out_score2;
wire [11:0] data_out_gameset;
wire [11:0] data_out_ducks;
wire        sram_we, sram_en;


// General VGA control signals
wire vga_clk;         // 50MHz clock for VGA control
wire video_on;        // when video_on is 0, the VGA controller is sending
                      // synchronization signals to the display device.
  
wire pixel_tick;      // when pixel tick is 1, we must update the RGB value
                      // based for the new coordinate (pixel_x, pixel_y)
  
wire [9:0] pixel_x;   // x coordinate of the next pixel (between 0 ~ 639) 
wire [9:0] pixel_y;   // y coordinate of the next pixel (between 0 ~ 479)
  
reg  [11:0] rgb_reg;  // RGB value for the current pixel
reg  [11:0] rgb_next; // RGB value for the next pixel
  
// Application-specific VGA signals
reg  [17:0] pixel_addr_background;
reg  [17:0] pixel_addr_pika;
reg  [17:0] pixel_addr_cloud;
reg  [17:0] pixel_addr_ball;
reg  [17:0] pixel_addr_stick;
reg  [17:0] pixel_addr_score1;
reg  [17:0] pixel_addr_score2;
reg  [17:0] pixel_addr_ducks;
reg  [17:0] pixel_addr_gameset;
// debounce
wire btn_level [3:0];
wire btn_pressed [3:0];
reg prev_btn_level [3:0];

// control jimping 
reg pika_jumping1;
reg pika_jumping2;

// debug
reg [3:0] to_usr_led;

// score system
reg  [3:0]  score_pika1;
reg  [3:0]  score_pika2; // record the score
wire        pika1_get_score;
wire        pika2_get_score;

// wind controler
reg  [31:0] wind_clock;
reg  [1:0]  wind_blow_direction; // 0 -> no_wind ,  1-> wind_right  , 2-> no_wind , 3-> wind_left
reg  [31:0] wind_shift_counter;
wire [3:0] wind_right_speed;
wire [3:0] wind_left_speed;

// stick
reg [4:0] stick_adjust;
reg [3:0] stick_counter;
reg [31:0]stick_clock;
reg [31:0]stick_smooth_clock;

//killing ball
reg   killing_ball;

// Declare the video buffer size
localparam VBUF_W = 320; // video buffer width
localparam VBUF_H = 240; // video buffer height

// Set parameters for the fish images
localparam PIKA_W      = 50; // Width of the pika.
localparam PIKA_H      = 50; // Height of the pika.
localparam PIKA_VPOS   = VBUF_H - PIKA_H ; // Vertical location of the fish in the sea image.

localparam STICK_W     = 10;
localparam STICK_H     = 175;
localparam STICK_VPOS  = VBUF_H - STICK_H ;
localparam VBUF_MID    = VBUF_W + STICK_W ;
localparam BALL_W      = 20;
localparam BALL_H      = 20;
localparam CLOUD_W     = 45;
localparam CLOUD_H     = 20;
localparam SCORE_W     = 25;
localparam SCORE_H     = 30;
localparam DUCKS_W     = 25;
localparam DUCKS_H     = 25;
localparam GAMESET_W   = 50;
localparam GAMESET_H   = 20;

localparam BALL_VPOS   = 80;
localparam CLOUD_VPOS1  = 30;
localparam CLOUD_VPOS2  = 50;
localparam DUCKS_VPOS   = 80;
localparam GAMESET_VPOS  = 20;
localparam GAMESET_XPOS  = 370;

localparam [11:0] PIKA_Y0_HPOS = 12'b111100000000;

reg P,P_next;

reg [17:0] pika_addr [2:0];   // Address array for up to 8 fish images.
reg [17:0] stick_addr;
reg [17:0] ball_addr [3:0];
reg [17:0] score_addr [9:0]; // 0~9  10 in total
reg [17:0] ducks_addr [1:0];

//debug only
assign usr_led = to_usr_led;

always@(*)begin
    if (~reset_n)begin
        to_usr_led = 4'b0000;
    end
    
    if (xpos_ball >= VBUF_W * 2)begin
        to_usr_led[0] = 1;
    end
    else begin
        to_usr_led[0] = 0;
    end
    
    
    if (xpos_ball - BALL_W * 2 <= 0)begin
        to_usr_led[1] = 1;
    end
    else begin
        to_usr_led[1] = 0;
    end
    
    if ((ball_region && pika_region1 && !pika_jumping1) || (ball_region && pika_region2 && !pika_jumping2))begin
        to_usr_led[2] = 1;
    end
    else begin
        to_usr_led[2] = 0;
    end
    
    if (ball_region && stick_region)begin
        to_usr_led[3] = 1;
    end
    else begin
        to_usr_led[3] = 0;
    end
    
end

// Initializes the fish images starting addresses.
// Note: System Verilog has an easier way to initialize an array,
//       but we are using Verilog 2001 :(
initial begin
  
  // pikachu image 
  pika_addr[0] = (0 + 1) * PIKA_W * PIKA_H; /* stand */ 
  pika_addr[1] = (1 + 1) * PIKA_W * PIKA_H; /* walk */
  pika_addr[2] = (2 + 1) * PIKA_W * PIKA_H - PIKA_W; /* jump*/
  
  
  // sticks image
  stick_addr = VBUF_W * VBUF_H ;
  
  // ball image 
  ball_addr[0] = 3 * PIKA_W * PIKA_H +  1 * BALL_H * BALL_W - BALL_W;
  ball_addr[1] = 3 * PIKA_W * PIKA_H +  2 * BALL_H * BALL_W - BALL_W;
  ball_addr[2] = 3 * PIKA_W * PIKA_H +  3 * BALL_H * BALL_W - BALL_W;
  ball_addr[3] = 3 * PIKA_W * PIKA_H +  4 * BALL_H * BALL_W - BALL_W;
  // need declare ball_addr[1] ...
  
  // score image
  score_addr[0] = (0) * SCORE_W * SCORE_H;
  score_addr[1] = (1) * SCORE_W * SCORE_H;
  score_addr[2] = (2) * SCORE_W * SCORE_H;
  score_addr[3] = (3) * SCORE_W * SCORE_H;
  score_addr[4] = (4) * SCORE_W * SCORE_H;
  score_addr[5] = (5) * SCORE_W * SCORE_H;
  score_addr[6] = (6) * SCORE_W * SCORE_H;
  score_addr[7] = (7) * SCORE_W * SCORE_H;
  score_addr[8] = (8) * SCORE_W * SCORE_H;
  score_addr[9] = (9) * SCORE_W * SCORE_H;
  
  // duck address
  ducks_addr[0] = GAMESET_W * GAMESET_H + (0) * DUCKS_W * DUCKS_H;
  ducks_addr[1] = GAMESET_W * GAMESET_H + (1) * DUCKS_W * DUCKS_H;
end

//debounce
debounce debounced0(.clk(clk),
                    .btn_input(usr_btn[0]),
                    .btn_output(btn_level[0]));
debounce debounced1(.clk(clk),
                    .btn_input(usr_btn[1]),
                    .btn_output(btn_level[1]));
debounce debounced2(.clk(clk),
                    .btn_input(usr_btn[2]),
                    .btn_output(btn_level[2]));
debounce debounced3(.clk(clk),
                    .btn_input(usr_btn[3]),
                    .btn_output(btn_level[3]));  

// Instiantiate the VGA sync signal generator
vga_sync vs0(
  .clk(vga_clk), .reset(~reset_n), .oHS(VGA_HSYNC), .oVS(VGA_VSYNC),
  .visible(video_on), .p_tick(pixel_tick),
  .pixel_x(pixel_x), .pixel_y(pixel_y)
);

clk_divider#(2) clk_divider0(
  .clk(clk),
  .reset(~reset_n),
  .clk_out(vga_clk)
);

// ------------------------------------------------------------------------
// The following code describes an initialized SRAM memory block that
// stores a 320x240 12-bit seabed image, plus two 64x32 fish images.
sram #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(VBUF_W * VBUF_H + STICK_W * STICK_H ))
  ram0 (.clk(clk), .we(sram_we), .en(sram_en),
          .addr1(sram_addr_background), .data_i1(data_in), .data_o1(data_out_background),
          .addr2(sram_addr_stick),.data_i2(data_in), .data_o2(data_out_stick));  ////////////////////////////////////////////////////////////////////
          
sram_pikachus_and_ball #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(PIKA_W * PIKA_H * 3 + BALL_W * BALL_H * 4))
  ram1 (.clk(clk), .we(sram_we), .en(sram_en),
          .addr1(sram_addr_pika), .data_i1(data_in), .data_o1(data_out_pika),
          .addr2(sram_addr_ball), .data_i2(data_in), .data_o2(data_out_ball));

sram_cloud #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(CLOUD_W * CLOUD_H ))
  ram2 (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr_cloud), .data_i(data_in), .data_o(data_out_cloud));
          
sram_score #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(10 * SCORE_W * SCORE_H ))
  ram3 (.clk(clk), .we(sram_we), .en(sram_en),
          .addr1(sram_addr_score1), .data_i1(data_in), .data_o1(data_out_score1),
          .addr2(sram_addr_score2), .data_i2(data_in), .data_o2(data_out_score2));

sram_ducks #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(GAMESET_W * GAMESET_H + 2 * DUCKS_W * DUCKS_H ))
  ram4 (.clk(clk), .we(sram_we), .en(sram_en),
          .addr1(sram_addr_ducks), .data_i1(data_in), .data_o1(data_out_ducks),
          .addr2(sram_addr_gameset), .data_i2(data_in), .data_o2(data_out_gameset));
          
          
assign sram_we = &usr_btn; // In this demo, we do not write the SRAM. However, if
                             // you set 'sram_we' to 0, Vivado fails to synthesize
                             // ram0 as a BRAM -- this is a bug in Vivado.
assign sram_en = 1;          // Here, we always enable the SRAM block.
assign sram_addr_background = pixel_addr_background;
assign sram_addr_pika = pixel_addr_pika;
assign sram_addr_ball = pixel_addr_ball;
assign sram_addr_cloud = pixel_addr_cloud;
assign sram_addr_stick = pixel_addr_stick;
assign sram_addr_score1 = pixel_addr_score1;
assign sram_addr_score2 = pixel_addr_score2;
assign sram_addr_gameset = pixel_addr_gameset;
assign sram_addr_ducks = pixel_addr_ducks;

assign data_in = 12'h000; // SRAM is read-only so we tie inputs to zeros.
// End of the SRAM memory block.
// ------------------------------------------------------------------------

// VGA color pixel generator
assign {VGA_RED, VGA_GREEN, VGA_BLUE} = rgb_reg;

// ------------------------------------------------------------------------
// An animation clock for the motion of the fish, upper bits of the
// fish clock is the x position of the fish on the VGA screen.
// Note that the fish will move one screen pixel every 2^20 clock cycles,
// or 10.49 msec
// the x position of the right edge of the fish image
// in the 640x480 VGA screen

assign xpos_pika1 = pika_clock1_x[31:20];
assign xpos_pika2 = pika_clock2_x[31:20];
assign ypos_pika1 = pika_clock1_y[31:20];
assign ypos_pika2 = pika_clock2_y[31:20];

assign xpos_ball = ball_clock_x[31:20];
assign ypos_ball = ball_clock_y[31:20];

assign xpos_cloud1 = cloud_clock1[31:20];
assign xpos_cloud2 = cloud_clock2[31:20];

// score sys tem
assign pika1_get_score = (ypos_ball >= (VBUF_H - 20) * 2) && (xpos_ball >= 170*2 && xpos_ball <= 320*2);
assign pika2_get_score = (ypos_ball >= (VBUF_H - 20) * 2) && (xpos_ball >= 0 && xpos_ball <= 150*2);

assign xpos_ducks = ducks_clock_x[31:20];
assign ypos_ducks = ducks_clock_y[31:20];

always@(*)begin
    P_next = 0;
    case(P)
        0:begin
            if (btn_pressed[3] == 1 && score_pika1 != 9 && score_pika2 != 9)begin
                P_next = 1;
            end
            else begin
                P_next = 0;
            end
        end
        1:begin
            if ((pika1_get_score || pika2_get_score))begin
                P_next = 0;
            end
            else begin
                P_next = 1;
            end
        end
    endcase
end

always@(posedge clk)begin
    if (~reset_n)begin
        P <= 0;
    end
    else begin
        P <= P_next;
    end
end

always @(posedge clk) begin
    if (~reset_n) begin
        score_pika1 <= 0;
        score_pika2 <= 0;
    end
    else begin
        if(pika1_get_score && score_pika1 < 9) score_pika1 <= score_pika1 + 1;
        else if(pika1_get_score && score_pika1 == 9) score_pika1 <= 0;
        if(pika2_get_score && score_pika2 < 9) score_pika2 <= score_pika2 + 1;
        else if(pika2_get_score && score_pika2 == 9) score_pika2 <= 0;
    end
end

// sync input
always @(posedge clk) begin
  if (~reset_n)
    prev_btn_level[0] <= 1'b0;
  else
    prev_btn_level[0] <= btn_level[0];
end

assign btn_pressed[0] = (btn_level[0] & ~prev_btn_level[0]); // btn_pressed is a 1 clock signal by debounced             

always @(posedge clk) begin
  if (~reset_n)
    prev_btn_level[1] <= 1'b0;
  else
    prev_btn_level[1] <= btn_level[1];
end

assign btn_pressed[1] = (btn_level[1] & ~prev_btn_level[1]); // btn_pressed is a 1 clock signal by debounced           

always @(posedge clk) begin
  if (~reset_n)
    prev_btn_level[2] <= 1'b0;
  else
    prev_btn_level[2] <= btn_level[2];
end

assign btn_pressed[2] = (btn_level[2] & ~prev_btn_level[2]); // btn_pressed is a 1 clock signal by debounced           

always @(posedge clk) begin
  if (~reset_n)
    prev_btn_level[3] <= 1'b0;
  else
    prev_btn_level[3] <= btn_level[3];
end

assign btn_pressed[3] = (btn_level[3] & ~prev_btn_level[3]); // btn_pressed is a 1 clock signal by debounced           

/////


always @(posedge clk) begin
  
  if (~reset_n )begin
    pika_clock1_x <= {12'd120,20'd0};
  end
  
  if (usr_sw[1] == 0)begin
      if (xpos_ball <= VBUF_W)begin//////////////////////////////
        if (xpos_ball > xpos_pika1)begin
          pika_clock1_x <= pika_clock1_x + 3;
        end
        else if (xpos_ball == xpos_pika1)begin
          pika_clock1_x <= pika_clock1_x;
        end
        else if (xpos_ball < xpos_pika1)begin
          pika_clock1_x <= pika_clock1_x - 3;
        end
      end
      else if (xpos_ball > VBUF_W)begin
        if (xpos_pika1 > 185)begin
          pika_clock1_x <= pika_clock1_x - 3;
        end
        else if (xpos_pika1 == 185)begin
          pika_clock1_x <= pika_clock1_x;
        end
        else if (xpos_pika1 < 185)begin
          pika_clock1_x <= pika_clock1_x + 3;
        end
      end//////////////////////////////////////////////////////////////////////
  end
  else if (usr_sw[1] == 1)begin
      if (xpos_ball <= VBUF_W)begin//////////////////////////////
        if (xpos_ball > xpos_pika1)begin
          pika_clock1_x <= pika_clock1_x + 8;
        end
        else if (xpos_ball == xpos_pika1)begin
          pika_clock1_x <= pika_clock1_x;
        end
        else if (xpos_ball < xpos_pika1)begin
          pika_clock1_x <= pika_clock1_x - 8;
        end
      end
      else if (xpos_ball > VBUF_W)begin
        if (xpos_pika1 > 185)begin
          pika_clock1_x <= pika_clock1_x - 8;
        end
        else if (xpos_pika1 == 185)begin
          pika_clock1_x <= pika_clock1_x;
        end
        else if (xpos_pika1 < 185)begin
          pika_clock1_x <= pika_clock1_x + 8;
        end
      end//////////////////////////////////////////////////////////////////////
  end
  
end

reg is_first_time;
always@(posedge clk)begin
    if (~reset_n)begin
        is_first_time <= 1;
    end
    else if (ball_region && pika_region1 && !pika_jumping1)begin
        is_first_time <= 0;
    end
    else if (ball_region && pika_region1 && pika_jumping1)begin
        is_first_time <= 1;
    end
end

always @(posedge clk) begin
  if (~reset_n )begin
    pika_clock1_y <= {12'd434,20'd0};
  end
  else if (pika_jumping1 == 1 )begin
    pika_clock1_y <= pika_clock1_y - pika_positive_speed_clock1_y[33:22] + pika_negative_speed_clock1_y[33:22]; 
  end
  else if (pika_jumping1 == 0)begin
    pika_clock1_y <= {12'd434,20'd0}; // may not be here without this branch
  end
end

// pika_positive_speed  1
always@(posedge clk)begin
    if (~reset_n)begin
        pika_positive_speed_clock1_y <= 0;
        pika_negative_speed_clock1_y <= 0;
        pika_jumping1 <= 0;
    end
    else if (pika_jumping1 == 0 && is_first_time == 0)begin
        pika_positive_speed_clock1_y <= {12'd10,22'd0};
        pika_jumping1 <= 1;
    end
    else if (pika_jumping1 == 1 && pika_positive_speed_clock1_y  > 0)begin
        pika_positive_speed_clock1_y <= pika_positive_speed_clock1_y - 1;
    end
    else if (pika_jumping1 == 1 && pika_positive_speed_clock1_y == 0 && pika_negative_speed_clock1_y  < {12'd10,22'd0})begin
        pika_negative_speed_clock1_y <= pika_negative_speed_clock1_y + 1;
    end
    else if (pika_jumping1 == 1 && pika_negative_speed_clock1_y == {12'd10,22'd0})begin
        pika_negative_speed_clock1_y <= 0;
        pika_jumping1 <= 0;
    end
    else if (pika_jumping1 == 0 )begin
        pika_positive_speed_clock1_y <= 0;
        pika_negative_speed_clock1_y <= 0;
    end
    
end


always @(posedge clk) begin
  if (~reset_n )begin
    pika_clock2_y <= {12'd434,20'd0};
  end
  else if (pika_jumping2 == 1)begin
    pika_clock2_y <= pika_clock2_y - pika_positive_speed_clock2_y[33:22] + pika_negative_speed_clock2_y[33:22];  
  end
  else if (pika_jumping2 == 0)begin
    pika_clock2_y <= {12'd434,20'd0}; // may not be here without this branch
  end
end

// pika_positive_speed  2
always@(posedge clk)begin
    if (~reset_n)begin
        pika_positive_speed_clock2_y <= 0;
        pika_negative_speed_clock2_y <= 0;
        pika_jumping2 <= 0;
    end
    else if (pika_jumping2 == 0 && btn_pressed[2] == 1)begin
        pika_positive_speed_clock2_y <= {12'd10,22'd0};
        pika_jumping2 <= 1;
    end
    else if (pika_jumping2 == 1 && pika_positive_speed_clock2_y  > 0)begin
        pika_positive_speed_clock2_y <= pika_positive_speed_clock2_y - 1;
    end
    else if (pika_jumping2 == 1 && pika_positive_speed_clock2_y == 0 && pika_negative_speed_clock2_y  < {12'd10,22'd0})begin
        pika_negative_speed_clock2_y <= pika_negative_speed_clock2_y + 1;
    end
    else if (pika_jumping2 == 1 && pika_negative_speed_clock2_y == {12'd10,22'd0})begin
        pika_negative_speed_clock2_y <= 0;
        pika_jumping2 <= 0;
    end
    else if (pika_jumping2 == 0 )begin
        pika_positive_speed_clock2_y <= 0;
        pika_negative_speed_clock2_y <= 0;
    end
    
end

always @(posedge clk) begin
  if (~reset_n )begin
    pika_clock2_x <= {12'd630,20'd0};
  end
  else if (btn_level[0] == 1 && pika_clock2_x [31:20] <= VBUF_W * 2)begin
    pika_clock2_x <= pika_clock2_x + 3;
  end
  else if (btn_level[1] == 1 && pika_clock2_x [31:20] >= VBUF_W + STICK_W + PIKA_W * 2)begin
    pika_clock2_x <= pika_clock2_x - 3;
  end
  
end

always@(posedge clk)begin
    if (~reset_n)begin
        ball_clock_x <= {12'd600,20'd0};
    end
    else if(pika1_get_score) begin // then pika1 serves the ball
        ball_clock_x <= {12'd80,20'd0};
    end
    else if(pika2_get_score) begin
        ball_clock_x <= {12'd600,20'd0};
    end
    else begin
        ball_clock_x <= ball_clock_x + ball_right_speed_clock_x[33:22] - ball_left_speed_clock_x[33:22] + wind_right_speed - wind_left_speed;
    end
end

// make sure that speed_x and speed_y can only be one non-zero
always@(posedge clk)begin
    if (~reset_n)begin
        ball_right_speed_clock_x <= 0;
        ball_left_speed_clock_x <= 0;
    end
    else if (P == 0)begin
        ball_right_speed_clock_x <= 0;
        ball_left_speed_clock_x <= 0;
    end
    else if (ypos_ball == VBUF_H * 2)begin
        ball_right_speed_clock_x <= 0;
        ball_left_speed_clock_x <= 0;
    end
    else if ((ball_region && pika_region1 && !pika_jumping1) || (ball_region && pika_region2 && !pika_jumping2))begin
        ball_right_speed_clock_x <= 0;
        ball_left_speed_clock_x <= 0;
    end
    else if ((ball_region && pika_region2 && pika_jumping2 && btn_level[3] == 1))begin
        ball_left_speed_clock_x <= {12'd15,22'd0};
        ball_right_speed_clock_x <= 0;
    end
    else if ((ball_region && pika_region1 && pika_jumping1))begin
        ball_right_speed_clock_x <= {12'd7,22'd0};
        ball_left_speed_clock_x <= 0;
    end
    else if ((ball_region && pika_region2 && pika_jumping2))begin
        ball_left_speed_clock_x <= {12'd7,22'd0};
        ball_right_speed_clock_x <= 0;
    end
    else if (xpos_ball >= VBUF_W * 2)begin
        ball_right_speed_clock_x <= 0;
        ball_left_speed_clock_x <= {12'd7,22'd0};
    end
    else if (xpos_ball - BALL_W * 2 <= 0)begin
        ball_right_speed_clock_x <= {12'd7,22'd0};
        ball_left_speed_clock_x <= 0;
    end
    else if (ball_region && stick_region)begin
        if (xpos_ball - BALL_W < VBUF_MID - 2 * STICK_W)begin
            ball_right_speed_clock_x <= 0;
            ball_left_speed_clock_x <= {12'd7,22'd0};
        end
        else if (xpos_ball - BALL_W > VBUF_MID)begin
            ball_right_speed_clock_x <= {12'd7,22'd0};
            ball_left_speed_clock_x <= 0;
        end
        else begin // hold the speed
            ball_right_speed_clock_x <= ball_right_speed_clock_x;
            ball_left_speed_clock_x <= ball_left_speed_clock_x;
        end
    end
    else if (ball_region && ducks_region)begin
        if (xpos_ball - BALL_W < xpos_ducks - 2 * DUCKS_W)begin
            ball_right_speed_clock_x <= 0;
            ball_left_speed_clock_x <= {12'd7,22'd0};
        end
        else if (xpos_ball - BALL_W > xpos_ducks)begin
            ball_right_speed_clock_x <= {12'd7,22'd0};
            ball_left_speed_clock_x <= 0;
        end
        else begin // hold the speed
            ball_right_speed_clock_x <= ball_right_speed_clock_x;
            ball_left_speed_clock_x <= ball_left_speed_clock_x;
        end
    end
end

always@(posedge clk)begin
    // just for debug
    if (~reset_n)begin
        ball_clock_y <= {12'd50,20'd0};
    end
    else if (pika1_get_score || pika2_get_score)begin
        ball_clock_y <= {12'd50,20'd0};
    end
    else begin
        ball_clock_y <= ball_clock_y - ball_positive_speed_clock_y[33:22] + ball_negative_speed_clock_y[33:22];
    end
    
  /*
    if (~reset_n)begin
        ball_clock_y <= {11'd60,21'd0};
    end
    else begin
        ball_clock_y <= ball_clock_y - ball_positive_speed_clock_y[33:22] + ball_negative_speed_clock_y[33:22];
    end
    */
end

always@(posedge clk)begin
    if (~reset_n)begin
        ball_positive_speed_clock_y <= 0;
        ball_negative_speed_clock_y <= 0;
    end
    else if (P == 0)begin
        ball_positive_speed_clock_y <= 0;
        ball_negative_speed_clock_y <= 0;
    end
    else if (ypos_ball >= (VBUF_H - 20) * 2)begin
        ball_positive_speed_clock_y <= 0;
        ball_negative_speed_clock_y <= 0;
    end
    else if (ypos_ball <= BALL_H * 2)begin
        if (ball_positive_speed_clock_y != 0)begin
            ball_positive_speed_clock_y <= 0;
            ball_negative_speed_clock_y <= ball_positive_speed_clock_y ;
        end
    end
    else if ((ball_region && pika_region2 && pika_jumping2 ) && btn_level[3] == 1)begin  // condition may failed for PIKA_H * 2 - 1?
        ball_negative_speed_clock_y <= {12'd3,22'd0};  //////  set peremeter 5 
        ball_positive_speed_clock_y <= 0;
    end
    else if ((ball_region && pika_region1 && ypos_ball <= ypos_pika1 - PIKA_H ) || (ball_region && pika_region2 && ypos_ball <= ypos_pika2 - PIKA_H))begin  // condition may failed for PIKA_H * 2 - 1?
        ball_negative_speed_clock_y <= 0;
        ball_positive_speed_clock_y <= {12'd10,22'd0};
    end
    //(ball_region && pika_region1 && (ypos_ball <= ypos_pika1 - PIKA_H) && pika_jumping1) || 
    else if (ball_positive_speed_clock_y != 0)begin
        ball_positive_speed_clock_y <= ball_positive_speed_clock_y - 1;
        ball_negative_speed_clock_y <= 0;
    end
    else begin
        ball_positive_speed_clock_y <= 0;
        ball_negative_speed_clock_y <= ball_negative_speed_clock_y + 1;
    end
    
    if (ball_region && stick_region && xpos_ball - BALL_W <= VBUF_MID && xpos_ball - BALL_W >= VBUF_MID - 2 * STICK_W)begin
        ball_positive_speed_clock_y <= ball_negative_speed_clock_y;
        ball_negative_speed_clock_y <= 0;
    end
    else if (ball_region && ducks_region && xpos_ball - BALL_W <= xpos_ducks && xpos_ball - BALL_W >= xpos_ducks - 2 * DUCKS_W)begin
        if (ypos_ball - BALL_H < ypos_ducks - 2 * DUCKS_H)begin
            ball_positive_speed_clock_y <= {12'd4,22'd0};
            ball_negative_speed_clock_y <= 0;
        end
        else if (ypos_ball - BALL_H > ypos_ducks)begin
            ball_positive_speed_clock_y <= 0;
            ball_negative_speed_clock_y <= {12'd4,22'd0};
        end
        else begin // hold the speed
            ball_positive_speed_clock_y <= ball_negative_speed_clock_y;
            ball_negative_speed_clock_y <= ball_negative_speed_clock_y;
        end
    end
end


always @(posedge clk) begin
  if (~reset_n )begin
    cloud_clock1 <= {11'd480,20'd0};
  end
  else begin
    cloud_clock1 <= cloud_clock1 + (wind_right_speed != 0 ? (wind_right_speed - 1) : 0) - (wind_left_speed != 0 ? (wind_left_speed - 1) : 0);
    if (cloud_clock1 >= { VBUF_W * 2 + CLOUD_W * 2,20'd0 })begin
        cloud_clock1 <= { 11'd0 , 20'd0 };
    end
  end
end

always @(posedge clk) begin
  if (~reset_n )begin
    cloud_clock2 <= {11'd240,20'd0};
  end
  else begin
    cloud_clock2 <= cloud_clock2 + (wind_right_speed != 0 ? (wind_right_speed - 1) : 0) - (wind_left_speed != 0 ? (wind_left_speed - 1) : 0);
    if (cloud_clock2 >= { VBUF_W * 2 + CLOUD_W * 2,20'd0 })begin
        cloud_clock2 <= { 11'd0 , 20'd0 };
    end
  end
end

always@(posedge clk)begin
    if (~reset_n)begin
        pika_animation_clock <= 0;
    end
    else if (pika_animation_clock[26] == 1)begin
        pika_animation_clock <= 0;
    end
    else begin
        pika_animation_clock <= pika_animation_clock + 1;
    end
end

always@(posedge clk)begin
    if (~reset_n || P == 0)begin
        ball_animation_clock <= 0;
        ball_animation_index <= 0;
    end
    else if (ball_animation_clock[25] == 1)begin
        ball_animation_clock <= 0;
        if (ball_animation_index < 2)begin
            ball_animation_index <= ball_animation_index + 1;
        end
        else begin
            ball_animation_index <= 0;
        end
    end
    else begin
        ball_animation_clock <= ball_animation_clock + 1;
    end
end

// ------------------------------------------------------------------------
// ducks
always@(posedge clk)begin
    if (~reset_n || usr_sw[3] == 0)begin
        ducks_clock_x <= 0;
    end
    else begin
       ducks_clock_x <= ducks_clock_x + 1;
    end
end
// ------------------------------------------------------------------------

always@(posedge clk)begin
    if (~reset_n)begin
        ducks_clock_y <= {11'd120,20'd0};
    end
    else begin
        ducks_clock_y <= {11'd120,20'd0};
    end
end

// End of the animation clock code.
// ------------------------------------------------------------------------

// ------------------------------------------------------------------------
// Video frame buffer address generation unit (AGU) with scaling control
// Note that the width x height of the fish image is 64x32, when scaled-up
// on the screen, it becomes 128x64. 'pos' specifies the right edge of the
// fish image.
assign pika_region1 =
           (pixel_y + (PIKA_H * 2 - 1)) >= ypos_pika1 && pixel_y < ypos_pika1 + 1 &&
           (pixel_x + (PIKA_W * 2 - 1)) >= xpos_pika1 && pixel_x < xpos_pika1 + 1;
           
assign pika_region2 =
           (pixel_y + (PIKA_H * 2 - 1)) >= ypos_pika2 && pixel_y < ypos_pika2 + 1 &&
           (pixel_x + (PIKA_W * 2 - 1)) >= xpos_pika2 && pixel_x < xpos_pika2 + 1;

assign stick_region =
           pixel_y >= 2 * (141 - stick_adjust) && pixel_y < 442 &&
           (pixel_x + (STICK_W * 2 - 1)) >= VBUF_MID && pixel_x < VBUF_MID + 1;

assign ball_region = 
           (pixel_y + (BALL_H * 2 - 1)) >= ypos_ball && pixel_y < ypos_ball + 1 &&
           (pixel_x + (BALL_W * 2 - 1)) >= xpos_ball && pixel_x < xpos_ball + 1;

assign cloud_region1 = 
           pixel_y >= (CLOUD_VPOS1<<1) && pixel_y < (CLOUD_VPOS1 + CLOUD_H)<<1 &&
           (pixel_x + (CLOUD_W * 2 - 1)) >= xpos_cloud1 && pixel_x < xpos_cloud1 + 1;
           
assign cloud_region2 = 
           pixel_y >= (CLOUD_VPOS2<<1) && pixel_y < (CLOUD_VPOS2 + CLOUD_H)<<1 &&
           (pixel_x + (CLOUD_W * 2 - 1)) >= xpos_cloud2 && pixel_x < xpos_cloud2 + 1;
assign ducks_region = 
           pixel_y >= (DUCKS_VPOS<<1) && pixel_y < (DUCKS_VPOS + DUCKS_H)<<1 &&
           (pixel_x + (DUCKS_W * 2 - 1)) >= xpos_ducks && pixel_x < xpos_ducks + 1;
assign score_region1 = 
           pixel_y >= (6'd40<<1) && pixel_y < (6'd40 + SCORE_H)<<1 &&
           (pixel_x + (SCORE_W * 2 - 1)) >= 7'd100 && pixel_x < 7'd100 + 1;
assign score_region2 = 
           pixel_y >= (6'd40<<1) && pixel_y < (6'd40 + SCORE_H)<<1 &&
           (pixel_x + (SCORE_W * 2 - 1)) >= 10'd600 && pixel_x < 10'd600 + 1;
assign gameset_region = 
           (score_pika1 == 9 || score_pika2 == 9) ? (
           pixel_y >= (GAMESET_VPOS << 1) && pixel_y < (GAMESET_VPOS + GAMESET_H)<<1 &&
           (pixel_x + (GAMESET_W * 2) - 1) >= GAMESET_XPOS && pixel_x < (GAMESET_XPOS) + 1
           ):(
           0
           );
           
always @ (posedge clk) begin
  if (~reset_n) begin
    pixel_addr_background <= 0;
  end
  else begin
    pixel_addr_background <= (pixel_y >> 1) * VBUF_W + (pixel_x >> 1);
  end
end

always@(posedge clk)begin
    if (~reset_n)begin
        pixel_addr_stick <= 0;
    end
    else begin
        pixel_addr_stick <=  stick_addr + 
          ((pixel_y>>1)-(141 - stick_adjust))*STICK_W +
          ((pixel_x +(STICK_W*2-1)-VBUF_MID)>>1);
    end
end

always@(posedge clk)begin
    if (~reset_n)begin
        pixel_addr_score1 <= 0;
        pixel_addr_score2 <= 0;
    end
    else begin // NOT SURE LOCATION
        pixel_addr_score1 <=  score_addr[score_pika1] + 
          ((pixel_y>>1)- 6'd40)*SCORE_W +
          ((pixel_x +(SCORE_W*2-1)- 7'd100)>>1);
        pixel_addr_score2 <=  score_addr[score_pika2] + 
          ((pixel_y>>1)- 6'd40)*SCORE_W +
          ((pixel_x +(SCORE_W*2-1)- 10'd600)>>1);
    end
end

always@(posedge clk)begin
    if (~reset_n)begin
        pixel_addr_pika <= 0;
    end
    else if (pika_region1)begin
        pixel_addr_pika <= (pika_jumping1 == 1 ? pika_addr[2] : pika_addr[pika_animation_clock[24]] )+
                  ((pixel_y - ypos_pika1) >> 1 )*PIKA_W +
                  ((pixel_x +(PIKA_W*2-1)-xpos_pika1)>>1);
    end
    else if (pika_region2 )begin
        pixel_addr_pika <= (pika_jumping2 == 1 ? pika_addr[2] : pika_addr[pika_animation_clock[24]] )+
                  ((pixel_y -ypos_pika2) >> 1 )*PIKA_W +
                  ((PIKA_W*2-1) - (pixel_x +(PIKA_W*2-1)-xpos_pika2)>>1);
    end
    
end

always@(posedge clk)begin
    if (~reset_n)begin
        pixel_addr_ball <= 0;
    end
    else if (ball_region && killing_ball == 0)begin
        pixel_addr_ball <= ball_addr[ball_animation_index] +   // 0 now but change future
                  ((pixel_y - ypos_ball ) >> 1) *BALL_W +
                  ((pixel_x +(BALL_W*2-1)-xpos_ball)>>1);
    end
    else if (ball_region && killing_ball == 1)begin
        pixel_addr_ball <= ball_addr[3] +   // 0 now but change future
                  ((pixel_y - ypos_ball ) >> 1) *BALL_W +
                  ((pixel_x +(BALL_W*2-1)-xpos_ball)>>1);
    end
end

always@(posedge clk)begin
    if (~reset_n)begin
        pixel_addr_cloud <= 0;
    end
    else if (cloud_region1)begin
        pixel_addr_cloud <= 18'd0 +   // 0 now but change future
                  ((pixel_y>>1)-CLOUD_VPOS1)*CLOUD_W +
                  ((pixel_x +(CLOUD_W*2-1)-xpos_cloud1)>>1);
    end
    else if (cloud_region2)begin
        pixel_addr_cloud <= 18'd0 +   // 0 now but change future
                  ((pixel_y>>1)-CLOUD_VPOS2)*CLOUD_W +
                  ((pixel_x +(CLOUD_W*2-1)-xpos_cloud2)>>1);
    end
end

always@(posedge clk)begin
    if (~reset_n)begin
        pixel_addr_gameset <= 0;
    end
    else if (gameset_region )begin
        pixel_addr_gameset <= 18'd0 +   // 0 now but change future
                  ((pixel_y>>1)-GAMESET_VPOS)*GAMESET_W +
                  ((pixel_x +(GAMESET_W*2-1)-GAMESET_XPOS )>>1);
    end

end
always@(posedge clk)begin
    if (~reset_n)begin
        pixel_addr_ducks <= 0;
    end
    else if (ducks_region )begin
        pixel_addr_ducks <= ducks_addr[1] +   
                  ((pixel_y >> 1) - DUCKS_VPOS ) *DUCKS_W +
                  ((pixel_x +(DUCKS_W*2-1)-xpos_ducks)>>1);
    end
end
// End of the AGU code.
// ------------------------------------------------------------------------
// sw[0] --> wind

always@(posedge clk)begin
    if (~reset_n || usr_sw[0] == 0 || P == 0)begin
        wind_clock <= 0;
        wind_blow_direction <= 0; // no_wind
    end
    else if (wind_blow_direction == 0 && wind_clock < 450000000)begin
        wind_clock <= wind_clock + 1;
    end
    else if (wind_blow_direction == 0 && wind_clock == 450000000)begin
        wind_clock <= 0;
        wind_blow_direction <= 1; // wind_right 
    end
    else if (wind_blow_direction == 1 && wind_clock < 90000000)begin
        wind_clock <= wind_clock + 1;
    end
    else if (wind_blow_direction == 1 && wind_clock == 90000000)begin
        wind_clock <= 0;
        wind_blow_direction <= 2; // no_wind
    end
    else if (wind_blow_direction == 2 && wind_clock < 350000000)begin
        wind_clock <= wind_clock + 1;
    end
    else if (wind_blow_direction == 2 && wind_clock == 350000000)begin
        wind_clock <= 0;
        wind_blow_direction <= 3;
    end
    else if (wind_blow_direction == 3 && wind_clock < 90000000)begin
        wind_clock <= wind_clock + 1;
    end
    else if (wind_blow_direction == 3 && wind_clock == 90000000)begin
        wind_clock <= 0;
        wind_blow_direction <= 0;
    end
end
/*
always@(posedge clk)begin
    if (~reset_n || usr_sw[0] == 0)begin
        wind_shift_counter <= 0;
    end
    else if ((wind_blow_direction == 1 || wind_blow_direction == 3) && wind_shift_counter < 2)begin
        wind_shift_counter <= wind_shift_counter + 1;
    end
    else if ((wind_blow_direction == 1 || wind_blow_direction == 3) && wind_shift_counter == 2)begin
        wind_shift_counter <= 0;
    end
    else begin
        wind_shift_counter <= 0;
    end
end
*/

assign wind_right_speed = (wind_blow_direction == 1 && P == 1) ? 2 : 0;
assign wind_left_speed = (wind_blow_direction == 3 && P == 1) ? 2 : 0;

// ------------------------------------------------------------------------
always@(posedge clk)begin
    if (~reset_n)begin
        killing_ball <= 0;
    end
    else if (ball_region && pika_region2 && btn_level[3] == 1 && pika_jumping2 )begin
        killing_ball <= 1;
    end
    else if (ball_region && pika_region1)begin
        killing_ball <= 0;
    end
    else if (pika1_get_score == 1)begin
        killing_ball <= 0;
    end
end

// ------------------------------------------------------------------------

always@(posedge clk)begin
    if (~reset_n || usr_sw[2] == 0)begin
        stick_adjust <= 0;
        stick_counter <= 0;
        stick_clock <= 0;
        stick_smooth_clock <= 0;
    end
    else begin
        stick_clock <= (stick_clock >= 99999999) ? 0 : stick_clock + 1;
        stick_smooth_clock <= (stick_smooth_clock >= 1700000) ? 0 : stick_smooth_clock + 1;
        stick_adjust <= (stick_counter == 0) ? ((stick_adjust < 31) ? ((stick_smooth_clock == 1700000) ? stick_adjust + 1 : stick_adjust) : stick_adjust) : ((stick_counter == 8) ? ((stick_adjust > 0) ? ((stick_smooth_clock == 1700000) ? stick_adjust - 1 : stick_adjust) : stick_adjust) : stick_adjust);
        stick_counter <= (stick_clock == 99999999) ? ((stick_counter >= 15) ? 0 : stick_counter + 1) : stick_counter;
    end
end
// ------------------------------------------------------------------------
// Send the video data in the sram to the VGA controller
always @(posedge clk) begin
  if (pixel_tick) rgb_reg <= rgb_next;
end

always@(posedge clk)begin
    if (~reset_n)begin
        color_rage <= 0;
    end
    else if (color_rage < 15)begin
        color_rage <= color_rage + 1;
    end
    else begin
        color_rage <= 0;
    end
end

always @(*) begin
    rgb_next = 12'h000;
  if (~video_on) begin
    rgb_next = 12'h000; // Synchronization period, must set RGB values to zero.
  end
  else if (gameset_region )begin
    if (data_out_gameset != 12'h0f0)begin
        rgb_next = data_out_gameset ;
    end
    else begin
        rgb_next = data_out_background;
    end
  end
  else if (score_region1)begin
    if (data_out_score1 != 12'h0f0)begin
        rgb_next = data_out_score1;
    end
    else begin
        if (ball_region )begin
            if (data_out_ball != 12'h0f0)begin
                rgb_next = data_out_ball;
            end
            else begin
                if (cloud_region1 || cloud_region2 )begin
                    if (data_out_cloud != 12'h0f0)begin
                        rgb_next = data_out_cloud;
                    end
                    else begin
                        rgb_next = data_out_background ;
                    end
                end
                else begin
                    rgb_next = data_out_background ;
                end
            end
        end
        else if (cloud_region1 || cloud_region2 )begin
             if (data_out_cloud != 12'h0f0)begin
                rgb_next = data_out_cloud ;
             end
             else begin
                rgb_next = data_out_background ;
             end
        end
        else begin
            rgb_next = data_out_background ;
        end
    end
  end
  else if (ducks_region )begin
    if (data_out_ducks != 12'h0f0)begin
        rgb_next = data_out_ducks;
    end
    else begin
        if (pika_region1 || pika_region2)begin
            if (data_out_pika != 12'h0f0)begin
                rgb_next = data_out_pika;
            end
            else begin
                rgb_next = data_out_background ;
            end
        end
        else begin
            rgb_next = data_out_background ;
        end
    end
  end
  else if (score_region2)begin
    if (data_out_score2 != 12'h0f0)begin
        rgb_next = data_out_score2;
    end
    else begin
        if (ball_region )begin
            if (data_out_ball != 12'h0f0)begin
                rgb_next = data_out_ball;
            end
            else begin
                if (cloud_region1 || cloud_region2 )begin
                    if (data_out_cloud != 12'h0f0)begin
                        rgb_next = data_out_cloud;
                    end
                    else begin
                        rgb_next = data_out_background ;
                    end
                end
                else begin
                    rgb_next = data_out_background ;
                end
            end
        end
        else if (cloud_region1 || cloud_region2 )begin
             if (data_out_cloud != 12'h0f0)begin
                rgb_next = data_out_cloud ;
             end
             else begin
                rgb_next = data_out_background ;
             end
        end
        else begin
            rgb_next = data_out_background ;
        end
    end
  end
  else if (ball_region )begin
    if (data_out_ball != 12'h0f0)begin
        rgb_next = data_out_ball;
    end
    else begin
        if (stick_region)begin
            if (data_out_stick != 12'h0f0)begin
                rgb_next = data_out_stick ;
            end
            else begin
                if (cloud_region1 || cloud_region2)begin
                    if (data_out_cloud != 12'h0f0)begin
                        rgb_next = data_out_cloud ;
                    end
                    else begin
                        rgb_next = data_out_background ;
                    end
                end
                else begin
                    rgb_next = data_out_background ;
                end
            end
        end
        else begin
            if (cloud_region1 || cloud_region2)begin
                if (data_out_cloud != 12'h0f0)begin
                    rgb_next = data_out_cloud ;
                end
                else begin
                    rgb_next = data_out_background ;
                end
            end
            else begin
                rgb_next = data_out_background ;
            end
        end
    end
  end
  else if (pika_region1)begin
    if (usr_sw[1] == 0)begin
        if (data_out_pika != 12'h0f0)begin
            rgb_next = data_out_pika;
        end
        else begin
            rgb_next = data_out_background ;
        end
    end
    else if (usr_sw[1] == 1)begin
        if (data_out_pika != 12'h0f0)begin
            rgb_next = data_out_pika + {color_rage ,color_rage,color_rage} ;
        end
        else begin
            rgb_next = data_out_background ;
        end
    end
  end
  else if (pika_region2)begin
    if (data_out_pika != 12'h0f0)begin
        rgb_next = data_out_pika;
    end
    else begin
        rgb_next = data_out_background ;
    end
  end
  else if (stick_region )begin
    if (data_out_stick != 12'h0f0)begin
        rgb_next = data_out_stick ;
    end
    else begin
        if (cloud_region1 || cloud_region2)begin
            if (data_out_cloud != 12'h0f0)begin
                rgb_next = data_out_cloud ;
            end
            else begin
                rgb_next = data_out_background ;
            end
        end
        else begin
            rgb_next = data_out_background ;
        end
    end
  end
  else if (cloud_region1 || cloud_clock2 )begin
    if (data_out_cloud != 12'h0f0)begin
        rgb_next = data_out_cloud;
    end
    else begin
        rgb_next = data_out_background ;
    end
  end
  else begin
    rgb_next = data_out_background ; // RGB value at (pixel_x, pixel_y)
  end
end
// End of the video data display code.
// ------------------------------------------------------------------------

endmodule
