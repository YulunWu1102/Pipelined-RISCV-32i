module MEMWB_latch 
import types::*;(
    input   clk,
    input   rst,
    input   load,
    input   control_word_t control_in,
    output  control_word_t control_out,
    input   rv32i_word regmuxout_in,
    output  rv32i_word regmuxout_out
);

register MEMWB_REGMUXOUT_REG(
    .clk(clk),
    .rst(rst),
    .load(load),
    .reg_in(regmuxout_in),
    .reg_out(regmuxout_out)
);

control_register MEMWB_CONTROL_REG(
    .clk(clk),
    .rst(rst),
    .load(load),
    .struct_in(control_in),
    .struct_out(control_out)
);

endmodule