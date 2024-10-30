

module ps2input( 
     input              clk   
    ,input              kbd_clk
    ,input              kbd_data
    ,output logic [7:0] key           // 8 bit keyboard input (partiy bit stripped)
    ,output logic       dvld          // If parity bit matches, dvld is high
    ,output logic [1:0] error_detect
    ,output logic       new_input_flag
    ,input  logic       clear_flag
    ,output logic [3:0] bit_loc
    );

    logic [8:0] kbd_buffer ; 
    logic       kbd_clk_d  ;       // KBD CLK Delay (used to capture negative edge)

    typedef enum  {IDLE,ACTIVE,STOP} kbd_state_t ;   
    kbd_state_t KBD_STATE ; 

    initial begin
    bit_loc   = '0        ; 
    KBD_STATE = IDLE      ; 
    end


    always@(negedge clk)                
    kbd_clk_d <= kbd_clk ; // keyboard clock delayed by 1 system clk, used to check rising/falling edge 

    always @(negedge kbd_clk) begin
        case (KBD_STATE)
            IDLE :  begin 
                    dvld         <= 1'b0   ;  
                    error_detect <= 2'b00  ; 
                    if (kbd_data == 1'b0 && kbd_clk_d == 1'b1) begin  // Check both kbd_data and previous kbd_clk
                    KBD_STATE    <= ACTIVE ;  
                    end
            end

            ACTIVE : begin
                new_input_flag <= 1'b1 & clear_flag ; 
                if (bit_loc < 4'd9) begin
                    kbd_buffer[bit_loc] <= kbd_data;  
                    bit_loc <= bit_loc + 1'b1      ; 
                end
                else  
                if (!(^kbd_buffer[7:0] == kbd_buffer[8])) begin 
                    key  [7:0]       <= kbd_buffer [7:0] ; 
                    kbd_buffer       <= 9'b0    ;    
                    dvld             <= 1'b1    ;  
                    KBD_STATE        <= IDLE    ;  // Transition back to IDLE
                    bit_loc          <= 4'b0000 ;  // Reset bit_loc
                end else 
                    error_detect     <= 2'b01   ;
            end
        endcase
    end

endmodule
