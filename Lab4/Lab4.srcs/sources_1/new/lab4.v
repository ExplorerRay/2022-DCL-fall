`timescale 1ns / 1ps
module lab4(
  input  clk,            // System clock at 100 MHz  (1 clk per 10ns)
  input  reset_n,        // System reset signal, in negative logic
  input  [3:0] usr_btn,  // Four user pushbuttons
  output [3:0] usr_led   // Four yellow LEDs
);

reg [3:0] btn_pressed;//signal for checking the button is pressed or not, [0] for btn0......
reg [18:0] st0,st1,st2,st3;// used for de bounce, When equal to 111, meaning input is stable and turn on
reg signed [3:0] cnt; // not sure signed works well?
reg [2:0] lt_cnt; //light ocunter , 5% 25% 50% 75% 100%(default) (3'b000~3'b100) 
reg rcd_cnt,rcd_lt;

reg [19:0] pwm_cnt;// can count to 2^20=1024^2 > 10^6
reg [3:0] lt;// signal after PWM
parameter ticks = 1000000;// 1 million

//assign btn_pressed = usr_btn;
//assign btn_pressed[0] = (&st0==1) ? 1 : 0;// when state0 equal to 20'b1, set to 1
//assign btn_pressed[1] = (&st1==1);
//assign btn_pressed[2] = (&st2==1);
//assign btn_pressed[3] = (&st3==1);

//assign usr_led = btn_pressed;
assign usr_led = lt;

always @(posedge clk, negedge reset_n) begin //deal with PWM
	if(!reset_n) pwm_cnt <= 0;//important to reset
	else begin
		if(pwm_cnt < 1000000) pwm_cnt <= pwm_cnt + 1;
		else pwm_cnt <= 0;
		
		if(lt_cnt==3'b100) lt <= cnt; //100%
		else if(lt_cnt==3'b011) begin //75%
			if(pwm_cnt < 750000) lt <= cnt;
			else lt <= 4'b0000;
		end
		else if(lt_cnt==3'b010) begin //50%
			if(pwm_cnt < 500000) lt <= cnt;
			else lt <= 4'b0000;
		end
		else if(lt_cnt==3'b001) begin //25%
			if(pwm_cnt < 250000) lt <= cnt;
			else lt <= 4'b0000;
		end
		else if(lt_cnt==3'b000) begin //5%
			if(pwm_cnt < 50000) lt <= cnt;
			else lt <= 4'b0000;
		end
	end
end
always @(posedge clk, negedge reset_n) begin //deal with normal counter
	if(!reset_n) begin
	    rcd_cnt <= 0;
		cnt <= 4'b0000;
	end
	else begin
	    if(btn_pressed[0]==0 && btn_pressed[1]==0)rcd_cnt <= 0;
	    
		if(btn_pressed[0] && cnt!=4'b1000 && rcd_cnt==0) begin 
		    cnt <= cnt - 1;
		    rcd_cnt <= 1;
		end
		else if(btn_pressed[1] && cnt!=4'b0111 && rcd_cnt==0) begin
		    cnt <= cnt + 1;
		    rcd_cnt <= 1;
		end
	end
end
always @(posedge clk, negedge reset_n) begin //deal with brightness counter
	if(!reset_n) begin
	    rcd_lt <= 0;
		lt_cnt <= 3'b100;// default 100%
	end
	else begin
	    if(btn_pressed[2]==0 && btn_pressed[3]==0)rcd_lt <= 0;
	
		if(btn_pressed[2] && lt_cnt > 3'b000 && rcd_lt==0) begin
		    lt_cnt <= lt_cnt -1;
		    rcd_lt <= 1;
		end
		else if(btn_pressed[3] && lt_cnt < 3'b100 && rcd_lt==0) begin
		    lt_cnt <= lt_cnt + 1;
		    rcd_lt <= 1;
		end
	end
end
always @(posedge clk, negedge reset_n) begin //dealing with bounce , not sure it correct or not
	if(!reset_n) begin
		st0 <= 0;
		st1 <= 0;
		st2 <= 0;
		st3 <= 0;
	end
	else begin
		if(usr_btn[0]==1 && &st0!=1) st0 <= st0+1;
		else if(usr_btn[0]==0 && |st0!=0)st0 <= st0-1;
		
		if(usr_btn[1]==1 && &st1!=1) st1 <= st1+1;
		else if(usr_btn[1]==0 && |st1!=0 ) st1 <= st1-1;
		
		if(usr_btn[2]==1 && &st2!=1) st2 <= st2+1;
		else if(usr_btn[2]==0 && |st2!=0) st2 <= st2-1;
		
		if(usr_btn[3]==1 && &st3!=1) st3 <= st3+1;
		else if(usr_btn[3]==0 && |st3!=0) st3 <= st3-1;
	end
end
always @(posedge clk, negedge reset_n) begin // deal with debounce 0to1 and 1to0
	if(!reset_n) btn_pressed <= 4'b0000;
	else begin
		if(&st0==1) btn_pressed[0] <= 1; //when st0==19'b1
		//else btn_pressed[0] <= 0;
		else if(|st0==0) btn_pressed[0] <= 0; //when st0==19'b0
		
		if(&st1==1) btn_pressed[1] <= 1;
		//else btn_pressed[1] <= 0;
		else if(|st1==0) btn_pressed[1] <= 0;
		
		if(&st2==1) btn_pressed[2] <= 1;
		//else btn_pressed[2] <= 0;
		else if(|st2==0) btn_pressed[2] <= 0;
		
		if(&st3==1) btn_pressed[3] <= 1;
		//else btn_pressed[3] <= 0;
		else if(|st3==0) btn_pressed[3] <= 0;//else btn_pressed remain the same
	end
end
endmodule