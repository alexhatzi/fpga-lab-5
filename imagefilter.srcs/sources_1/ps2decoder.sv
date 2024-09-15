
module ps2decoder (
    input               clk
   ,input  logic [7:0]  key
   ,input               dvld
   ,output logic [3:0]  digit
);



    always@(posedge clk) begin
  if(dvld) begin
            case (key)
              8'h45   : digit = 4'd0   ;
              8'h16   : digit = 4'd1   ;
              8'h1E   : digit = 4'd2   ; 
              8'h26   : digit = 4'd3   ;
              8'h25   : digit = 4'd4   ; 
              8'h2E   : digit = 4'd5   ; 
              8'h36   : digit = 4'd6   ;
              8'h3D   : digit = 4'd7   ; 
              8'h3E   : digit = 4'd8   ;
              8'h46   : digit = 4'd9   ;  
              8'h5A   : digit = 4'd11  ;     // Enter key
            default   : digit = 4'd10  ;     // Used to trigger decoder condition to indicate error
            endcase
        end
    end




initial digit = '0 ; 


endmodule 