`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/28/2022 08:09:08 PM
// Design Name: 
// Module Name: alu
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


module alu(
    output wire [7:0] alu_out,
    output wire zero,
    input wire [2:0] opcode,
    input wire [7:0] data,
    input wire [7:0] accum,
    input wire clk,
    input wire reset
    );

reg [7:0] out;
wire [7:0] accum_2c;//2's complement
wire [7:0] data_2c; //2's complement
wire [7:0] accum_abs;

wire [3:0] accum_mul;
wire [3:0] data_mul;
wire [7:0] mul_abs;
wire [7:0] mul_ans;

assign accum_2c = ~(accum) + 1;
assign data_2c = ~(data) + 1;
assign accum_abs = (accum[7]==1) ? accum_2c : accum;

assign accum_mul = (accum[3]==1) ? ~(accum[3:0])+1 : accum[3:0]; 
//if input only from -7 to 7 , accum[7]==accum[3], so this equals to accum_abs[3:0]
assign data_mul = (data[3]==1) ? ~(data[3:0])+1 : data[3:0];
assign mul_abs = accum_mul * data_mul;
assign mul_ans = (accum[3] ^ data[3]==1) ? ~(mul_abs)+1 : mul_abs;

assign alu_out = out;
assign zero = (accum==0) ? 1 : 0;
    
always @(posedge clk, posedge reset) begin
    if(reset==1) begin
    	out <= 0;
    end
	else begin
		case(opcode)
			3'b000: out <= accum;
			3'b001: out <= accum + data;
			3'b010: out <= accum + data_2c; //accum - data
			3'b011: out <= accum & data;
			3'b100: out <= accum ^ data;
			3'b101: out <= accum_abs;
			3'b110: out <= mul_ans;//not yet
			3'b111: out <= data;
			default: out <= 0;
		endcase
	end
end
endmodule
