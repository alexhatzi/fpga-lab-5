

module image_driver 
    (   input                  clk
    ,   input                  disp_clk
    ,   input                  vsync
    ,   input                  hsync
    ,   input    logic  [3:0]  digit 
    ,   input                  new_input_flag
    ,   output   logic         clear_flag

    ,   output   logic  [15:0] addra 
    ,   output   logic  [ 7:0] dina  
    ,   input    logic  [ 7:0] douta
    ,   output   logic         wea   
    ,   output   logic  [15:0] addrb 
    ,   input    logic  [ 7:0] doutb 

    ,   output   logic  [ 3:0] r_color
    ,   output   logic  [ 3:0] g_color
    ,   output   logic  [ 3:0] b_color
    );

    logic             hsync_d                 ; // Hsync delayed by 1 clk (disp_clk)
    logic [9:0 ]      ypos,xpos               ;
    logic [7:0 ]      pixel_data              ; 
    logic [9:0 ]      row, col                ; 

    initial begin
    ypos          = 0 ; 
    xpos          = 0 ;
    row           = 0 ; 
    col           = 0 ; 
    end

    // initial delay_counter = 0 ; 
    // initial clear_flag    = 0 ; 


    // Row (Y) Counter
    always@( posedge disp_clk ) begin      
        hsync_d <= hsync           ;          
        if (vsync) begin    
         if(hsync & !hsync_d)  begin                  
                row <= row + 1'b1  ; 
         end 
        end 
        else    row <= '0          ;  
        // Pix (X) counter
        if (hsync) begin
                col <= col + 1'b1  ;
        end 
        else    col <= '0          ; 
    end

    always@ (posedge disp_clk) begin
        if (vsync) begin
         if(hsync & !hsync_d)  begin                  

            if ((row >= 33) && (row <= 515)) begin       // Values come from the  porches
                ypos <= ypos + 1 ; 
            end else  begin
            ypos <= 0 ; 
            end
         end
         if ((col >= 48) && (col <= 784)) begin
                xpos <= xpos + 1 ; 
            end else begin
            xpos <= '0 ; 
            end
        end
    end

      logic delay            ;  
      logic new_input_flag_d ; 

    

    typedef enum  {WAIT_FOR_NEW_ENTRY,EDIT,DONE} lpf_state_t ;   
    lpf_state_t LPF_STATE ; 

always @ ( posedge disp_clk) begin 
            new_input_flag_d <= new_input_flag ; 
            case (LPF_STATE) 
            WAIT_FOR_NEW_ENTRY :
                                 if(new_input_flag && !new_input_flag_d) begin
                                    LPF_STATE <= EDIT ; 
                                 end
            EDIT               : 
                                if ( digit == 1 ) begin
                                    if ((xpos < 449) && (xpos > 193) && (ypos < 368) && (ypos > 112)) begin
                                        addra   <= ((xpos-192) * 256) + (ypos - 112) - 256 ; 
                                        wea     <= '0                                      ;
                                        delay   <= '1                                      ;
                                        if (delay) begin
                                            if ( douta >= 4'b0011) begin
                                            dina           <= douta >> 1        ;
                                            wea            <= '1                ;
                                            end
                                        delay          <= '0                ; 
                                        end
                                        if (xpos == 448 && ypos == 366   ) begin
                                            LPF_STATE <= DONE  ; 
                                            end
                                    end
                                end

            DONE               :begin
                                delay     <= '0                 ; 
                                wea       <= '0                 ; 
                                LPF_STATE <= WAIT_FOR_NEW_ENTRY ; 
                                end

            default            :  LPF_STATE <= WAIT_FOR_NEW_ENTRY ; 
     endcase
end


    always @ ( posedge clk) begin
        pixel_data <= doutb  ; 
    end 

    // Image Driver
    always@(posedge disp_clk) begin
            if ((xpos < 448) && (xpos > 192) && (ypos < 368) && (ypos > 112)) begin
            addrb      <= ((xpos-192) * 256) + (ypos - 112)  ; 
            r_color    <= pixel_data [7:4]     ; 
            g_color    <= pixel_data [7:4]     ; 
            b_color    <= pixel_data [7:4]     ; 
            end else begin
            r_color    <= 4'b1001     ; 
            g_color    <= 4'b1000     ; 
            b_color    <= 4'b1101     ; 
            end
    end








endmodule 