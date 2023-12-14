module IDEX_latch
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
    input       rv32i_word alumux1_in,
    output      rv32i_word alumux1_out,
    input       rv32i_word alumux2_in,
    output      rv32i_word alumux2_out,
    input       rv32i_word cmp1_in,
    output      rv32i_word cmp1_out,
    input       rv32i_word cmp2_in,
    output      rv32i_word cmp2_out,
    input       control_word_t control_in,
    output      control_word_t control_out,
    input       logic [2:0] ifid_funct3_out,
    output      logic [2:0] idex_funct3_out,
    input       state_word_t state_in,
    output      state_word_t state_out
);

register IDEX_PC_REG(
    .clk(clk),
    .rst(rst),
    .load(load),
    .reg_in(pc_in),
    .reg_out(pc_out)
);

register #(3) IDEX_FUNCT3_REG(
    .clk(clk),
    .rst(rst),
    .load(load),
    .reg_in(ifid_funct3_out),
    .reg_out(idex_funct3_out)
);

register IDEX_UIMM_REG(
    .clk(clk),
    .rst(rst),
    .load(load),
    .reg_in(u_imm_in),
    .reg_out(u_imm_out)
);

register IDEX_RS2OUT_REG(
    .clk(clk),
    .rst(rst),
    .load(load),
    .reg_in(rs2_in),
    .reg_out(rs2_out)
);

register IDEX_ALU1_REG(
    .clk(clk),
    .rst(rst),
    .load(load),
    .reg_in(alumux1_in),
    .reg_out(alumux1_out)
);

register IDEX_ALU2_REG(
    .clk(clk),
    .rst(rst),
    .load(load),
    .reg_in(alumux2_in),
    .reg_out(alumux2_out)
);

register IDEX_CMP1_REG(
    .clk(clk),
    .rst(rst),
    .load(load),
    .reg_in(cmp1_in),
    .reg_out(cmp1_out)
);

register IDEX_CMP2_REG(
    .clk(clk),
    .rst(rst),
    .load(load),
    .reg_in(cmp2_in),
    .reg_out(cmp2_out)
);

control_register IDEX_CONTROL_REG(
    .clk(clk),
    .rst(rst),
    .load(load),
    .struct_in(control_in),
    .struct_out(control_out)
);

state_register IDEX_STATE_REG(
        .clk(clk),
        .rst(rst),
        .load(load),
        .struct_in(state_in),
        .struct_out(state_out)
    );

endmodule