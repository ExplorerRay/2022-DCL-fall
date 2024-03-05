`timescale 1ns / 1ps

module SeqMultiplier(
    input wire clk,
    input wire enable,
    input wire [0:7] A,
    input wire [0:7] B,
    output wire [0:16] C
    );

reg [0:16] ans;
reg [0:7] mult;
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
    	ans <= (ans + (A & {8{mult[0]}})) << shift;
        mult <= mult << 1;
        counter <= counter + shift;
    end
end
endmodule
