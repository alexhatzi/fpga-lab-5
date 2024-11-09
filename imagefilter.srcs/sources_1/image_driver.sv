

module image_driver 
    (   input                  clk
    ,   input                  disp_clk
    ,   input                  vsync
    ,   input                  hsync
    ,   input    logic  [3:0]  digit 
    ,   input                  new_input_flag

    ,   output   logic  [15:0] addra 
    ,   output   logic  [ 7:0] dina  
    ,   input    logic  [ 8:0] douta
    ,   output   logic         wea   
    ,   output   logic  [15:0] addrb 
    ,   input    logic  [ 8:0] doutb 

    ,   output   logic  [15:0] addra2
    ,   input    logic  [8:0 ] douta2

    ,   output   logic  [ 3:0] r_color
    ,   output   logic  [ 3:0] g_color
    ,   output   logic  [ 3:0] b_color
    );

    logic             hsync_d                 ; // Hsync delayed by 1 clk (disp_clk)
    logic [9:0 ]      ypos,xpos               ;
    logic [8:0 ]      pixel_data      [8:0]   ; 
    logic [9:0 ]      row, col                ; 

    logic new_input_flag_d                    ; 
    logic [8:0] filter                        ; 
    logic [15:0]       edit_counter           ; 
    logic vsync_d                             ;
    logic [3:0] delay                         ; 
    logic [15:0] edit_counter_d               ; 

    logic [8:0] buffer                        ; 
    logic [8:0] orig_buffer                   ; 
    logic wea_state                           ; 
    logic wea_state_d                         ; 
    logic [3:0] indexX, indexY, index         ; 
    logic [15:0] saveX, saveY                 ; 
    logic [17:0] combined_pixels              ; 
    logic [9:0] read_pixels                   ; 
    logic [3:0] disp_pixels                   ;


    typedef enum   {WAIT_FOR_NEW_ENTRY,DIGIT,EDIT1,EDIT2,EDIT3,EDIT4,EDIT5,EDIT6,EDIT7,EDIT8,REINIT,REINIT2,DONE} lpf_state_t ;   
    lpf_state_t LPF_STATE ; 




    initial begin
    ypos          = 0 ; 
    xpos          = 0 ;
    row           = 0 ; 
    col           = 0 ; 
    filter        = 9'b100000000; 
    edit_counter  = '0 ; 
    delay         = '0 ; 
    buffer        = '0 ;
    index         = '0 ; 
    end



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



always @ ( posedge disp_clk) begin 
            wea_state_d      <= wea_state ; 
            new_input_flag_d <= new_input_flag ; 
            vsync_d          <= vsync          ;
            case (LPF_STATE)  
            WAIT_FOR_NEW_ENTRY :   begin
                                        if (new_input_flag && !new_input_flag_d) begin
                                                LPF_STATE  <= DIGIT       ; 
                                                r_color    <= 4'b0000     ; 
                                                g_color    <= 4'b0000     ; 
                                                b_color    <= 4'b0000     ; 
                                        end else begin
                                        if ((xpos < 448) && (xpos > 192) && (ypos < 368) && (ypos > 112)) begin
                                        edit_counter <= edit_counter + 1'b1 ; 
                                        addrb        <= ((xpos-192) * 256) + (ypos - 112)  ; 
                                        r_color      <=  buffer[8:5]                       ; 
                                        g_color      <=  buffer[8:5]                       ; 
                                        b_color      <=  buffer[8:5]                       ; 
                                        end                                         
                                        else begin
                                        r_color    <= 4'b0000     ; 
                                        g_color    <= 4'b0000     ; 
                                        b_color    <= 4'b0000     ; 
                                        end
                                        end
                                    end
            DIGIT               : begin
                                    if (digit == 1) begin
                                        LPF_STATE <= EDIT1  ; 
                                    end else
                                    if (digit == 5) begin
                                        LPF_STATE <= REINIT ; 
                                    end
                                  end
            EDIT1               : begin
                                        LPF_STATE <= EDIT2  ; 
                                  end
            EDIT2               : begin
                                    if (hsync && !hsync_d) begin // start of frame
                                            LPF_STATE <= EDIT3 ; 
                                        end 
                                   end

            EDIT3               : begin
                                        addra             <= '0    ;  
                                        saveX             <= '0    ;  
                                        saveY             <= '0    ;  
                                        LPF_STATE         <= EDIT4 ;  
                                      end
            EDIT4               : begin                         // Scanning 1st 3 pixels in first row
                                        if (indexY < 3) begin
                                            if (indexX < 3) begin
                                            indexX     <= indexX + 1 ; 
                                            index      <= index  + 1 ;
                                            addra             <= ((saveX+indexX) * 256) + (saveY+indexY)  ; 
                                            pixel_data[index] <= douta ; 
                                        end 
                                        else  begin 
                                            indexY <= indexY + 1 ; 
                                            indexX <= '0         ; 
                                        end
                                        end
                                        else begin
                                            LPF_STATE <= EDIT5;
                                        end
                                  end
            EDIT5               : begin         // If above filter value, write combined pixel number
                                    combined_pixels <= ((pixel_data[0] + pixel_data[1] + pixel_data[2] + pixel_data[3] + pixel_data[4] + pixel_data[5] + pixel_data[6] + pixel_data[7] + pixel_data[8])*7) >>6 ;
                                    LPF_STATE <= EDIT6 ; 
                                  end
            EDIT6               : begin
                                    indexX    <= '0     ;
                                    indexY    <= '0     ; 
                                  if ( combined_pixels > filter) begin
                                        addra             <= ((saveX+index) * 256) + saveY ; 
                                        LPF_STATE         <= EDIT7 ; 
                                        index             <= 1     ; 
                                  end else begin
                                    index     <= '0    ; 
                                    LPF_STATE <= EDIT8 ; // dont edit any data 
                                  end

                                  end
            EDIT7               : begin         // Writing 1st 3 pixels in 1st row 
                                      if (indexY < 3) begin
                                            if (indexX < 3) begin
                                            indexX     <= indexX + 1                               ; 
                                            index      <= index  + 1                               ;
                                            addra      <= ((saveX+indexX) * 256) + (saveY+indexY)  ; 
                                            dina       <= combined_pixels ;  
                                            wea_state  <= ~wea_state      ; 
                                        end 
                                        else  begin 
                                            indexY <= indexY + 1 ; 
                                            indexX <= '0         ; 
                                        end
                                        end
                                        else begin
                                            LPF_STATE <= EDIT8;
                                            indexX    <= '0   ; 
                                            indexY    <= '0   ; 
                                            index     <= '0   ; 
                                        end
                                  end        
            EDIT8               : begin        
                                        if ( saveX >= 255 ) begin
                                            if (saveY >= 255 ) begin
                                                LPF_STATE <= DONE ; 
                                                filter    <= filter >> 1 ; 
                                         end else
                                         begin
                                         saveY <= saveY + 3 ;  
                                         saveX <= 0 ; 
                                         LPF_STATE <= EDIT4 ; 
                                         index     <= '0    ; 
                                         end
                                        end
                                        else begin
                                            LPF_STATE       <= EDIT4 ; 
                                            index           <= '0    ; 
                                            saveX           <= saveX + 3 ; 
                                        end
                                   end
            REINIT             : begin
                                    if (!vsync && vsync_d) begin
                                    LPF_STATE <= REINIT2 ; 
                                    edit_counter <= '0   ; 
                                   end
                                    
                                 end

            REINIT2             :  begin
                                        if ((xpos < 448) && (xpos > 192) && (ypos < 368) && (ypos > 112)) begin
                                            edit_counter <= edit_counter + 1'b1 ; 
                                            addra2 <= ((xpos-192) * 256) + (ypos - 112) - 256 ; 
                                            addra  <= ((xpos-191) * 256) + (ypos - 112) - 256 ; 
                                            dina   <= orig_buffer ; 
                                            wea_state <= ~wea_state ; 
                                            filter  <= 9'b100000000; 
                                            if (edit_counter == 16'hffff)
                                            LPF_STATE <= DONE ;                                
                                        end
                                      end

            DONE               :
                                begin
                                edit_counter <= '0 ;
                                saveX        <= '0 ; 
                                saveY        <= '0 ; 
                                LPF_STATE <= WAIT_FOR_NEW_ENTRY ; 
                                end

            default            :  LPF_STATE <= WAIT_FOR_NEW_ENTRY ; 
     endcase

end


    always @ ( posedge clk) begin
        edit_counter_d <= edit_counter ; 
        read_pixels    <= doutb  ; 
        orig_buffer    <= douta2 ; 

        if (edit_counter != edit_counter_d) 
        buffer      <= doutb  ; 

        if (wea_state != wea_state_d) begin
            wea <= '1 ; 
        end else
        wea <= '0 ; 

    end 









endmodule 