
module display_driver 
   # ( parameter PIXELS_PER_ROW    = 640
     , parameter PIXELS_PER_COLUMN = 480
     , parameter A_CLKS            = 800    // HORZ SYNC    PULSE
     , parameter B_CLKS            = 96     // HORZ PULSE   WIDTH
     , parameter C_CLKS            = 48     // HORZ BACK    PORCH
     , parameter D_CLKS            = 640    // HORZ DISPLAY TIME 
     , parameter E_CLKS            = 16     // HORZ BACK    PORCH 
     , parameter O_CLKS            = 416800 // VERT SYNC    PULSE (P EDGE -> P EDGE)
     , parameter P_CLKS            = 1600   // VERT PULSE   WIDTH
     , parameter Q_CLKS            = 23200  // VERT BACK    PORCH (FIRST PORCH)
     , parameter R_CLKS            = 384000 // VERT DISP    TIME
     , parameter S_CLKS            = 8000   // VERT FRONT   PORCH
     )
     ( input              slowclk
     , input  logic [3:0] r_color
     , input  logic [3:0] g_color 
     , input  logic [3:0] b_color
     , output logic [3:0] red
     , output logic [3:0] green
     , output logic [3:0] blue
     , output logic       H_SYNC
     , output logic       V_SYNC
     , output logic    rgb_active

     );

          // ┌────────────────────────────────────────────────────────────────────────┐    
          // │             35 Lines/Rows of the back porch                            │    
          // │                                                                        │    
          // │               ┌─────────────────────────────────────────────────┐      │    
          // │               │Visible Display                                  │      │    
          // │ 144 pixels:   │                                                 │      │    
          // │  96 w/ HSYNC  │ <------------------------640------------->      │      │    
          // │  low          │ ^                                               │      │    
          // │               │ |                                               │      │    
          // │  48 pixels    │ |                                               │      │    
          // │  while HSYNC  │ |                                               │      │    
          // │  high         │ |                                               │      │    
          // │               │ |                                               │      │    
          // │               │ |                                               │      │    
          // │               │ |                                               │      │    
          // │               │ |                                               │      │    
          // │               │ |                                               │      │    
          // │               │ 480                                             │      │    
          // │               │ |                                               │      │    
          // │               │ |                                               │      │    
          // │               │ |                                               │      │    
          // │               │ |                                               │      │    
          // │               │ |                                               │      │    
          // │               │ |                                               │      │    
          // │               │ |                                               │      │    
          // │               │ V                                               │      │    
          // │               └─────────────────────────────────────────────────┘      │    
          // │                                                                        │    
          // │                                                                        │    
          // │                                                                        │    
          // └────────────────────────────────────────────────────────────────────────┘    


          //    VSYNC   and HSYNC are Driven Seperately 
          //    RGB is timed and driven from VSYNC and HSYNC

    typedef enum logic  [2:0] {HIDLE,HWAIT,HSYNC}   HSYNC_t ; 
    typedef enum logic  [2:0] {VIDLE,VWAIT,VSYNC}   VSYNC_t ; 

    logic [20:0] v_counter ; 
    logic [20:0] h_counter ;  // big enough reg to hold the largest number
    logic [20:0] c_cnt     ; 
    logic [20:0] d_cnt     ;
    logic [20:0] e_cnt     ; 
    HSYNC_t      HSYNC_STATE ; 
    VSYNC_t      VSYNC_STATE ;

    initial v_counter = '0  ;
    initial h_counter = '0  ; 
    initial c_cnt     = '0  ;
    initial d_cnt     = '0  ; 
    initial e_cnt     = '0  ; 



    // HSYNC state machine 
    always @(posedge slowclk) begin
        case (HSYNC_STATE)
            HIDLE : begin
                    HSYNC_STATE <= HWAIT ; 
                    h_counter   <= 0     ; 
            end
            HWAIT : begin
                if (h_counter == B_CLKS - 1) begin  
                    HSYNC_STATE <= HSYNC ; 
                    H_SYNC      <= 1'b1  ;  
                    h_counter   <= '0    ;
                end else
                    h_counter <= h_counter + 1 ;
            end
            HSYNC : begin
                if (h_counter == C_CLKS + D_CLKS + E_CLKS - 1) begin  // End of visible region and porches
                    HSYNC_STATE <= HWAIT;
                    H_SYNC <= 1'b0 ;  
                    h_counter <= 0 ;
                end else
                    h_counter <= h_counter + 1;
            end
          default : begin 
                    HSYNC_STATE <= HIDLE ;
                    h_counter   <= '0    ; 
          end 
        endcase
    end




    // VSYNC state machine 
    always @(posedge slowclk) begin
        case (VSYNC_STATE)
            VIDLE: begin
                    VSYNC_STATE <= VWAIT;
                    v_counter <= 0; 
            end
            VWAIT: begin
                if (v_counter == P_CLKS - 1) begin  
                    V_SYNC <= 1'b1;  // De-assert VSYNC
                    VSYNC_STATE <= VSYNC;
                    v_counter <= 0;
                end else
                    v_counter <= v_counter + 1;
            end
            VSYNC: begin
                if (v_counter == Q_CLKS + R_CLKS + S_CLKS - 1) begin  // End of the active time + porches
                    VSYNC_STATE <= VWAIT;
                    V_SYNC <= 1'b0;  // Assert VSYNC (sync pulse)
                    v_counter <= 0;
                end else
                    v_counter <= v_counter + 1;
            end
          default : 
                     VSYNC_STATE <= VIDLE ; 
        endcase
    end


  // RGB Driver
    always@(posedge slowclk) begin
      if(V_SYNC) begin
        if(H_SYNC) begin  // When HSYNC high
          if (c_cnt == (C_CLKS-1)) begin // Wait for hold time
            if (d_cnt == (D_CLKS-1)) begin // Drive RGB values in active region
                if (e_cnt == (E_CLKS-1)) begin // Stop after D time
                    red    [3:0] <= '0 ;
                    green  [3:0] <= '0 ; 
                    blue   [3:0] <= '0 ; 
                    rgb_active  <= 1'b0;
                end 
                else e_cnt <= e_cnt + 1'b1 ; 
            end
            else begin
            d_cnt       <= d_cnt + 1'b1     ; 
            red   [3:0] <= r_color [3:0]    ; 
            green [3:0] <= g_color [3:0]    ; 
            blue  [3:0] <= b_color [3:0]    ; 
            rgb_active  <= 1'b1             ;
            end
          end 
          else begin
          c_cnt       <= c_cnt + 1'b1 ; 
          end
        end 
        else begin
        c_cnt   <= '0 ; 
        d_cnt   <= '0 ; 
        e_cnt   <= '0 ; 
        end
    end
  end



endmodule
