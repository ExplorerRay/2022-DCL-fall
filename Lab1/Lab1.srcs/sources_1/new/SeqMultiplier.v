`timescale 1ns / 1ps

module SeqMultiplier(
    input wire clk,
    input wire enable,
    input wire [7:0] A,
    input wire [7:0] B,
    output wire [15:0] C
    );

reg [15:0] ans;
reg [7:0] mult;
reg [2:0] counter;
wire shift;
	
assign C = ans;
assign shift = !(&counter); //shift=0 when counter=111

always @(posedge clk) begin
    if(!enable) begin
        mult <= B;
        ans <= 0;
        counter <= 0;
    end
    else begin
    	ans <= (ans + (A & {8{mult[7]}})) << shift;
        mult <= mult << 1;
        counter <= counter + shift;
    end
end
endmodule
