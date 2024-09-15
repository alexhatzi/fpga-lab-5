
module clk_divider  #(CLK_COUNT = 12500000)
( 
     input clk 
  ,  output logic sample_clk
) ; 


reg [24:0] clkcount ; 

initial clkcount = 0 ; 
initial sample_clk = 0 ; 


always@(posedge clk) begin
    if (clkcount == CLK_COUNT - 1 ) begin
      sample_clk <= ~sample_clk ; 
        clkcount <= '0 ; 
     end else begin
        clkcount = clkcount + 1'b1 ; 
     end
end



endmodule 