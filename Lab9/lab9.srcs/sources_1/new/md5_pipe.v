`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/30/2022 11:41:28 PM
// Design Name: 
// Module Name: md5_iter
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


`define SALT_A 32'h67452301
`define SALT_B 32'hefcdab89
`define SALT_C 32'h98badcfe
`define SALT_D 32'h10325476

module md5_pipe(output wire [127:0] digest_o, output valid, output [63:0] value, input clk, rst, input [63:0] message, input new_message);
//	reg [1:0] round;
//	reg [3:0] phase;
	reg [127:0] digest [63:0];
	reg [63:0] stage_valid;
	reg [63:0] stage_message [63:0];
	reg [511:0] padded_message [63:0];
	reg [127:0] current_state [63:0];
	wire [127:0] next_state [63:0];
	reg idle;
    
//    genvar round, phase;
//    generate
//        for(round=0;round<4;round=round+1) begin
//            for(phase=0;phase<16;phase=phase+1) begin
                
//            end
//        end
//    endgenerate
    
    genvar i;
    generate
        for(i=0;i<64;i=i+1) begin
//            always @(*) begin
//                if(rst) begin
//                    phase = 0;
//                    round = 0;
//                end
//                else begin
//                    phase = i[3:0];
//                    round = i[5:4];
//                end
//            end
            md5_operation md5op(.round(i[5:4]), .phase(i[3:0]), .message(padded_message[i]), .current_state(current_state[i]), .next_state(next_state[i]));
        
            always @ (posedge clk) begin
                if( rst ) begin
                    if(i==0)current_state[0] <= {`SALT_A, `SALT_B, `SALT_C, `SALT_D};
                    else current_state[i] <= 0;
                    padded_message[i] <= 0;
                    stage_message[i] <= 0;
                    
                    digest[i] <= 0;
                end
                else begin
                    current_state[0] <= {`SALT_A, `SALT_B, `SALT_C, `SALT_D};
                    if(i!=0 && i!=63)current_state[i] <= next_state[i-1]; // CHECK
                    if(stage_valid[62] && i==63)current_state[63] <= next_state[62];
                    else current_state[63] <= current_state[63];
                        
                    if(new_message)padded_message[0] <= {message[39:32], message[47:40], message[55:48], message[63:56],
		                                                 message[7:0], message[15:8], message[23:16], message[31:24],
		                                                 24'd0, 8'b10000000, 352'd0, 24'd0, 8'd64, 32'd0};
		            else padded_message[0] <= 0;
                    if(i!=0 && i!=63)padded_message[i] <= padded_message[i-1];
                    if(stage_valid[62] && i==63)padded_message[63] <= padded_message[62];
                    else padded_message[63] <= padded_message[63];
                    
                    if(new_message)stage_message[0] <= message;
                    else stage_message[0] <= 0;
                    if(i!=0 && i!=63)stage_message[i] <= stage_message[i-1];
                    if(stage_valid[62] && i==63)stage_message[63] <= stage_message[62];
                    else stage_message[63] <= stage_message[63];
                        
                    digest[i] <= {next_state[i][127:96]+`SALT_A, next_state[i][95:64]+`SALT_B,  next_state[i][63:32]+`SALT_C, next_state[i][31:0]+`SALT_D};
                end
            end
        end
	endgenerate
	
	always @(posedge clk) begin
	   if( rst ) stage_valid <= 0;
	   else if(stage_valid[62])stage_valid <= {stage_valid[62:0], new_message};
	   else stage_valid <= {stage_valid[63], stage_valid[61:0], new_message};
	end

    
    assign valid = stage_valid[63];
    assign value = stage_message[63];
    
    assign digest_o[127:96] = {digest[63][103:96], digest[63][111:104], digest[63][119:112], digest[63][127:120]};
	assign digest_o[95:64] =  {digest[63][71:64], digest[63][79:72], digest[63][87:80], digest[63][95:88]};
	assign digest_o[63:32] =  {digest[63][39:32], digest[63][47:40], digest[63][55:48], digest[63][63:56]};
	assign digest_o[31:0] =  {digest[63][7:0], digest[63][15:8], digest[63][23:16], digest[63][31:24]};

endmodule
