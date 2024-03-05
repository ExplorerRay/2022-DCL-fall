`timescale 1ns / 1ps
/////////////////////////////////////////////////////////
module lab5(
  input clk,
  input reset_n,
  input [3:0] usr_btn,
  output [3:0] usr_led,
  output LCD_RS,
  output LCD_RW,
  output LCD_E,
  output [3:0] LCD_D
);

// turn off all the LEDs
assign usr_led = 4'b0000;

wire btn_level, btn_pressed;
reg prev_btn_level;
reg [127:0] row_A = "Press BTN3 to   "; // Initialize the text of the first row. 
reg [127:0] row_B = "show a message.."; // Initialize the text of the second row.

reg [27:0] cnt; // count to 70 millions
reg [4:0] stp; // from 1 to 25
reg after_pressed; // after press btn_3

reg [16*25-1:0] fibo;
integer i;
initial begin //deal with first 25 fibo
	fibo[15:0]=4'h0000;
	fibo[31:16]=4'h0001;
	for(i=3;i<=25;i=i+1) begin
		fibo[(i)*16-1 -: 16] = fibo[(i-1)*16-1 -: 16] + fibo[(i-2)*16-1 -: 16];
	end
end


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
  .reset_n(reset_n),
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


always @(posedge clk) begin
	if (~reset_n) begin
		after_pressed <= 0;
	end
	else begin
		if(btn_pressed) after_pressed <= ~after_pressed;
	end
end

//0.7 sec = 70 millions clock
always @(posedge clk) begin
	if (~reset_n) begin
		stp <= 1;
		cnt <= 0;
	end
	else if(cnt==70000000) begin
		cnt <= 0;
		if(after_pressed==0) begin
			if(stp<25)stp <= stp + 1;
			else stp <= 1;
		end
		else begin
			if(stp>1)stp <= stp - 1;
			else stp <= 25;
		end
	end
	else cnt <= cnt + 1;
end

always @(posedge clk) begin
  if (~reset_n) begin
    // Initialize the text when the user hit the reset button
    row_A <= "Press BTN3 to   ";
    row_B <= "show a message..";
  end
  else if (cnt==70000000) begin
    //row_A <= "Hello, World!   ";
    //row_B <= "Demo of the LCD.";
    
    row_A[127:80] <= "Fibo #";
    row_A[79:72] <= stp/10 + 48;
  	row_A[71:64] <= stp%10 + 48;
  	row_A[63:32] <= " is ";
  	if(fibo[(stp)*16-1 -: 4]>=0 && fibo[(stp)*16-1 -: 4]<=9)row_A[31:24] <= {4'b0011, fibo[(stp)*16-1 -: 4]};
  	else row_A[31:24] <= fibo[(stp)*16-1 -: 4] + 55;
  	if(fibo[(stp)*16-5 -: 4]>=0 && fibo[(stp)*16-5 -: 4]<=9)row_A[23:16] <= {4'b0011, fibo[(stp)*16-5 -: 4]};
  	else row_A[23:16] <= fibo[(stp)*16-5 -: 4] + 55;
  	if(fibo[(stp)*16-9 -: 4]>=0 && fibo[(stp)*16-9 -: 4]<=9)row_A[15:8] <= {4'b0011, fibo[(stp)*16-9 -: 4]};
  	else row_A[15:8] <= fibo[(stp)*16-9 -: 4] + 55;
  	if(fibo[(stp)*16-13 -: 4]>=0 && fibo[(stp)*16-13 -: 4]<=9)row_A[7:0] <= {4'b0011, fibo[(stp)*16-13 -: 4]};
  	else row_A[7:0] <= fibo[(stp)*16-13 -: 4] + 55;
  	
  	row_B[127:80] <= "Fibo #";
  	row_B[63:32] <= " is ";
  	if(stp+1 == 26) begin //特判 stp+1 == 26 代表繞回來到1
  		row_B[79:64] <= "01"; 
  		row_B[31:24] <= {4'b0011, fibo[16-1 -: 4]};
  		row_B[23:16] <= {4'b0011, fibo[16-5 -: 4]};
  		row_B[15:8] <= {4'b0011, fibo[16-9 -: 4]};
  		row_B[7:0] <= {4'b0011, fibo[16-13 -: 4]};
  	end
  	else begin
		row_B[79:72] <= (stp+1)/10 + 48;
		row_B[71:64] <= (stp+1)%10 + 48;
		if(fibo[(stp+1)*16-1 -: 4]>=0 && fibo[(stp+1)*16-1 -: 4]<=9)row_B[31:24] <= {4'b0011, fibo[(stp+1)*16-1 -: 4]};
		else row_B[31:24] <= fibo[(stp+1)*16-1 -: 4] + 55;
		if(fibo[(stp+1)*16-5 -: 4]>=0 && fibo[(stp+1)*16-5 -: 4]<=9)row_B[23:16] <= {4'b0011, fibo[(stp+1)*16-5 -: 4]};
		else row_B[23:16] <= fibo[(stp+1)*16-5 -: 4] + 55;
		if(fibo[(stp+1)*16-9 -: 4]>=0 && fibo[(stp+1)*16-9 -: 4]<=9)row_B[15:8] <= {4'b0011, fibo[(stp+1)*16-9 -: 4]};
		else row_B[15:8] <= fibo[(stp+1)*16-9 -: 4] + 55;
		if(fibo[(stp+1)*16-13 -: 4]>=0 && fibo[(stp+1)*16-13 -: 4]<=9)row_B[7:0] <= {4'b0011, fibo[(stp+1)*16-13 -: 4]};
		else row_B[7:0] <= fibo[(stp+1)*16-13 -: 4] + 55;
	end
  end
end

endmodule

module debounce(
    input clk,
    input reset_n,
    input btn_input,
    output btn_output
    );
    reg [18:0] st3;
    always @(posedge clk) begin
    	if(~reset_n) st3 <= 0;
    	else begin
    		if(btn_input==1 && &st3!=1) st3 <= st3 + 1;
    		else if(btn_input==0) st3 <= 0;
    	end
    end
    
    assign btn_output = (&st3==1);
endmodule