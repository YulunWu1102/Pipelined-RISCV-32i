module datapath
// import rv32i_types::*;
import types::*;
(
    input    logic                           clk,
    input    logic                           rst,
    output   logic                           imem_read,
    output   logic [31:0]                    imem_address,
    input    logic [31:0]                    imem_rdata,
    output   logic                           dmem_read,
    output   logic                           dmem_write,
    output   logic [3:0]                     dmem_wmask,
    output   logic [31:0]                    dmem_address,
    input    logic [31:0]                    dmem_rdata,
    output   logic [31:0]                    dmem_wdata,
    input    control_word_t                  control,
    output   rv32i_opcode                    opcode,
    output   logic [2:0]                     funct3,
    output   logic [6:0]                     funct7,
    output   logic [4:0]                     rd,
    output   logic [4:0]                     rs1,
    output   logic [4:0]                     rs2,
    input    logic                           imem_resp,
    input    logic                           dmem_resp,
    output   logic [1:0]                     byte_pos,

    output   logic                           pc_brjl_load,
    output   control_word_t                  ifid_control_out,
    output   control_word_t                  idex_control_out,
    output   control_word_t                  exmem_control_out,
    output   control_word_t                  memwb_control_out,
    input    logic                           ifid_flush,
    input    logic                           idex_flush,
    input    logic                           exmem_flush,
    input    logic                           memwb_flush,
    input    logic                           ifid_stall,
    input    forwardmux::forwardmux_sel_t    forwardmux1_sel,
    input    forwardmux::forwardmux_sel_t    forwardmux2_sel,
    output   logic                           all_ready,
    input    logic                           br_predicted,
    input    logic                           mispredicted,
    input    state_word_t                    state_out,
    output   state_word_t                    ifid_state_out,
    output   state_word_t                    idex_state_out,
    output   state_word_t                    exmem_state_out,
    output   logic                           br_mem,
    output   logic                           update
);

rv32i_word pcmux_out;
rv32i_word pc_in;
rv32i_word alumux1_out;
rv32i_word alumux2_out;
rv32i_word regfilemux_out;
rv32i_word cmpmux_out;
/* latch signals */
logic [4:0] ifid_rs1_out, rs1_addr;
logic [4:0] ifid_rs2_out, rs2_addr;
assign rs1_addr = ifid_rs1_out;
assign rs2_addr = ifid_rs2_out;
logic [4:0] ifid_rd_out;
logic [2:0] ifid_funct3_out;
logic [6:0] ifid_funct7_out;
logic [2:0] idex_funct3_out;
logic [2:0] exmem_funct3_out;
rv32i_opcode ifid_opcode_out;
rv32i_word ifid_i_imm_out, ifid_s_imm_out, ifid_b_imm_out, ifid_u_imm_out, ifid_j_imm_out, ifid_pc_out;

rv32i_word idex_pc_out, idex_umm_out, idex_alumux1_out, idex_alumux2_out, idex_cmp1_out, idex_cmp2_out;
rv32i_word idex_rs2_out;
logic load_ifid, load_idex, load_exmem, load_memwb;

rv32i_word exmem_pc_out, exmem_umm_out, exmem_rs2_out, exmem_aluout, exmem_cmpout;

rv32i_word memwb_regmuxout_out; 
// control_word_t memwb_control_out, idex_control_out, exmem_control_out;
logic load_pc;
logic [31:0] pc_out, pc_prev;
logic [31:0] i_imm, s_imm, b_imm, u_imm, j_imm;
logic [31:0] rs1_out, rs2_out, updated_rs1_out, updated_rs2_out;
logic br_en;
logic [31:0] alu_out, mul_out, div_q_out, div_r_out, exe_out;
logic [31:0] cmp_out;
logic [4:0] ready_mask;

// for ld/st alignment
logic [31:0] shifted_val;
logic [3:0] dmem_rmask;
logic [1:0] byte_pos_out;
logic mul_resp, div_resp;

logic br_if;
rv32i_word target_predicted;

assign update = (exmem_control_out.pcmux_sel == pcmux::br && all_ready);
assign br_mem = (exmem_cmpout == 32'b1);
assign br_if = imem_rdata[6:0] == op_br;
assign target_predicted = pc_out + {{20{imem_rdata[31]}}, imem_rdata[7], imem_rdata[30:25], imem_rdata[11:8], 1'b0};

assign pc_brjl_load = ((exmem_control_out.pcmux_sel == pcmux::br && mispredicted) || (exmem_control_out.pcmux_sel == pcmux::alu_out) || (exmem_control_out.pcmux_sel == pcmux::alu_mod2)) && all_ready;
assign ifid_control_out = control;
assign cmp_out = {31'd0, br_en};
assign rs1 = ifid_rs1_out;
assign rs2 = ifid_rs2_out;

assign ready_mask = {(!imem_read || imem_resp), 1'b1, 
(!idex_control_out.mul_en || (idex_control_out.mul_en && mul_resp)) && (!idex_control_out.div_en || (idex_control_out.div_en && div_resp)), 
((!exmem_control_out.dmem_read && !exmem_control_out.dmem_write) || dmem_resp), 1'b1};
assign all_ready = (ready_mask == 5'b11111);
assign load_ifid = all_ready && (~ifid_stall);
assign load_idex = all_ready;
assign load_exmem = all_ready;
assign load_memwb = all_ready;
// assign load_pc = load_ifid;
assign load_pc = load_ifid|| pc_brjl_load;

assign imem_address = pc_out;

assign imem_read = '1;

assign dmem_read = exmem_control_out.dmem_read;
assign dmem_write = exmem_control_out.dmem_write;


assign opcode = ifid_opcode_out;
assign funct3 = ifid_funct3_out;
assign funct7 = ifid_funct7_out;
assign rd = ifid_rd_out;


pc_reg PC_REG(
    .clk(clk),
    .rst(rst),
    .load(load_pc),
    .pc_in(pcmux_out),
    .pc_out(pc_out)
);

IFID_latch ifid_latch(
    .clk(clk),
    .rst(rst || ifid_flush),
    .load(load_ifid),
    .pc_in(pc_out),
    .mem_rdata_i(imem_rdata),
    .funct3(ifid_funct3_out),
    .funct7_(ifid_funct7_out),
    .opcode(ifid_opcode_out),
    .i_imm(ifid_i_imm_out),
    .s_imm(ifid_s_imm_out),
    .b_imm(ifid_b_imm_out),
    .u_imm(ifid_u_imm_out),
    .j_imm(ifid_j_imm_out),
    .rs1(ifid_rs1_out),
    .rs2(ifid_rs2_out),
    .rd (ifid_rd_out),
    .pc_id_out(ifid_pc_out),
    .state_in(state_out),
    .state_out(ifid_state_out)
);

regfile regfile(
    .clk(clk),
    .rst(rst),
    .load(load_memwb),
    .in(memwb_regmuxout_out),
    .src_a(ifid_rs1_out),
    .src_b(ifid_rs2_out),
    .dest(memwb_control_out.rd),
    .reg_a(rs1_out),
    .reg_b(rs2_out)
);

IDEX_latch idex_latch(
    .clk(clk),
    .rst(rst || idex_flush),
    .load(load_idex),
    .pc_in(ifid_pc_out),
    .pc_out(idex_pc_out),
    .u_imm_in(ifid_u_imm_out),
    .u_imm_out(idex_umm_out),
    .rs2_in(updated_rs2_out),
    .rs2_out(idex_rs2_out),
    .alumux1_in(alumux1_out),
    .alumux1_out(idex_alumux1_out),
    .alumux2_in(alumux2_out),
    .alumux2_out(idex_alumux2_out),
    .cmp1_in(updated_rs1_out),
    .cmp1_out(idex_cmp1_out),
    .cmp2_in(cmpmux_out),
    .cmp2_out(idex_cmp2_out),
    .control_in(control),
    .control_out(idex_control_out),
    .ifid_funct3_out(ifid_funct3_out),
    .idex_funct3_out(idex_funct3_out),
    .state_in(ifid_state_out),
    .state_out(idex_state_out)
);

alu ALU(
    .aluop(idex_control_out.aluop), 
    .a(idex_alumux1_out), 
    .b(idex_alumux2_out), 
    .f(alu_out)
);

Multiplier multuplier(
    .clk(clk),
    .rst(rst),
    .mul_en(idex_control_out.mul_en),
    .multiplier(idex_alumux1_out),
    .multiplicand(idex_alumux2_out),
    .mul_funct3(idex_control_out.mul_funct3),
    .mul_out(mul_out),
    .resp(mul_resp)
);

Divider divider(
    .clk(clk),
    .rst(rst),
    .div_en(idex_control_out.div_en),
    .dividend(idex_alumux1_out),
    .divisor(idex_alumux2_out),
    .signed_en(idex_control_out.div_signed_en),
    .quotient(div_q_out),
    .remainder(div_r_out),
    .resp(div_resp)
);

cmp CMP(
    .cmpop(idex_control_out.cmpop),
    .rs1_out(idex_cmp1_out),
    .cmpmux_out(idex_cmp2_out),
    .br_en(br_en)
);

EXMEM_latch exmem_latch(
    .clk(clk),
    .rst(rst || exmem_flush),
    .load(load_exmem),
    .pc_in(idex_pc_out),
    .pc_out(exmem_pc_out),
    .u_imm_in(idex_umm_out),
    .u_imm_out(exmem_umm_out),
    .rs2_in(idex_rs2_out),
    .rs2_out(exmem_rs2_out),
    .aluout_in(exe_out),
    .aluout_out(exmem_aluout),
    .cmpout_in(cmp_out),
    .cmpout_out(exmem_cmpout),
    .control_in(idex_control_out),
    .control_out(exmem_control_out),
    .byte_pos_in(byte_pos),
    .byte_pos_out(byte_pos_out),
    .idex_funct3_out(idex_funct3_out),
    .exmem_funct3_out(exmem_funct3_out),
    .state_in(idex_state_out),
    .state_out(exmem_state_out)
);

assign dmem_address = {exmem_aluout[31:2], 2'b00};
assign byte_pos = exmem_aluout[1:0];


MEMWB_latch memwb_latch(
    .clk(clk),
    .rst(rst || memwb_flush),
    .load(load_memwb),
    .regmuxout_in(regfilemux_out),
    .regmuxout_out(memwb_regmuxout_out),
    .control_in(exmem_control_out),
    .control_out(memwb_control_out)
);

// dmem_wmaskの最高cao
always_comb begin : assign_mask
    if(dmem_write) begin
        case (exmem_funct3_out)
            sw: begin 
                dmem_wdata = exmem_rs2_out;
                dmem_wmask = 4'b1111;
            end
            sh: begin 
                dmem_wdata = exmem_rs2_out  << (8 * byte_pos);
                dmem_wmask = 4'b0011 << byte_pos; /* Unsure for now */ 
            end
            sb: begin
                dmem_wdata = exmem_rs2_out  << (8 * byte_pos);
                dmem_wmask = 4'b0001 << byte_pos; /* Unsure for now */ 
            end
            default: begin
                dmem_wmask = 4'b0000;
                dmem_wdata = '0;
            end
        endcase
    end
    else begin 
        dmem_wmask = 4'b0000;
        dmem_wdata = '0;
    end
end

always_comb begin : MUXES

    unique case (exmem_control_out.pcmux_sel)
        pcmux::pc_plus4: pcmux_out = (br_if && br_predicted) ? target_predicted : pc_out + 4;
        pcmux::alu_out: pcmux_out = exmem_aluout;
        pcmux::alu_mod2: pcmux_out = {exmem_aluout[31:1], 1'b0};
        pcmux::br: pcmux_out = mispredicted ? ((exmem_cmpout == 32'b1) ? exmem_aluout : exmem_pc_out + 4) : ((br_if && br_predicted) ? target_predicted : pc_out + 4);
    endcase

    unique case (forwardmux1_sel)
        forwardmux::regfile_out: updated_rs1_out = rs1_out;
        forwardmux::alu_out: updated_rs1_out = alu_out;
        forwardmux::cmp_out: updated_rs1_out = cmp_out;
        forwardmux::idex_umm_out: updated_rs1_out = idex_umm_out;
        forwardmux::idex_pc_out_plus4: updated_rs1_out = idex_pc_out + 4;
        forwardmux::exmem_regfilemux_out: updated_rs1_out = regfilemux_out;
        forwardmux::memwb_regmuxout_out: updated_rs1_out = memwb_regmuxout_out;
        forwardmux::m_out: updated_rs1_out = exmem_aluout;
        default: updated_rs1_out = '0;
    endcase

    unique case (forwardmux2_sel)
        forwardmux::regfile_out: updated_rs2_out = rs2_out;
        forwardmux::alu_out: updated_rs2_out = alu_out;
        forwardmux::cmp_out: updated_rs2_out = cmp_out;
        forwardmux::idex_umm_out: updated_rs2_out = idex_umm_out;
        forwardmux::idex_pc_out_plus4: updated_rs2_out = idex_pc_out + 4;
        forwardmux::exmem_regfilemux_out: updated_rs2_out = regfilemux_out;
        forwardmux::memwb_regmuxout_out: updated_rs2_out = memwb_regmuxout_out;
        forwardmux::m_out: updated_rs2_out = exmem_aluout;
        default: updated_rs2_out = '0;
    endcase

    unique case (control.alumux1_sel)
        alumux::rs1_out: alumux1_out = updated_rs1_out;
        alumux::pc_out: alumux1_out = ifid_pc_out;
    endcase

    unique case (control.alumux2_sel)
        alumux::i_imm: alumux2_out = ifid_i_imm_out;
        alumux::u_imm: alumux2_out = ifid_u_imm_out;
        alumux::b_imm: alumux2_out = ifid_b_imm_out;
        alumux::s_imm: alumux2_out = ifid_s_imm_out;
        alumux::j_imm: alumux2_out = ifid_j_imm_out;
        alumux::rs2_out: alumux2_out = updated_rs2_out;
        default: alumux2_out = '0;
    endcase

    unique case (control.cmpmux_sel)
        cmpmux::rs2_out: cmpmux_out = updated_rs2_out;
        cmpmux::i_imm: cmpmux_out = ifid_i_imm_out;
    endcase
    
    unique case (exmem_control_out.regfilemux_sel)
        regfilemux::alu_out:   begin 
            regfilemux_out = exmem_aluout;
            dmem_rmask = '0;
        end
        regfilemux::br_en:     begin 
            regfilemux_out = exmem_cmpout;
            dmem_rmask = '0;
        end
        regfilemux::u_imm:     begin 
            regfilemux_out = exmem_umm_out;
            dmem_rmask = '0;
        end
        regfilemux::pc_plus4:  begin 
            regfilemux_out = exmem_pc_out + 4;
            dmem_rmask = '0;
        end
        regfilemux::lw: begin
            regfilemux_out = dmem_rdata;
            dmem_rmask = 4'b1111;
        end
        regfilemux::lb: begin
            shifted_val = (dmem_rdata >> (8 * byte_pos));
            regfilemux_out = {{24{shifted_val[7]}}, shifted_val[7:0]};
            dmem_rmask = 4'b0001 << byte_pos;
        end
        regfilemux::lbu: begin
            shifted_val = (dmem_rdata >> (8 * byte_pos));
            regfilemux_out = {24'b0, shifted_val[7:0]};
            dmem_rmask = 4'b0001 << byte_pos;
        end
        regfilemux::lh: begin
            shifted_val = (dmem_rdata >> (8 * byte_pos));
            regfilemux_out = {{16{shifted_val[15]}}, shifted_val[15:0]};
            dmem_rmask = 4'b0011 << byte_pos;
        end
        regfilemux::lhu: begin
            shifted_val = (dmem_rdata >> (8 * byte_pos));
            regfilemux_out = {16'b0, shifted_val[15:0]};
            dmem_rmask = 4'b0011 << byte_pos;
        end
        default: begin
            shifted_val = '0;
            regfilemux_out = '0;
            dmem_rmask = '0;
        end
    endcase

    unique case (idex_control_out.exemux_sel) 
        exemux::aluout:     exe_out = alu_out;
        exemux::mulout:     exe_out = mul_out;
        exemux::divout_q:   exe_out = div_q_out;
        exemux::divout_r:   exe_out = div_r_out;
        default: exe_out = alu_out;
    endcase

end

endmodule