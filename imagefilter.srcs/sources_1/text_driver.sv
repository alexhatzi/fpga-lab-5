

module text_driver (
    input               clk
,   input               slowclk
,   input               rgb_active
,   output logic [11:0]  addra 
,   input        [24:0] douta
,   input        [3:0]  digit
,   input               hsync 
,   input               vsync
,   output  logic [3:0] r_color
,   output  logic [3:0] g_color
,   output  logic [3:0] b_color
) ; 

    logic [20:0]      clk_cnt                 ; // Index through the actual pixel data (pixels) when driving
    logic             hsync_d                 ; // Used to drive active_row_cnt by detecting when   
    logic [9:0 ]      active_row_cnt          ; // Index through the actual pixel data (rows) when driving
    logic [9:0 ]      row_cnt                 ;
    logic [24:0]      pixel_data[15:0][7:0]   ; 
    logic [7:0 ]      row,pix                 ; // Index through to write to pixel_data
    logic [6:0 ]      delay_counter           ;  
    logic             debug                   ; 
    logic [3:0]       digit_d                 ;

    typedef enum logic  [1:0] {NEW,STALE}   DIGIT_t ; 
    DIGIT_t DIGIT_STATUS ;

    initial delay_counter  = '0  ; 
    initial debug          = '0  ; 
    initial clk_cnt        = '0  ; 
    initial active_row_cnt = '0  ; 
    initial row            = '0  ; 
    initial pix            = '0  ; 



// Row Counting State Machine
// row_cnt tracks number of lines (a lot of this logic is repeated in h_driver in the display driver)
// active_row_cnt tracks number of lines starting from first visible line.  
    always@( posedge clk ) begin                  // Drive active_row_cnt (row counter) on positive edge of hsync, reset once VSYNC goes low
        if (vsync) begin    
         hsync_d <= hsync ; 
            if(hsync & !hsync_d)  begin          // posedge of hsync , increment row counter
                row_cnt        <= row_cnt + 1'b1              ; 
            end 

            if (row_cnt >  38)    begin                   // after back porch (35 lines of porch + 2 lines while VSYNC is low)          
                active_row_cnt <= active_row_cnt + 1'b1 ; // line "38" == active row "0"
            end else 
                active_row_cnt <= '0                    ;
        end 
        else begin
        active_row_cnt <= '0 ; 
        row_cnt        <= '0 ; 
        end
    end



    // There is probably a much better way of doing this, but thankfully since the front porch exists, we have a few μs to capture 
    // and buffer the font data stored at different address locations in BRAM
    // I am not 100% confident this is the actual intended memory map but this is what I'm working with:
    // Each address stores 1 pixel (4 bits each for R,G,B)
    // Each digit is 128 pixels, I'm assuming 16 x 8. 
    // so '0' digit pixel data inhabits locations 0-127
    //  ┌──────────────────┐ 
    //  │0,1,2,..........15│ 
    //  │16,17,18......... │ 
    //  │.                 │ 
    //  │.                 │ 
    //  │.                 │ 
    //  │.                 │ 
    //  │.                 │ 
    //  │.                 │ 
    //  │.                 │ 
    //  │.                 │ 
    //  │.                 │ 
    //  │112............128│ 
    //  └──────────────────┘ 

    //  this digit status state machine is completely unncessary, but occasionally theres flickering in the digits
    // I think because the value in the buffer is changing at the same time it's being read from so this just reduces the rate 
    // that occurs at because the buffer wont update unless the digit value changes

    always @(posedge clk) begin
        digit_d <= digit;
        case (DIGIT_STATUS)

            NEW: 
                if (row < 16) begin
                    if (pix < 8) begin
                        addra <= ((digit * 128) + row * 8 + pix) ; // idk if this formula is right
                        if (delay_counter < 6'd5) begin            // Delay reading the output for at least 2 clock cycles, there is a 2 cycle latency in the IP
                            delay_counter        <= delay_counter + 1'b1 ;
                        end else begin
                            pixel_data[row][pix] <= douta[0]   ;     // After BRAM output is stable pipe it to the corresponding buffer
                            delay_counter        <= '0         ;
                            pix                  <= pix + 1'b1 ;
                            debug                <= ~debug     ;
                        end
                       end else begin
                            pix                  <= '0         ;
                            row                  <= row + 1'b1 ;
                       end
                    end else begin
                            row                  <= '0         ;
                            pix                  <= '0         ;
                            DIGIT_STATUS         <= STALE      ;
                end

            STALE: 
                if (digit_d != digit)
                    DIGIT_STATUS <= NEW ;

            default: 
                DIGIT_STATUS <= NEW ;

        endcase
    end

    


    // Actually drive the color data the display driver uses, this MUST be driven off 
    // 25 MHz clock along with the display driver, otherwise using the native 100MHz downscaled will skip pixel data
    always @ (posedge slowclk) begin
        if(rgb_active) begin
         clk_cnt <= clk_cnt + 1'b1 ;
                if(active_row_cnt <= 21'd15) begin                                     
                    if ((clk_cnt >= 21'd10) && (clk_cnt <= 21'd17)) begin              // added a 10 pixel pixel cushion off the left 
                        if (pixel_data[active_row_cnt][clk_cnt-10] != '0 ) begin    
                                    r_color <= 4'b0000   ;  
                                    g_color <= 4'b1111   ;
                                    b_color <= 4'b1111   ; 
                        end
                        else begin
                                    r_color <= 4'b0001 ;        // All these repeating elses wouldn't be necessary
                                    g_color <= 4'b0001 ;        // if it was all one really long if statement 
                                    b_color <= 4'b0001 ;        // this is for pixel values that are = 0 
                        end
                    end
                    else begin
                                    r_color <= 4'b0001 ;        // pixels 13-640 of the first 16 rows
                                    g_color <= 4'b0001 ;
                                    b_color <= 4'b0001 ; 
                    end
                end
                else begin
                                    r_color <= 4'b0001 ;        // these basically lines 17-480 of the visible display
                                    g_color <= 4'b0001 ;
                                    b_color <= 4'b0001 ; 

                end
        end else
        clk_cnt <= '0 ; 
    end


endmodule