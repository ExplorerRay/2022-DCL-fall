`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/19/2022 09:11:22 PM
// Design Name: 
// Module Name: mmult
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module mmult(
	input clk,
	input reset_n,
	input enable,
	input [0:9*8-1] A_mat,
	input [0:9*8-1] B_mat,
	output valid, //signal that the output is valid to read (meaning mult is done)
	output reg [0:9*17-1] C_mat
    );
    
reg [0:9*8-1] Bm;
//reg [0:9*17-1] C_ans;
//wire [0:16] c1,c2,c3,c4,c5,c6,c7,c8,c9;
reg [1:0] cnt;

assign valid = &cnt;//when cnt==11

always @(posedge clk, negedge reset_n) begin
	if(!reset_n) begin
		C_mat <= 0;
		Bm <= B_mat;
		cnt <= 0;
	end
	else if(enable) begin
		if(cnt==0) begin
			C_mat[0:16] <= A_mat[0:7]*Bm[0:7] + A_mat[8:15]*Bm[24:31] + A_mat[16:23]*Bm[48:55];
			C_mat[51:67] <= A_mat[24:31]*Bm[0:7] + A_mat[32:39]*Bm[24:31] + A_mat[40:47]*Bm[48:55];
			C_mat[102:118] <= A_mat[48:55]*Bm[0:7] + A_mat[56:63]*Bm[24:31] + A_mat[64:71]*Bm[48:55];
		end
		else if(cnt==1) begin
			C_mat[17:33] <= A_mat[0:7]*Bm[0:7] + A_mat[8:15]*Bm[24:31] + A_mat[16:23]*Bm[48:55];
			C_mat[68:84] <= A_mat[24:31]*Bm[0:7] + A_mat[32:39]*Bm[24:31] + A_mat[40:47]*Bm[48:55];
			C_mat[119:135] <= A_mat[48:55]*Bm[0:7] + A_mat[56:63]*Bm[24:31] + A_mat[64:71]*Bm[48:55];
		end
		else if(cnt==2)begin
			C_mat[34:50] <= A_mat[0:7]*Bm[0:7] + A_mat[8:15]*Bm[24:31] + A_mat[16:23]*Bm[48:55];
			C_mat[85:101] <= A_mat[24:31]*Bm[0:7] + A_mat[32:39]*Bm[24:31] + A_mat[40:47]*Bm[48:55];
			C_mat[136:152] <= A_mat[48:55]*Bm[0:7] + A_mat[56:63]*Bm[24:31] + A_mat[64:71]*Bm[48:55];
		end
		Bm <= Bm << 8;
		if(cnt!=3) begin cnt <= cnt + 1; end
	end
end
endmodule
