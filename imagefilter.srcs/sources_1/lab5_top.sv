`timescale 1ns / 1ps



module lab5_top 
        ( input              clk
        , input              KBD_CLK
        , input              KBD_DATA
        , output logic       debugBUT_LED
        , output logic       debugDISP_LED
        , output logic [3:0] red
        , output logic [3:0] green
        , output logic [3:0] blue
        , output logic       hsync
        , output logic       vsync
        , output logic [3:0] digit      
        ) ; 

        logic rgb_active         ; 
        logic dvld               ; 
        logic [7:0] key          ;
        logic [1:0] error_detect ; 
        logic [2:0] state_detect ; 
        logic [3:0] bit_loc      ;
        logic       slowclk      ; 

        logic [3:0] r_color      ; 
        logic [3:0] g_color      ; 
        logic [3:0] b_color      ; 

        logic [11:0] addra       ; 
        logic [24:0] douta       ; 

        always @ (posedge u_text_driver.debug) begin
        debugBUT_LED <=  ~debugBUT_LED ;
        end 

        always@ (posedge clk) begin
        if(rgb_active)
        debugDISP_LED <= ~debugDISP_LED ; 
         end

        initial begin
                debugBUT_LED = 0 ; 
                debugDISP_LED = 0 ;
        end



        clk_divider #( .CLK_COUNT(2)) u_clk_divider // 25 Mhz for VGA standard
                (       .clk            (clk)
                ,       .sample_clk     (slowclk)
                ) ;


        display_driver u_disp_driv 
                (       .slowclk        (slowclk)
                ,       .r_color        (r_color)
                ,       .g_color        (g_color)
                ,       .b_color        (b_color)
                ,       .red            (red)
                ,       .blue           (green)
                ,       .green          (blue)
                ,       .H_SYNC         (hsync)
                ,       .V_SYNC         (vsync)
                ,       .rgb_active     (rgb_active)
                ) ;




        ps2input u_ps2_inp
                (       .clk            (clk)
                ,       .kbd_clk        (KBD_CLK)
                ,       .kbd_data       (KBD_DATA)
                ,       .key            (key)
                ,       .dvld           (dvld)
                ,       .error_detect   (error_detect)
                ,       .state_detect   (state_detect)
                ,       .bit_loc        (bit_loc)
                ) ; 


        ps2decoder u_ps2_dec
                (       .clk            (clk)
                ,       .key            (key)
                ,       .dvld           (dvld)
                ,       .digit          (digit)
                ) ; 


        text_driver u_text_driver
                (       .clk            (clk)
                ,       .slowclk        (slowclk)
                ,       .rgb_active     (rgb_active)
                ,       .addra          (addra)
                ,       .douta          (douta)
                ,       .digit          (digit)
                ,       .vsync          (vsync)
                ,       .hsync          (hsync)
                ,       .r_color        (r_color)
                ,       .g_color        (g_color)
                ,       .b_color        (b_color)
                ) ; 


        
        BLK_MEM_ROM   u_BLK_MEM_ROM 
                (       .clka           (clka)     // input wire clka
                ,       .ena            (ena)      // input wire ena
                ,       .addra          (addra)    // input wire [15 : 0] addra
                ,       .douta          (douta)    // output wire [7 : 0] douta
                );


        DUAL_PORT_BRAM u_DUAL_PORT_BRAM 
                  (      .clka           (clka)    // input wire clka
                  ,      .ena            (ena)     // input wire ena
                  ,      .wea            (wea)     // input wire [0 : 0] wea
                  ,      .addra          (addra)   // input wire [15 : 0] addra
                  ,      .dina           (dina)    // input wire [7 : 0] dina
                  ,      .clkb           (clkb)    // input wire clkb
                  ,      .enb            (enb)     // input wire enb
                  ,      .addrb          (addrb)   // input wire [15 : 0] addrb
                  ,      .doutb          (doutb)   // output wire [7 : 0] doutb
                  );



        // ila_0 u_ila (
        //         .clk (clk)
        // ,       .probe0 (clka)
        // ,       .probe1 (KBD_CLK)
        // ,       .probe2 (KBD_DATA)
        // ,       .probe3 (debugBUT_LED)
        // ,       .probe4 (debugDISP_LED)
        // ,       .probe5 (red)
        // ,       .probe6 (green)
        // ,       .probe7 (blue)
        // ,       .probe8 (hsync)
        // ,       .probe9 (vsync)
        // ) ; 

endmodule






















 




