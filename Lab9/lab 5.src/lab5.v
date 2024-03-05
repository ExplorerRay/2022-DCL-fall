`timescale 1ns / 1ps
/////////////////////////////////////////////////////////
module lab9(
  input clk,
  input reset_n,
  input [3:0] usr_btn,
  output [3:0] usr_led,
  output LCD_RS,
  output LCD_RW,
  output LCD_E,
  output [3:0] LCD_D
);

// states
localparam [2:0] S_MAIN_WAIT = 0, S_MAIN_CALC = 1,
				 S_MAIN_SHOW = 2;

// turn off all the LEDs
assign usr_led = 4'b0000;

//reg [0:127] passwd_hash = 128'h554f6b200af0d287596c1bb47c72553f;
//99999998
reg [0:127] passwd_hash = 128'hE8CD0953ABDFDE433DFEC7FAA70DF7F6;
// 53589793

reg [2:0] P, P_next;

//reg [27:0] time_cnt;// add 1 every 1ms (10^5 clk)
reg [$clog2(100000):0] clk_cnt;
//reg [31:0] gus_value; // guess the answer,brute force from 0 to 10^8-1
wire [31:0] gus_BCD;
wire [27:0] tm_BCD;
wire [63:0] init_msg; // cnt_value turn to ASCII, becomes initial message
wire valid;
wire str_crk; //start crack
wire [127:0] current_digest;
wire [63:0] current_value;
reg [63:0] ans;
wire found;

//for sec
wire [31:0] gus_BCD2;
wire valid2;
wire [63:0] init_msg2;
wire [127:0] current_digest2;
wire [63:0] current_value2;
reg [63:0] ans2;
wire found2;

reg found_tmp, found_tmp2;

wire btn_level, btn_pressed;
reg prev_btn_level;
reg [127:0] row_A = "Press BTN3 to   "; // Initialize the text of the first row. 
reg [127:0] row_B = "show a message.."; // Initialize the text of the second row.

LCD_module lcd0(
  .clk(clk),
  .reset(~reset_n),
  .row_A(row_A),
  .row_B(row_B),
  .LCD_E(LCD_E),
  .LCD_RS(LCD_RS),
  .LCD_RW(LCD_RW),
  .LCD_D(LCD_D)
);
    
debounce btn_db0(
  .clk(clk),
  .btn_input(usr_btn[3]),
  .btn_output(btn_level)
);
    
always @(posedge clk) begin
  if (~reset_n)
    prev_btn_level <= 1;
  else
    prev_btn_level <= btn_level;
end

assign btn_pressed = (btn_level == 1 && prev_btn_level == 0);

assign init_msg = {{4'b0011}, gus_BCD[31:28],
				   {4'b0011}, gus_BCD[27:24],
				   {4'b0011}, gus_BCD[23:20],
				   {4'b0011}, gus_BCD[19:16],
				   {4'b0011}, gus_BCD[15:12],
				   {4'b0011}, gus_BCD[11:8],
				   {4'b0011}, gus_BCD[7:4],
				   {4'b0011}, gus_BCD[3:0]};
assign gus_BCD2 = gus_BCD + 32'h50000000;
assign init_msg2 = {{4'b0011}, gus_BCD2[31:28],
				   {4'b0011}, gus_BCD2[27:24],
				   {4'b0011}, gus_BCD2[23:20],
				   {4'b0011}, gus_BCD2[19:16],
				   {4'b0011}, gus_BCD2[15:12],
				   {4'b0011}, gus_BCD2[11:8],
				   {4'b0011}, gus_BCD2[7:4],
				   {4'b0011}, gus_BCD2[3:0]};

assign str_crk = (P==S_MAIN_WAIT && P_next==S_MAIN_CALC);
assign found = valid && (current_digest==passwd_hash);
//assign ans = found ? current_value : ans;
assign found2 = valid2 && (current_digest2==passwd_hash);
//assign ans2 = found2 ? current_value2 : ans2;

always @(posedge clk) begin
    if(~reset_n) begin
        ans <= 0;
        ans2 <= 0;
    end
    else begin
        ans <= found ? current_value : ans;
        ans2 <= found2 ? current_value2 : ans2;
    end
end
//always @(posedge clk) begin
//	if(~reset_n) tmp_digest <= 0;
//	else tmp_digest <= current_digest;
//end
//always @(posedge clk) begin
//	if(~reset_n) begin
//		//init_msg <= 0;
//		gus_value <= 0;
//	end
//	else begin
//		//init_msg <= tmp_msg;
//		if(P==S_MAIN_CALC) begin
//			if(valid) begin// if md5 finished, and the guess value not correct, add 1
//				gus_value <= gus_value + 1;
//			end
//			else gus_value <= gus_value;
//		end
//		else gus_value <= gus_value;
//	end
//end
BCD_cnt guess(
	.clk(clk),
	.rst(~reset_n),
	.cin(valid),
	.result(gus_BCD)
);
BCD_cnt tm_cnt(
	.clk(clk),
	.rst(~reset_n),
	.cin(clk_cnt==100000),
	.result(tm_BCD)
);

md5_tmp md5_tst(
	.digest(current_digest),
	.valid(valid), //signal
	.value(current_value),
	.clk(clk), 
	.rst(~reset_n), 
	.message(init_msg),
	.new_message(str_crk || valid) //signal
);
md5_tmp md5_sec(
	.digest(current_digest2),
	.valid(valid2), //signal
	.value(current_value2),
	.clk(clk), 
	.rst(~reset_n), 
	.message(init_msg2),
	.new_message(str_crk || valid2) //signal
);
//md5_iter ano(
//  .digest_o(current_digest),
//	.valid(valid), //signal
//	.value(current_value),
//	.clk(clk), 
//	.rst(~reset_n), 
//	.message(init_msg),
//	.new_message(str_crk || (valid && current_digest!=passwd_hash))
//);

always @(posedge clk) begin
	if(~reset_n) begin
		//time_cnt <= 0;
		clk_cnt <= 0;
	end
	else begin
		if(P==S_MAIN_CALC) begin
			clk_cnt <= clk_cnt + 1;
			if(clk_cnt==100000) begin
				//time_cnt <= time_cnt + 1;
				clk_cnt <= 0;
			end
		end
		else begin
			//time_cnt <= time_cnt;
			clk_cnt <= 0;
		end
	end
end


always @(posedge clk) begin
	if(~reset_n) P <= S_MAIN_WAIT;
	else P <= P_next;
end
always @(*) begin
	case (P)
	  S_MAIN_WAIT:
	    if(btn_pressed)P_next = S_MAIN_CALC;
	    else P_next = S_MAIN_WAIT;
	  S_MAIN_CALC:
	    if(found_tmp || found_tmp2)P_next = S_MAIN_SHOW;
	    else P_next = S_MAIN_CALC;
	  S_MAIN_SHOW:
	  	P_next = S_MAIN_SHOW;
	endcase
end

always @(posedge clk) begin
    if(~reset_n) begin
        found_tmp <= 0;
        found_tmp2 <= 0;
    end
    else begin
        if(found)found_tmp <= 1;
        
        if(found2)found_tmp2 <= 1;
    end
end

always @(posedge clk) begin
  if (~reset_n || P==S_MAIN_WAIT) begin
    // Initialize the text when the user hit the reset button
    row_A = "Press BTN3 to   ";
    row_B = "show a message..";
  end
  else if(P==S_MAIN_CALC) begin
    row_A <= {"Crack:  ", current_value};
    row_B <= {"Time: ",
    		  {4'b0011}, tm_BCD[27:24],
    		  {4'b0011}, tm_BCD[23:20],
    		  {4'b0011}, tm_BCD[19:16],
    		  {4'b0011}, tm_BCD[15:12],
    		  {4'b0011}, tm_BCD[11:8],
    		  {4'b0011}, tm_BCD[7:4],
    		  {4'b0011}, tm_BCD[3:0],
    		  " ms"};
  end
  else if(P==S_MAIN_SHOW) begin
    if(found_tmp)row_A <= {"Passwd: ", ans};
    else if(found_tmp2) row_A <= {"Passwd: ", ans2};
    row_B <= {"Time: ",
    		  {4'b0011}, tm_BCD[27:24],
    		  {4'b0011}, tm_BCD[23:20],
    		  {4'b0011}, tm_BCD[19:16],
    		  {4'b0011}, tm_BCD[15:12],
    		  {4'b0011}, tm_BCD[11:8],
    		  {4'b0011}, tm_BCD[7:4],
    		  {4'b0011}, tm_BCD[3:0],
    		  " ms"};
  end
end
endmodule

module debounce(
    input clk,
    input btn_input,
    output btn_output
    );
    assign btn_output = btn_input;
endmodule