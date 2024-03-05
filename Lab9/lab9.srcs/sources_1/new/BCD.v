`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/04/2022 06:14:09 AM
// Design Name: 
// Module Name: BCD
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


module BCD(
	input clk,
	input rst,
	input Cin,
	output reg [3:0] sum,
	output Cout
    );
    
    always @(posedge clk) begin
    	if(rst) sum <= 0;
    	else if(Cin) begin
    		sum <= (sum==9) ? 0 : sum+1;
    	end
    end
    assign Cout = (sum==9 && Cin);
endmodule
