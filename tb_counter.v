module tb_counter; 
reg Clk;
reg Mode;
reg En;
reg Rst;
reg Step;
wire [0:3] Cnt;

counter inst1 (Clk, Mode, En, Rst, Step, Cnt);

parameter clk_period  = 5;
parameter full_cycle  = 100;

integer write_data;

reg reset_err;
reg count_err;
reg overflow_err;
wire test_err;

reg overflow;


reg [0:3] delay_reg;
integer n;

always
begin
    #clk_period Clk = !Clk;    
end

initial 
begin
    Clk <= 0;
    Mode <= 0;
    En <= 0;
    Rst <= 0;
    Step <= 0;
    reset_err <= 0;
    count_err <= 0;
    overflow_err <= 0;
    delay_reg <= 0;
end

assign test_err = reset_err&count_err&overflow_err;

always @(negedge Clk) 
begin
    delay_reg <= Cnt;
end

always @(negedge Clk) 
begin
    if(Cnt > 0 && Cnt < 9) overflow <= 0;
    else    overflow <= 1;
end

initial begin 
    write_data = $fopen("report.txt");
end

/////////////////////////////////////////////////////
//_____________Проверка режимов работы_____________//
/////////////////////////////////////////////////////

event pMode_pStep;
event nMode_pStep;
event pMode_nStep;
event nMode_nStep;

event check_pMode_pStep;
event check_nMode_pStep;
event check_pMode_nStep;
event check_nMode_nStep;

initial begin 
    forever begin 
        @(pMode_pStep); 
        @(posedge Clk); 
        Mode <=1;
        Step <=1;
        repeat(3) begin
        @(negedge Clk); 
        end     
        -> check_pMode_pStep;
        if(Cnt == 9);           
    end 
end

initial begin 
    forever begin 
        @(check_pMode_pStep);  
        if((Cnt != delay_reg+3 && !overflow) || !En) begin
            $fdisplay(write_data, "Increment error at time %t",  $time);
            count_err <= 1;
        end
        else begin
            $fdisplay(write_data, "The counter is working correctly at time %t",  $time); 
            count_err <= 0;       
        end                
    end 
end

initial begin 
    forever begin 
        @(nMode_pStep); 
        @(posedge Clk); 
        Mode <=0;
        Step <=1;
        repeat(3) begin
        @(negedge Clk); 
        end     
        -> check_nMode_pStep;
        if(Cnt == 0);           
    end 
end

initial begin  
    forever begin 
        @(check_nMode_pStep); 
        if((Cnt != delay_reg-3 && !overflow) || !En) begin
            $fdisplay (write_data,"Decrement error at time %t",  $time);
            count_err <= 1;
        end 
        else begin
            $fdisplay (write_data,"The counter is working correctly at time %t",  $time); 
            count_err <= 0;       
        end              
    end 
end

initial begin 
    forever begin 
        @(pMode_nStep); 
        @(posedge Clk); 
        Mode <=1;
        Step <=0;
        repeat(3) begin
        @(negedge Clk); 
        end     
        -> check_pMode_nStep;
        if(Cnt == 9);           
    end 
end

initial begin 
    forever begin 
        @(check_pMode_nStep); 
        if((Cnt != delay_reg+1 && !overflow) || !En) begin
            $fdisplay (write_data,"Increment error at time %t",  $time); 
            count_err <= 1;
        end
        else begin
            $fdisplay (write_data,"The counter is working correctly at time %t",  $time); 
            count_err <= 0;       
        end           
    end 
end

initial begin 
    forever begin 
        @(nMode_nStep); 
        @(posedge Clk); 
        Mode <=0;
        Step <=0;
        repeat(3) begin
        @(negedge Clk); 
        end     
        -> check_nMode_nStep;
        if(Cnt == 0);           
    end 
end

initial begin 
    forever begin 
        @(check_nMode_nStep); 
        if((Cnt != delay_reg-1 && !overflow) || !En) begin
            $fdisplay (write_data,"Decrement error at time %t",  $time);   
            count_err <= 1;
        end
        else begin
            $fdisplay (write_data,"The counter is working correctly at time %t",  $time); 
            count_err <= 0;       
        end           
    end 
end

/////////////////////////////////////////////////////

/////////////////////////////////////////////////////
//_________Проверка переполнения счетчика_________//
/////////////////////////////////////////////////////

event check_overflow; //Проверка переполнения счетчика   
event check_done_overflow;

always @(negedge Clk)
begin
    if(En) begin
        if(Mode && Step) begin
            if((delay_reg == 7 || delay_reg == 8) && Cnt > 9) 
                ->check_overflow;
            else overflow_err <= 0;    
        end
        if(Mode && !Step) begin
            if(delay_reg == 9 && Cnt > 9) begin
                ->check_overflow;
            end   
            else overflow_err <= 0;  
        end
        if(!Mode && Step) begin
            if((delay_reg == 1 || delay_reg == 2) && Cnt > 9)
                ->check_overflow;
            else overflow_err <= 0;          
        end
        if(!Mode && !Step) begin
            if(delay_reg == 0 && Cnt > 9)
                ->check_overflow; 
            else overflow_err <= 0;  
        end
    end
end

initial begin 
    forever begin 
        @(check_overflow); 
            $fdisplay (write_data,"Error, the counter is overflowed at time %t",  $time);
            overflow_err <= 1;    
        -> check_done_overflow; 
    end 
end
/////////////////////////////////////////////////////

/////////////////////////////////////////////////////
//_____________Проверка сброса счетчика____________//
/////////////////////////////////////////////////////

event reset_cnt;
event reset_done_cnt; 

initial begin 
    forever begin 
        @(reset_cnt); 
        @(posedge Clk); 
            Rst = 1; 
        @(posedge Clk);
        repeat (2) begin 
        @(negedge Clk); 
        end  
        if(Cnt != 0) begin
            $fdisplay(write_data,"Reset error at time %t",  $time);
            reset_err <= 1;
        end 
        else begin
            $fdisplay(write_data,"Correct reset work at time %t",  $time);
            reset_err <= 0;
        end
        @(posedge Clk); 
            Rst = 0; 
        -> reset_done_cnt; 
    end 
end
/////////////////////////////////////////////////////

/////////////////////////////////////////////////////
//____________Тест с ПСЧ воздействиями_____________//
/////////////////////////////////////////////////////

event check_random_signals;
event check_random_signals_done;

initial begin 
    forever begin 
        @(check_random_signals)
        fork
            repeat (20) begin
                @(posedge Clk);
                En = $random; 
            end
            repeat (20) begin
                @(posedge Clk);
                Rst = $random;    
            end
            repeat (20) begin
                @(posedge Clk);
                Mode = $random;    
            end
            repeat (20) begin
                @(posedge Clk);
                Step = $random;    
            end
        join
        -> check_random_signals_done;
    end 
end

/////////////////////////////////////////////////////
//_________Результат тестирования счетчика_________//
/////////////////////////////////////////////////////
event test;

initial begin 
    forever begin 
        @(test)
        if(test_err == 0) $fdisplay (write_data, "Test is done. ERRORS: No %t", $time);
        else              $fdisplay (write_data, "Test is done. ERRORS: Yes %t", $time);
    end 
end

initial begin
    #5
    En <= 1;
    Mode <= 1;
    #full_cycle -> reset_cnt;
    #10   
    #full_cycle -> nMode_pStep;
    #full_cycle -> pMode_pStep;
    #full_cycle -> nMode_nStep;
    #full_cycle -> pMode_nStep;
    #clk_period Rst <= 1;
    #clk_period Rst <= 0;
    #full_cycle -> check_random_signals;
    #clk_period Rst <= 1;
    #clk_period Rst <= 0;
    #clk_period ->test;
    #full_cycle;
    #full_cycle;
    $fclose(write_data);
    $stop;
end

endmodule