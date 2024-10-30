

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
        if (vsync) begin    
             hsync_d <= hsync       ; 
         if(hsync & !hsync_d)  begin                  
                row <= row + 1'b1   ; 
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
            if ( (row > 35) && (col > 144)) begin       // Values come from the back porches
                xpos <= col - 144 ;  
                ypos <= row - 35  ; 
            end
        end else begin
            xpos <= '0 ; 
            ypos <= '0 ; 
        end
    end

    //   logic [6:0 ]      delay_counter           ;  

    // LPF when new input detected
    // always@(posedge clk) begin
    //     if ( digit == 1 ) begin
    //         if ( new_input_flag ) begin
    //             if ( (ypos <= 640) & (xpos <= 480) ) begin
    //                 wea   <= 1'b0                           ;
    //                 if (delay_counter > 2) begin
    //                     dina           <= douta >> 1        ;
    //                     wea            <= 1'b1              ;
    //                     xpos           <= xpos + 1'b1       ;
    //                     if (xpos == 480) begin
    //                         xpos       <= '0                ; 
    //                         if(ypos == 640) begin
    //                             clear_flag <= 1'b1          ; 
    //                             ypos      <= '0             ;
    //                         end
    //                         else ypos <= ypos + 1'b1        ; 
    //                     end 
    //                     delay_counter <= '0                 ;
    //                 end
    //                 else delay_counter <= delay_counter + 1'b1 ; 
    //             end
    //         end
    //     end
    // end

    always @ ( posedge clk) begin
        pixel_data <= douta  ; 
    end 

    // Image Driver
    always@(posedge disp_clk) begin
            addra      <= (xpos * 480) + ypos  ; 
            r_color    <= pixel_data [7:4]     ; 
            g_color    <= pixel_data [7:4]     ; 
            b_color    <= pixel_data [7:4]     ; 
    end








endmodule 