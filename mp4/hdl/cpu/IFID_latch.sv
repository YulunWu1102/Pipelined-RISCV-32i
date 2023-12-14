module IFID_latch
import types::*; (
    input   clk,
    input   rst,
    input   load,
    input   rv32i_word pc_in,
    input   rv32i_word mem_rdata_i,
    output  [2:0] funct3,
    output  [6:0] funct7_,
    output  rv32i_opcode opcode,
    output  rv32i_word i_imm,
    output  rv32i_word s_imm,
    output  rv32i_word b_imm,
    output  rv32i_word u_imm,
    output  rv32i_word j_imm,
    output  [4:0] rs1,
    output  [4:0] rs2,
    output  [4:0] rd ,
    output  rv32i_word pc_id_out,
    input   state_word_t state_in,
    output  state_word_t state_out

);
    register IFID_PC_REG(
        .clk(clk),
        .rst(rst),
        .load(load),
        .reg_in(pc_in),
        .reg_out(pc_id_out)
    );

    ir IFID_INST_REG(
        .clk(clk),
        .rst(rst),
        .load(load),
        .in(mem_rdata_i),
        .funct3(funct3),
        .funct7(funct7_),
        .opcode(opcode),
        .i_imm(i_imm),
        .s_imm(s_imm),
        .b_imm(b_imm),
        .u_imm(u_imm),
        .j_imm(j_imm),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd)
    );

    state_register IFID_STATE_REG(
        .clk(clk),
        .rst(rst),
        .load(load),
        .struct_in(state_in),
        .struct_out(state_out)
    );

endmodule