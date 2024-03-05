`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Dept. of Computer Science, National Chiao Tung University
// Engineer: Chun-Jen Tsai
//
// Create Date: 2018/11/01 11:16:50
// Design Name:
// Module Name: lab6
// Project Name:
// Target Devices:
// Tool Versions:
// Description: This is a sample circuit to show you how to initialize an SRAM
//              with a pre-defined data file. Hit BTN0/BTN1 let you browse
//              through the data.
//
// Dependencies: LCD_module, debounce
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

module lab7(
  // General system I/O ports
  input  clk,
  input  reset_n,
  input  [3:0] usr_btn,
  output [3:0] usr_led,

  // 1602 LCD Module Interface
//  output LCD_RS,
//  output LCD_RW,
//  output LCD_E,
//  output [3:0] LCD_D,

  input  uart_rx,
  output uart_tx
);

//localparam [1:0] S_MAIN_ADDR = 3'b000, S_MAIN_READ = 3'b001,
//                 S_MAIN_SHOW = 3'b010, S_MAIN_WAIT = 3'b011; // for P
localparam [1:0] S_UART_IDLE = 0, S_UART_WAIT = 1,
                 S_UART_SEND = 2, S_UART_INCR = 3; // for Q
localparam [2:0] S_MULT_GET = 3'b000, S_MULT_MUL = 3'b001,
				S_MULT_REPLY = 3'b010, S_MULT_RESEC = 3'b011,
				S_MULT_WAIT = 3'b100, S_MULT_ADDR = 3'b101; // for R
//localparam REPLY_LEN = 169; // 40 + 32*4 + 1
localparam FIR_LEN = 41;
localparam SEC_LEN = 33;

// declare system variables
//wire [1:0]  btn_level, btn_pressed;
//reg  [1:0]  prev_btn_level;
//reg  [1:0]  P, P_next;
reg  [1:0]  Q, Q_next;
reg  [2:0]  R, R_next;
//reg  [11:0] user_addr;
//reg  [7:0]  user_data;

wire print_enable, print_done;
//reg [$clog2(REPLY_LEN):0] send_counter;
//reg [7:0] data[0:REPLY_LEN-1];
//reg  [0:REPLY_LEN*8-1] msg = { {"\015\012The matrix multiplication result is:\015\012"},
// {"[ xxxxx, xxxxx, xxxxx, xxxxx ]\015\012"},
// {"[ xxxxx, xxxxx, xxxxx, xxxxx ]\015\012"},
// {"[ xxxxx, xxxxx, xxxxx, xxxxx ]\015\012"},
// {"[ xxxxx, xxxxx, xxxxx, xxxxx ]\015\012"}, 8'h00 };
reg  [$clog2(FIR_LEN+SEC_LEN):0] send_counter;
reg [7:0] data[0: FIR_LEN + SEC_LEN -1];
reg  [0:FIR_LEN*8-1] msg_fir = {"\015\012The matrix multiplication result is:\015\012", 8'h00};
reg  [0:SEC_LEN*8-1] msg_sec = { "[ xxxxx, xxxxx, xxxxx, xxxxx ]\015\012", 8'h00 };

// SRAM variables for matrix multiply
wire [11:0] mult_sram_addr;
wire [11:0] mult_sec_addr;
wire mult_sram_en;
wire [7:0] mult_sram_out;
wire [7:0] mult_sec_out;

reg [18-1:0] C_mat [0:3] [0:3];

// LCD output
//reg  [127:0] row_A, row_B;

// declare SRAM control signals
//wire [11:0] sram_addr;
wire [7:0]  data_in;
//wire [7:0]  data_out;
wire        sram_we;
//wire		sram_en;

assign usr_led = 4'h00;

//LCD_module lcd0(
//  .clk(clk),
//  .reset(~reset_n),
//  .row_A(row_A),
//  .row_B(row_B),
//  .LCD_E(LCD_E),
//  .LCD_RS(LCD_RS),
//  .LCD_RW(LCD_RW),
//  .LCD_D(LCD_D)
//);
 
//debounce btn_db0(
//  .clk(clk),
//  .btn_input(usr_btn[0]),
//  .btn_output(btn_level[0])
//);

//debounce btn_db1(
//  .clk(clk),
//  .btn_input(usr_btn[1]),
//  .btn_output(btn_level[1])
//);

reg [3:0] cnt_A;
reg [5:0] cnt_B; // cnt_A from 0 to 15, cnt_B from 0 to 63
// another sram to get matrix data
sram ram1(.clk(clk), .we(sram_we), .en(mult_sram_en),
          .addr(mult_sram_addr), .data_i(data_in), .data_o(mult_sram_out));
assign sram_we = usr_btn[3]; // In this demo, we do not write the SRAM. However,
                             // if you set 'we' to 0, Vivado fails to synthesize
                             // ram0 as a BRAM -- this is a bug in Vivado.
assign mult_sram_en = (R == S_MULT_ADDR || R_next == S_MULT_ADDR); // Enable the SRAM block.
assign mult_sram_addr = {8'b0, cnt_A};
assign data_in = 8'b0; // SRAM is read-only so we tie inputs to zeros.

// third sram to get matrix data
sram ram2(.clk(clk), .we(sram_we), .en(mult_sram_en),
          .addr(mult_sec_addr), .data_i(data_in), .data_o(mult_sec_out));
assign mult_sec_addr = {7'b0, (cnt_B%4)*4+16 + cnt_A/4};


//
// Enable one cycle of btn_pressed per each button hit
//
//always @(posedge clk) begin
//  if (~reset_n)
//    prev_btn_level <= 2'b00;
//  else
//    prev_btn_level <= btn_level;
//end

//assign btn_pressed = (btn_level & ~prev_btn_level);

// ------------------------------------------------------------------------
// The following code creates an initialized SRAM memory block that
// stores an 1024x8-bit unsigned numbers.
//sram ram0(.clk(clk), .we(sram_we), .en(sram_en),
//          .addr(sram_addr), .data_i(data_in), .data_o(data_out));

//assign sram_we = usr_btn[3]; // In this demo, we do not write the SRAM. However,
//                             // if you set 'we' to 0, Vivado fails to synthesize
//                             // ram0 as a BRAM -- this is a bug in Vivado.
//assign sram_en = (P == S_MAIN_ADDR || P == S_MAIN_READ); // Enable the SRAM block.
//assign sram_addr = user_addr[11:0];
//assign data_in = 8'b0; // SRAM is read-only so we tie inputs to zeros.
// End of the SRAM memory block.
// ------------------------------------------------------------------------

//FSM of multiply matrix
always @(posedge clk) begin
    if(~reset_n) R <= S_MULT_ADDR;
    else R <= R_next;
end

reg [8-1:0] A_ele, B_ele;

always @(posedge clk) begin // get input to A,B matrix
  if (~reset_n) begin
    A_ele <= 0;
    B_ele <= 0;
  end
  else if (R == S_MULT_GET) begin
    A_ele <= mult_sram_out;
    B_ele <= mult_sec_out;
  end
end

integer i,j;
always @(posedge clk) begin // do matrix multiply
    if(~reset_n) begin
        for(i=0;i<4;i=i+1) begin
            for(j=0;j<4;j=j+1) begin
                C_mat[i][j] <= 0;
            end
        end
        cnt_A <= 0;
        cnt_B <= 0;
    end
    else if(R == S_MULT_MUL) begin //cnt_B and cnt_A additions have finished
        if(cnt_B%4==3) cnt_A <= cnt_A + 1;
        cnt_B <= cnt_B + 1;
        
        C_mat[cnt_B%4][cnt_A%4] <= C_mat[cnt_B%4][cnt_A%4] + A_ele*B_ele;
    end
end

reg [1:0] cnt_sec;
always @(*) begin
    case (R)
        S_MULT_ADDR:
            R_next = S_MULT_GET;
        S_MULT_GET:
            R_next = S_MULT_MUL;
        S_MULT_MUL:
            if(cnt_B == 63) R_next = S_MULT_REPLY;
            else R_next = S_MULT_ADDR;

        S_MULT_REPLY:
            if(print_done) R_next = S_MULT_RESEC;
            else R_next = S_MULT_REPLY;
        S_MULT_RESEC:
            if(print_done && cnt_sec==3) R_next = S_MULT_WAIT;
            else R_next = S_MULT_RESEC;
        S_MULT_WAIT:
            R_next = S_MULT_WAIT;
    endcase
end

always @(posedge clk) begin
    if(~reset_n) cnt_sec <= 0;
    else begin
        if(R==S_MULT_RESEC && print_done && cnt_sec<3) cnt_sec <= cnt_sec + 1;
        else if(R!=S_MULT_RESEC) cnt_sec <= 0;
    end
end

// ------------------------------------------------------------------------
// FSM of the main controller
//always @(posedge clk) begin
//  if (~reset_n) begin
//    P <= S_MAIN_ADDR; // read samples at 000 first
//  end
//  else begin
//    P <= P_next;
//  end
//end

//always @(*) begin // FSM next-state logic
//  case (P)
//    S_MAIN_ADDR: // send an address to the SRAM
//      P_next = S_MAIN_READ;
//    S_MAIN_READ: // fetch the sample from the SRAM
//      P_next = S_MAIN_SHOW;
//    S_MAIN_SHOW:
//      P_next = S_MAIN_WAIT;
//    S_MAIN_WAIT: // wait for a button click
//      if (| btn_pressed == 1) P_next = S_MAIN_ADDR;
//      else P_next = S_MAIN_WAIT;
//  endcase
//end

integer idx,x;
always @(posedge clk) begin
  if (~reset_n) begin
    for (idx = 0; idx < FIR_LEN; idx = idx + 1) data[idx] = msg_fir[idx*8 +: 8];
    for (idx = 0; idx < SEC_LEN; idx = idx + 1) data[idx+FIR_LEN] = msg_sec[idx*8 +: 8];
  end
  else if (R_next == S_MULT_RESEC) begin //turn hex to ASCII
    for (x=0;x<4;x=x+1) begin
        data[FIR_LEN+2 + x*7 + 0] <= "0" + {2'b00, C_mat[x][cnt_sec][17:16]};
        data[FIR_LEN+2 + x*7 + 1] <= ((C_mat[x][cnt_sec][15:12] > 9)? "7" : "0") + C_mat[x][cnt_sec][15:12];
        data[FIR_LEN+2 + x*7 + 2] <= ((C_mat[x][cnt_sec][11: 8] > 9)? "7" : "0") + C_mat[x][cnt_sec][11: 8];
        data[FIR_LEN+2 + x*7 + 3] <= ((C_mat[x][cnt_sec][ 7: 4] > 9)? "7" : "0") + C_mat[x][cnt_sec][ 7: 4];
        data[FIR_LEN+2 + x*7 + 4] <= ((C_mat[x][cnt_sec][ 3: 0] > 9)? "7" : "0") + C_mat[x][cnt_sec][ 3: 0];
    end
  end
end
// ------------------------------------------------------------------------
// declare UART signals
wire transmit;
wire [7:0] tx_byte;
wire is_transmitting;
uart uart(
  .clk(clk),
  .rst(~reset_n),
  .tx(uart_tx),
  .transmit(transmit),
  .tx_byte(tx_byte),
  .is_transmitting(is_transmitting)
);

assign print_enable = ((R == S_MULT_MUL && R_next == S_MULT_REPLY) || R_next == S_MULT_RESEC);
assign print_done = (tx_byte == 8'h0);
assign transmit = (Q_next == S_UART_WAIT || print_enable);
assign tx_byte = data[send_counter];

always @(posedge clk) begin //not sure
    if(~reset_n) send_counter <= 0;
    else if(R_next==S_MULT_RESEC && print_done) send_counter <= FIR_LEN;
    else send_counter <= send_counter + (Q_next == S_UART_INCR);
end
// FSM of the controller that sends a string to the UART.
always @(posedge clk) begin
  if (~reset_n) Q <= S_UART_IDLE;
  else Q <= Q_next;
end
always @(*) begin // FSM next-state logic
  case (Q)
    S_UART_IDLE: // wait for the print_string flag
      if (print_enable) Q_next = S_UART_WAIT;
      else Q_next = S_UART_IDLE;
    S_UART_WAIT: // wait for the transmission of current data byte begins
      if (is_transmitting == 1) Q_next = S_UART_SEND;
      else Q_next = S_UART_WAIT;
    S_UART_SEND: // wait for the transmission of current data byte finishes
      if (is_transmitting == 0) Q_next = S_UART_INCR; // transmit next character
      else Q_next = S_UART_SEND;
    S_UART_INCR:
      if (tx_byte == 8'h0) Q_next = S_UART_IDLE; // string transmission ends
      else Q_next = S_UART_WAIT;
  endcase
end
// ------------------------------------------------------------------------

// FSM ouput logic: Fetch the data bus of sram[] for display
//always @(posedge clk) begin
//  if (~reset_n) user_data <= 8'b0;
//  else if (sram_en && !sram_we) user_data <= data_out;
//end
// End of the main controller
// ------------------------------------------------------------------------

// ------------------------------------------------------------------------
// The following code updates the 1602 LCD text messages.
//always @(posedge clk) begin
//  if (~reset_n) begin
//    row_A <= "Data at [0x---] ";
//  end
//  else if (P == S_MAIN_SHOW) begin
//    row_A[39:32] <= ((user_addr[11:08] > 9)? "7" : "0") + user_addr[11:08];
//    row_A[31:24] <= ((user_addr[07:04] > 9)? "7" : "0") + user_addr[07:04];
//    row_A[23:16] <= ((user_addr[03:00] > 9)? "7" : "0") + user_addr[03:00];
//  end
//end

//always @(posedge clk) begin
//  if (~reset_n) begin
//    row_B <= "is equal to 0x--";
//  end
//  else if (P == S_MAIN_SHOW) begin
//    row_B[15:08] <= ((user_data[7:4] > 9)? "7" : "0") + user_data[7:4];
//    row_B[07: 0] <= ((user_data[3:0] > 9)? "7" : "0") + user_data[3:0];
//  end
//end
// End of the 1602 LCD text-updating code.
// ------------------------------------------------------------------------

// ------------------------------------------------------------------------
// The circuit block that processes the user's button event.
//always @(posedge clk) begin
//  if (~reset_n)
//    user_addr <= 12'h000;
//  else if (btn_pressed[1])
//    user_addr <= (user_addr < 2048)? user_addr + 1 : user_addr;
//  else if (btn_pressed[0])
//    user_addr <= (user_addr > 0)? user_addr - 1 : user_addr;
//end
// End of the user's button control.
// ------------------------------------------------------------------------

endmodule
