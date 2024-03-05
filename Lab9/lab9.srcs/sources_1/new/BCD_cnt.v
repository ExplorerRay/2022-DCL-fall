`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/04/2022 12:47:55 PM
// Design Name: 
// Module Name: BCD_cnt
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


module BCD_cnt(
  input clk,
  input rst,
  input cin, // valid
  output [31:0]result
);

genvar i;
wire Ci[7:0];
wire Co[7:0];

assign Ci[0] = cin;
assign Ci[1] = Co[0];
assign Ci[2] = Co[1];
assign Ci[3] = Co[2];
assign Ci[4] = Co[3];
assign Ci[5] = Co[4];
assign Ci[6] = Co[5];
assign Ci[7] = Co[6];

wire [3:0]sum[7:0];
assign result = {sum[7],sum[6],sum[5],sum[4],sum[3],sum[2],sum[1],sum[0]};

generate
  for(i=0;i<8;i=i+1)begin
    BCD 
    B(
      .clk(clk),
      .rst(rst),
	  .Cin(Ci[i]),
	  .sum(sum[i]),
	  .Cout(Co[i])  
    );
  end
endgenerate

endmodule 
