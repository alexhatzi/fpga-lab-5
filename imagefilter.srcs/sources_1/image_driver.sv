

module image_driver 
    (   input                  clk
    ,   input                  disp_clk
    ,   input                  vsync
    ,   input                  hsync
    ,   input                  rgb_active
    ,   input                  new_input_flag
    ,   output   logic         clear_flag
    ,   output   logic  [15:0] addra 
    ,   output   logic  [ 7:0] dina  
    ,   output   logic         wea   
    ,   output   logic  [15:0] addrb 
    ,   input    logic  [ 7:0] doutb 
    ,   output   logic  [ 3:0] r_color
    ,   output   logic  [ 3:0] g_color
    ,   output   logic  [ 3:0] b_color
    );

    logic [9:0 ]      active_row_cnt          ; // Index through the actual pixel data (rows) when driving
    logic             hsync_d                 ; // Used to drive active_row_cnt by detecting when   
    logic [20:0]      row,pix                 ; // Index through to write to pixel_data
    logic [6:0 ]      delay_counter           ;  
    logic             debug                   ; 
    logic [20:0]      redit,pedit             ;
    logic [7:0 ]      pixel_data              ; 


    always@( posedge clk ) begin                     // Drive active_row_cnt (row counter) on positive edge of hsync, reset once VSYNC goes low
        if (vsync) begin    
         hsync_d <= hsync                     ; 
            if(hsync & !hsync_d)  begin                   // posedge of hsync , increment row counter
                row            <= row + 1'b1  ; 
            end 

            if (row >  36)    begin                       // after back porch (35 lines of porch + 2 lines while VSYNC is low)          
                active_row_cnt <= active_row_cnt + 1'b1 ; // line "38" == active row "0"
            end else 
                active_row_cnt <= '0          ;
        end 
        else begin
                active_row_cnt <= '0          ; 
                row            <= '0          ; 
        end
    end


    // // LPF when new input detected
    // always@(posedge clk) begin
    //     if (!rgb_active) begin
    //         if (new_input_flag) begin
    //             if ((redit < 640) & (pedit < 480)) begin
    //                 addrb <= (redit * 640) + pedit          ; 
    //                 addra <= (redit * 640) + pedit          ; 
    //                 wea   <= 1'b0                           ;
    //                 if (delay_counter > 2) begin
    //                     dina           <= doutb >> 1        ;
    //                     wea            <= 1'b1              ;
    //                     pedit          <= pedit + 1'b1      ;
    //                     if (pedit == 480) begin
    //                         pedit      <= '0                ; 
    //                         if(redit == 640) begin
    //                             clear_flag <= 1'b1          ; 
    //                             redit      <= '0            ;
    //                         end
    //                         else redit <= redit + 1'b1      ; 
    //                     end 
    //                     delay_counter <= '0                 ;
    //                 end
    //                 else delay_counter <= delay_counter + 1'b1 ; 
    //             end
    //         end
    //     end
    // end



    // Image Driver
    always@(posedge disp_clk) begin
        if(rgb_active) begin
            pix        <= pix + 1'b1 ;
            addrb      <= ((row-35) * 640) + pix ; 
            pixel_data <= doutb                        ; // Only one pipeline is needed since the bram itself is driven by 100MHz clk, and this logic is 
            r_color    <= pixel_data[3:0]              ; 
            g_color    <= pixel_data[3:0]              ; 
            b_color    <= pixel_data[3:0]              ; 
        end
        else pix <= '0 ; 
    end








endmodule 