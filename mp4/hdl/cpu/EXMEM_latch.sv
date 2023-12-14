module EXMEM_latch
import types::*;(
    input       clk,
    input       rst,
    input       load,
    input       rv32i_word pc_in,
    output      rv32i_word pc_out,
    input       rv32i_word u_imm_in,
    output      rv32i_word u_imm_out,
    input       rv32i_word rs2_in,
    output      rv32i_word rs2_out,
    input       rv32i_word aluout_in,
    output      rv32i_word aluout_out,
    input       rv32i_word cmpout_in,
    output      rv32i_word cmpout_out,
    input       control_word_t control_in,
    output      control_word_t control_out,
    input       logic[1:0] byte_pos_in,
    output      logic[1:0] byte_pos_out,
    input       logic [2:0] idex_funct3_out,
    output      logic [2:0] exmem_funct3_out,
    input       state_word_t state_in,
    output      state_word_t state_out
);

register EXMEM_PC_REG(
    .clk(clk),
    .rst(rst),
    .load(load),
    .reg_in(pc_in),
    .reg_out(pc_out)
);

register EXMEM_UIMM_REG(
    .clk(clk),
    .rst(rst),
    .load(load),
    .reg_in(u_imm_in),
    .reg_out(u_imm_out)
);

register EXMEM_RS2OUT_REG(
    .clk(clk),
    .rst(rst),
    .load(load),
    .reg_in(rs2_in),
    .reg_out(rs2_out)
);

register EXMEM_ALUOUT_REG(
    .clk(clk),
    .rst(rst),
    .load(load),
    .reg_in(aluout_in),
    .reg_out(aluout_out)
);

register EXMEM_CMPOUT_REG(
    .clk(clk),
    .rst(rst),
    .load(load),
    .reg_in(cmpout_in),
    .reg_out(cmpout_out)
);

control_register EXEMEM_CONTROL_REG(
    .clk(clk),
    .rst(rst),
    .load(load),
    .struct_in(control_in),
    .struct_out(control_out)
);

register #(3) IDEX_FUNCT3_REG(
    .clk(clk),
    .rst(rst),
    .load(load),
    .reg_in(idex_funct3_out),
    .reg_out(exmem_funct3_out)
);

register #(2) EXMEM_BYTE_POS_REG(
    .clk(clk),
    .rst(rst),
    .load(load),
    .reg_in(byte_pos_in),
    .reg_out(byte_pos_out)
);

state_register EXMEM_STATE_REG(
    .clk(clk),
    .rst(rst),
    .load(load),
    .struct_in(state_in),
    .struct_out(state_out)
);

endmodule