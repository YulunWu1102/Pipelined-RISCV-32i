module register
import types::*;
#(parameter REG_WIDTH=32)(clk, rst, load, reg_in, reg_out);

    input logic clk;
    input logic rst;
    input logic load;
    input logic [REG_WIDTH-1:0] reg_in;
    output logic [REG_WIDTH-1:0] reg_out;

    logic [REG_WIDTH-1:0] data;

    always_ff @(posedge clk) begin
        if (rst) begin 
            data <= '0;
        end
        else if (load) begin
            data <= reg_in;
        end
    end

    
    assign reg_out = data;
    

endmodule
