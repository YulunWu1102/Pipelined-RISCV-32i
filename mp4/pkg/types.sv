package pcmux;
typedef enum bit [1:0] {
    pc_plus4  = 2'b00
    ,alu_out  = 2'b01
    ,alu_mod2 = 2'b10
    ,br       = 2'b11
} pcmux_sel_t;
endpackage

package marmux;
typedef enum bit {
    pc_out = 1'b0
    ,alu_out = 1'b1
} marmux_sel_t;
endpackage

package cmpmux;
typedef enum bit {
    rs2_out = 1'b0
    ,i_imm = 1'b1
} cmpmux_sel_t;
endpackage

package alumux;
typedef enum bit {
    rs1_out = 1'b0
    ,pc_out = 1'b1
} alumux1_sel_t;

typedef enum bit [2:0] {
    i_imm    = 3'b000
    ,u_imm   = 3'b001
    ,b_imm   = 3'b010
    ,s_imm   = 3'b011
    ,j_imm   = 3'b100
    ,rs2_out = 3'b101
} alumux2_sel_t;
endpackage

package regfilemux;
typedef enum bit [3:0] {
    alu_out   = 4'b0000
    ,br_en    = 4'b0001
    ,u_imm    = 4'b0010
    ,lw       = 4'b0011
    ,pc_plus4 = 4'b0100
    ,lb        = 4'b0101
    ,lbu       = 4'b0110  // unsigned byte
    ,lh        = 4'b0111
    ,lhu       = 4'b1000  // unsigned halfword
} regfilemux_sel_t;
endpackage

package forwardmux;
typedef enum bit [2:0] {
    regfile_out    = 3'b000
    ,alu_out   = 3'b001
    ,cmp_out   = 3'b010
    ,idex_umm_out   = 3'b011
    ,idex_pc_out_plus4   = 3'b100
    ,exmem_regfilemux_out = 3'b101
    ,memwb_regmuxout_out = 3'b110
    ,m_out = 3'b111
} forwardmux_sel_t;
endpackage

package exemux;
typedef enum bit [1:0] {
    aluout      = 2'b00,
    mulout      = 2'b01,
    divout_q    = 2'b10,
    divout_r    = 2'b11
} exemux_sel_t;
endpackage

package types;
import pcmux::*;
import marmux::*;
import cmpmux::*;
import alumux::*;
import regfilemux::*;
import exemux::*;

typedef logic [31:0] rv32i_word;
typedef logic [4:0] rv32i_reg;
typedef logic [3:0] rv32i_mem_wmask;

typedef enum bit [6:0] {
    op_lui   = 7'b0110111, //load upper immediate (U type)
    op_auipc = 7'b0010111, //add upper immediate PC (U type)
    op_jal   = 7'b1101111, //jump and link (J type)
    op_jalr  = 7'b1100111, //jump and link register (I type)
    op_br    = 7'b1100011, //branch (B type)
    op_load  = 7'b0000011, //load (I type)
    op_store = 7'b0100011, //store (S type)
    op_imm   = 7'b0010011, //arith ops with register/immediate operands (I type)
    op_reg   = 7'b0110011, //arith ops with register operands (R type)
    op_csr   = 7'b1110011,  //control and status register (I type)
    // op_zeros, no op
    op_zeros = 7'b0000000
} rv32i_opcode;

typedef enum bit [2:0] {
    beq  = 3'b000,
    bne  = 3'b001,
    blt  = 3'b100,
    bge  = 3'b101,
    bltu = 3'b110,
    bgeu = 3'b111
} branch_funct3_t;

typedef enum bit [2:0] {
    lb  = 3'b000,
    lh  = 3'b001,
    lw  = 3'b010,
    lbu = 3'b100,
    lhu = 3'b101
} load_funct3_t;

typedef enum bit [2:0] {
    sb = 3'b000,
    sh = 3'b001,
    sw = 3'b010
} store_funct3_t;

typedef enum bit [2:0] {
    add  = 3'b000, //check bit30 for sub if op_reg opcode
    sll  = 3'b001,
    slt  = 3'b010,
    sltu = 3'b011,
    axor = 3'b100,
    sr   = 3'b101, //check bit30 for logical/arithmetic
    aor  = 3'b110,
    aand = 3'b111
} arith_funct3_t;

typedef enum bit [2:0] {
    mul     = 3'b000, 
    mulh    = 3'b001,
    mulhsu  = 3'b010,
    mulhu   = 3'b011,
    div     = 3'b100,
    divu    = 3'b101,
    rem     = 3'b110,
    remu    = 3'b111
} m_funct3_t;

typedef enum bit [2:0] {
    alu_add = 3'b000,
    alu_sll = 3'b001,
    alu_sra = 3'b010,
    alu_sub = 3'b011,
    alu_xor = 3'b100,
    alu_srl = 3'b101,
    alu_or  = 3'b110,
    alu_and = 3'b111
} alu_ops;

typedef struct {
    // 5 x pcmux_sel (no more mar mux)
    pcmux_sel_t pcmux_sel;
    alumux1_sel_t alumux1_sel;
    alumux2_sel_t alumux2_sel;
    regfilemux_sel_t regfilemux_sel;
    cmpmux_sel_t cmpmux_sel;
    
    // 2x ops
    alu_ops aluop;
    branch_funct3_t cmpop;

    // D-cache enable bits
    logic [3:0] dmem_wmask;
    // logic [3:0] dmem_rmask;
    logic [4:0] rd;

    // signal for D-cache/memory
    logic dmem_read;
    logic dmem_write;

    // signal for rvfi related issue
    rv32i_opcode opcode;
    // rv32i_word inst;
    logic [4:0] rs1;
    logic [4:0] rs2;

    exemux_sel_t  exemux_sel;
    logic         mul_en;
    logic         div_en;
    logic         div_signed_en;
    m_funct3_t    mul_funct3;
} control_word_t;

typedef enum logic [1:0] {
    sn,
    wn,
    wt,
    st
} state_t;

typedef struct {
    logic [1:0] bhrt_index;
    logic [1:0] bhr;
    state_t state;
} state_word_t;
endpackage


