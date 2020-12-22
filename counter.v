module counter (
input Clk, 
input Mode, 
input En,
input Rst,
input Step,
output reg [0:3] Cnt
);

reg b_rst;
reg b_en;
reg b_mode;
reg b_step;

initial begin
    Cnt <= 0;
end 

always @(posedge Clk)
begin
    b_rst <= Rst;
    b_en <= En;
    b_mode <= Mode;
    b_step <= Step;
end

always @(negedge Clk)
begin
    if(b_rst) begin 
        Cnt <=0;
    end 
    else begin
        if (b_en) begin
            if(b_mode) begin
                if(Cnt == 9) Cnt <= Cnt;                
                else begin
                    if (!b_step) Cnt <= Cnt+1;
                    else if (Cnt == 7 || Cnt == 8) Cnt <= Cnt; 
                    else    Cnt <= Cnt+3;
                end
            end
            else begin
                if(Cnt == 0) Cnt <= Cnt;
                else begin
                    if (!b_step) Cnt <= Cnt-1;
                    else if (Cnt == 1 || Cnt == 2) Cnt <= Cnt;       
                    else Cnt <= Cnt-3;
                end
            end
        end
    end
end
endmodule