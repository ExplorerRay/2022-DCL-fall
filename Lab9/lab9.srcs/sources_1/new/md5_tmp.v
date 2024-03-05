`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/30/2022 01:02:52 PM
// Design Name: 
// Module Name: md5_tmp
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


`define A 32'h67452301
`define B 32'hefcdab89
`define C 32'h98badcfe
`define D 32'h10325476

module md5_tmp(output [127:0] digest, output reg valid, output reg [63:0] value, input clk, rst, input [63:0] message, input new_message);
	reg [127:0] state_in [63:1];
	wire [127:0] state_out [63:0];
	reg [63:0] stage_message [63:1];
	reg [63:1] stage_valid;
	reg [127:0] tmp_digest;

	genvar rp;//round phase
	generate
		for( rp = 0; rp < 64; rp = rp + 1 ) begin
			if( rp==0 ) 
				md5_operation md5_0(.round(rp[5:4]), .phase(rp[3:0]), .message({message[39:32], message[47:40], message[55:48], message[63:56],
		message[7:0], message[15:8], message[23:16], message[31:24], 24'd0, 8'b10000000, 352'd0, 24'd0, 8'd64, 32'd0}), .current_state({`A,`B,`C,`D}), .next_state(state_out[rp]));
			else
				md5_operation md5_all(.round(rp[5:4]), .phase(rp[3:0]), .message({stage_message[rp][39:32], stage_message[rp][47:40], stage_message[rp][55:48], stage_message[rp][63:56],
		stage_message[rp][7:0], stage_message[rp][15:8], stage_message[rp][23:16], stage_message[rp][31:24], 24'd0, 8'b10000000, 352'd0, 24'd0, 8'd64, 32'd0}), .current_state(state_in[rp]), .next_state(state_out[rp]));
		end
	endgenerate

	genvar i;
	generate
		for( i = 1; i < 64; i = i + 1 ) begin : messages
			always @ (posedge clk) begin
				if( i == 1 )
					stage_message[1] <= message;
				else begin
					stage_message[i] <= stage_message[i-1];
					if( ~stage_valid[62] )
						stage_message[63] <= stage_message[63];
				end
				state_in[i] <= state_out[i-1];
				if( ~stage_valid[62] )
					state_in[63] <= state_in[63];
			end
		end
	endgenerate

	always @ (posedge clk) begin
		if( rst ) begin
			stage_valid <= 63'd0;
		end
		else begin
            if( stage_valid[62] )
                stage_valid <= {stage_valid[62:1], new_message};// left shift
            else
                stage_valid <= {stage_valid[63], stage_valid[61:1], new_message}; 
		end
	end
    
    always @(posedge clk) begin
        if(rst) begin
            tmp_digest <= 0;
            valid <= 0;
        end
        else begin
            value <= stage_message[63];
            valid <= stage_valid[63];
            tmp_digest <= { state_out[63][127:96]+`A, state_out[63][95:64]+`B, state_out[63][63:32]+`C, state_out[63][31:0]+`D};
        end
    end
	//assign tmp_digest = { state_out[63][127:96]+`A, state_out[63][95:64]+`B, state_out[63][63:32]+`C, state_out[63][31:0]+`D};
	assign digest = {tmp_digest[103:96], tmp_digest[111:104], tmp_digest[119:112], tmp_digest[127:120],
						tmp_digest[71:64], tmp_digest[79:72], tmp_digest[87:80], tmp_digest[95:88],
						tmp_digest[39:32], tmp_digest[47:40], tmp_digest[55:48], tmp_digest[63:56], 
						tmp_digest[7:0], tmp_digest[15:8], tmp_digest[23:16], tmp_digest[31:24]};
	//assign valid = stage_valid[63];
	//assign value = stage_message[63];
endmodule
