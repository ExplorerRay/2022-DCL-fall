module Color_controller(C1,C2,clk,outputC,seven_segment_output);
    input C1,C2,clk;
    output [1:0] outputC;
    output [2:0] seven_segment_output;
    
    reg [3:0] P,P_next;
    reg [9:0] H;
    reg count;
    
    initial begin
        P = 0;
        P_next = 0;
        count = 0;
    end
    
    always@(*)begin
        P_next = 0;
        count = 0;
        
        case (P)
            0:begin
                if (C1 == 1)begin
                    P_next = 1;
                end
                else if (C2 == 1)begin
                    P_next = 2;
                end
                else begin
                    P_next = 0;
                end
            end
            1:begin
                count = 1;
                if (C2 == 1)begin
                    P_next = 0;
                end
                else if (H < 500)begin
                    P_next = 1;
                end
                else begin
                    P_next = 3;
                end
            end
            2:begin
                count = 1;
                if (C1 == 1)begin
                    P_next = 0;
                end
                else if (H < 500)begin
                    P_next = 2;
                end
                else begin
                    P_next = 3;
                end
            end
            3:begin
                if (C1 == 1)begin
                    P_next = 4;
                end
                else if (C2 == 1)begin
                    P_next = 5;
                end
                else begin
                    P_next = 3;
                end
            end
            4:begin
                count = 1;
                if (C2 == 1)begin
                    P_next = 3;
                end
                else if (H < 500)begin
                    P_next = 4;
                end
                else begin
                    P_next = 6;
                end
            end
            5:begin
                count = 1;
                if (C1 == 1)begin
                    P_next = 3;
                end
                else if (H < 500)begin
                    P_next = 5;
                end
                else begin
                    P_next = 6;
                end
            end
            6:begin
                if (C1 == 1)begin
                    P_next = 7;
                end
                else if (C2 == 1)begin
                    P_next = 8;
                end
                else begin
                    P_next = 6;
                end
            end
            7:begin
                count = 1;
                if (C2 == 1)begin
                    P_next = 6;
                end
                else if (H < 500)begin
                    P_next = 7;
                end
                else begin
                    P_next = 9;
                end
            end
            8:begin
                count = 1;
                if (C1 == 1)begin
                    P_next = 6;
                end
                else if (H < 500)begin
                    P_next = 8;
                end
                else begin
                    P_next = 9;
                end
            end
            9:begin
                if (C1 == 1)begin
                    P_next = 10;
                end
                else if (C2 == 1)begin
                    P_next = 11;
                end
                else begin
                    P_next = 9;
                end
            end
            10:begin
                count = 1;
                if (C2 == 1)begin
                    P_next = 9;
                end
                else if (H < 500)begin
                    P_next = 10;
                end
                else begin
                    P_next = 0;
                end
            end
            11:begin
                count = 1;
                if (C1 == 1)begin
                    P_next = 9;
                end
                else if (H < 500)begin
                    P_next = 11;
                end 
                else begin
                    P_next = 0;
                end
            end
        endcase
    end
    
    always@(posedge clk)begin
        P <= P_next;
    end

    // H_counter
    always@(posedge clk)begin
        if (count == 0)begin
            H <= 0;
        end
        else begin
            if (H < 500)begin
                H <= H + 1;
            end
            else begin
                H <= 0;
            end
        end
    end

    // outputC
    assign outputC = (P >= 0 && P <= 2) ? 0 : 
                     (P >= 3 && P <= 5) ? 1 :
                     (P >= 6 && P <= 8) ? 2 : 3;
                     
    // 7-segment
    assign seven_segment_output = (P >= 0 && P <= 2) ? 1 : 
                     (P >= 3 && P <= 5) ? 2 :
                     (P >= 6 && P <= 8) ? 3 : 4;


endmodule