module state_register
import types::*;
(
    input clk,
    input rst,
    input load,
    input types::state_word_t struct_in,
    output types::state_word_t struct_out
);

    types::state_word_t data;

    always_ff @(posedge clk) begin
        if (rst) begin 
            data.bhrt_index <= '0;
            data.bhr <= '0;
            data.state <= wn;
        end
        else if (load) begin
            data <= struct_in;
        end
    end

    
    assign struct_out = data;
    

endmodule