module pc_reg
import types::*;(
    input clk,
    input rst,
    input load,
    input [31:0] pc_in,
    output logic [31:0] pc_out);

    logic [31:0] data;

    always_ff @(posedge clk) begin
        if (rst) begin 
            data <= 32'h40000000;
        end
        else if (load) begin
            data <= pc_in;
        end
    end

    
    assign pc_out = data;
    

endmodule