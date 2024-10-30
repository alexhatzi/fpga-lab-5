`timescale 1ns / 1ps
`timescale 1ns / 1ps

module top_sim;
    // Inputs
    logic clk;
    logic kbd_data ; 
    logic kbd_clk  ; 

    // Outputs
    logic [3:0] red;
    logic [3:0] green;
    logic [3:0] blue;
    logic       hsync  ;
    logic       vsync  ;

    lab5_top uut 
    (   .clk         (clk)
    ,   .KBD_CLK     (kbd_clk)
    ,   .KBD_DATA    (kbd_data)
    ,   .red         (red)
    ,   .green       (green)
    ,   .blue        (blue)
    ,   .hsync       (hsync)
    ,   .vsync       (vsync)
    );


    always #5 clk = ~clk; 

initial begin
        #500us
    #20us
    kbd_data = '1 ; 
    #100
    kbd_data = '0 ;         // start condition
    #10 
    kbd_data = '0 ;         // 0010
    #10 
    kbd_data = '1 ; 
    #10 
    kbd_data = '1 ; 
    #10 
    kbd_data = '0 ; 
    #10 
    kbd_data = '1 ;         // 0110
    #10
    kbd_data = '0 ; 
    #10 
    kbd_data = '0 ; 
    #10 
    kbd_data = '0 ; 
    #10             
    kbd_data = '0 ; // Odd parity bit
    #10 
    kbd_data = '1 ; // stop condition
    #10
    kbd_data = '0 ;
end

initial clk = 0 ; 


initial begin
    #500us
    #20us
    #100
    kbd_clk = '1 ; 
    #5
    kbd_clk = '0 ; 
    #5
    kbd_clk = '1 ; 
    #5
    kbd_clk = '0 ; 
    #5
    kbd_clk = '1 ; 
    #5
    kbd_clk = '0 ; 
    #5
    kbd_clk = '1 ; 
    #5
    kbd_clk = '0 ; 
    #5
    kbd_clk = '1 ; 
    #5
    kbd_clk = '0 ; 
    #5
    kbd_clk = '1 ; 
    #5
    kbd_clk = '0 ; 
    #5
    kbd_clk = '1 ; 
    #5
    kbd_clk = '0 ; 
    #5
    kbd_clk = '1 ; 
    #5
    kbd_clk = '0 ; 
    #5
    kbd_clk = '1 ; 
    #5
    kbd_clk = '0 ; 
    #5
    kbd_clk = '1 ; 
    #5
    kbd_clk = '0 ; 
    #5
    kbd_clk = '1 ; 
    #5
    kbd_clk = '0 ; 
    #5
    kbd_clk = '1 ; 


end


endmodule

