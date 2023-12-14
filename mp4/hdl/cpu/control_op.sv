module control_op
import types::*;

(
    // 4 x register direct output
    input rv32i_opcode opcode,
    input logic [2:0] funct3,
    input logic [6:0] funct7,

    // not hint in graph
    input logic [4:0] rd, // pack in control word and pass around
    input logic [4:0] rs1,
    input logic [4:0] rs2,
    
    // 6 x sel
    output control_word_t control_word,

    // ld/st alignment
    input [1:0] byte_pos

);


branch_funct3_t branch_funct3;
store_funct3_t store_funct3;
load_funct3_t load_funct3;
arith_funct3_t arith_funct3;
m_funct3_t mul_funct3;

assign arith_funct3 = arith_funct3_t'(funct3);
assign branch_funct3 = branch_funct3_t'(funct3);
assign load_funct3 = load_funct3_t'(funct3);
assign store_funct3 = store_funct3_t'(funct3);
assign mul_funct3 = m_funct3_t'(funct3);

function void set_defaults();    

    // 6 x mux sel's (to default value)
    control_word.pcmux_sel = pcmux::pc_plus4; // for regular code proceed
    control_word.cmpmux_sel = cmpmux::rs2_out;
    control_word.alumux1_sel = alumux::rs1_out;
    control_word.alumux2_sel = alumux::i_imm;
    control_word.regfilemux_sel = regfilemux::alu_out;

    // 2 x ops
    control_word.aluop = alu_add;
    control_word.cmpop = beq;

    // dmem signal
    control_word.dmem_read = 1'b0;
    control_word.dmem_write = 1'b0;

    // D-cache enable bits
    control_word.dmem_wmask = 4'b0000; // change 10.26

    // rd: default set to 0, which by assumption will never matter
    control_word.rd = '0;
    
    // pass opcode
    control_word.opcode = opcode;

    control_word.rs1 = '0;
    control_word.rs2 = '0;

    control_word.exemux_sel = exemux::aluout;
    control_word.mul_en = '0;
    control_word.div_en = '0;
    control_word.div_signed_en = '0;
    control_word.mul_funct3 = m_funct3_t'(3'b000);

endfunction

/**
 *  Use the next several functions to set the signals needed to
 *  load various registers
**/

// load signals (6)
function void loadPC(pcmux::pcmux_sel_t sel);
    // load_pc = 1'b1; // no more needed, always assume 1'b1 unless invalid raised
    control_word.pcmux_sel = sel;
endfunction

function void loadRegfile(logic [4:0] rd_val, regfilemux::regfilemux_sel_t sel);
    // load_regfile = 1'b1; // no more needed, always assume 1'b1 unless invalid raised
    control_word.regfilemux_sel = sel;
    control_word.rd = rd_val;
endfunction


// module ops (2)
function void setALU(alumux::alumux1_sel_t sel1, alumux::alumux2_sel_t sel2, logic setop, alu_ops op);
    /* Student code here */
    control_word.alumux1_sel = sel1;
    control_word.alumux2_sel = sel2;
    if (setop) control_word.aluop = op; // else default value
    control_word.exemux_sel = exemux::aluout;
endfunction

function automatic void setCMP(cmpmux::cmpmux_sel_t sel, branch_funct3_t op);
    control_word.cmpop = op;
    control_word.cmpmux_sel = sel;
endfunction

function void setMUL();
    control_word.mul_en = 1'b1;
    control_word.exemux_sel = exemux::mulout;
    control_word.mul_funct3 = mul_funct3;
    control_word.alumux1_sel = alumux::rs1_out;
    control_word.alumux2_sel = alumux::rs2_out;
endfunction

function void setDIV(logic signed_en, exemux::exemux_sel_t sel);
    control_word.div_en = 1'b1;
    control_word.div_signed_en = signed_en;
    control_word.exemux_sel = sel;
    control_word.alumux1_sel = alumux::rs1_out;
    control_word.alumux2_sel = alumux::rs2_out;
endfunction
/*****************************************************************************/

    /* Remember to deal with rst signal */

always_comb begin : opcode_action
    /* Default output assignments */
    set_defaults();
    case (opcode)
        op_lui: begin            
            loadRegfile(rd, regfilemux::u_imm);
        end
        
        op_auipc: begin
            setALU(alumux::pc_out, alumux::u_imm, 1'b1, alu_add);
            loadRegfile(rd, regfilemux::alu_out);
        end
        
        op_jal: begin// store pc+4 to rd
            loadRegfile(rd, regfilemux::pc_plus4);
            // pc+j_imm
            setALU(alumux::pc_out, alumux::j_imm, 1'b1, alu_add);
            // load
            loadPC(pcmux::alu_out);
        end
        
        op_jalr: begin
            // store pc+4 to rd
            loadRegfile(rd, regfilemux::pc_plus4);
            // rs1+i_imm
            setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_add);
            // then setting the least-significant bit of the result to zero.
            loadPC(pcmux::alu_mod2);
            control_word.rs1 = rs1;       
        end
        
        op_br: begin
            // will compare rs1 and rs2 whatsoever
            // The 12-bit B-immediate encodes signed offsets in multiples of 2
            setCMP(cmpmux::rs2_out, branch_funct3);
            setALU(alumux::pc_out, alumux::b_imm, 1'b1, alu_add);
            loadPC(pcmux::br);
            control_word.rs1 = rs1;
            control_word.rs2 = rs2;   
                     
        end 
        
        op_load: begin
            // decide dmem_wmask based on load_function3

            // calc_addr: set ALU for address calculation        
            setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_add);
            
            // ld1: raise D-cache/mem read signal
            control_word.dmem_read = 1'b1;           
            
            // ld2: tell regfile which data to load in
            case(load_funct3)
                lw: loadRegfile(rd, regfilemux::lw);
                lb: loadRegfile(rd, regfilemux::lb);
                lbu: loadRegfile(rd, regfilemux::lbu);
                lh: loadRegfile(rd, regfilemux::lh);
                lhu: loadRegfile(rd, regfilemux::lhu);                                         
                default: loadRegfile(rd, regfilemux::lw); // for CP1 only
            endcase
            control_word.rs1 = rs1;
        end
        
        op_store: begin

            // calc_addr: set ALU for address calculation        
            setALU(alumux::rs1_out, alumux::s_imm, 1'b1, alu_add);

            // st1: raise dmem_write
            control_word.dmem_write = 1'b1;

            case (store_funct3)
                sw: control_word.dmem_wmask = 4'b1111;
                sh: control_word.dmem_wmask = 4'b0011 << byte_pos; /* Unsure for now */ 
                sb: control_word.dmem_wmask = 4'b0001 << byte_pos; /* Unsure for now */ 
                default: ;
            endcase

            control_word.rs1 = rs1;
            control_word.rs2 = rs2;       

            // st2:
            // do nothing   
        end
        
        op_imm: begin // register immediate, CP1
            // addi, slti, sltiu, xori, ori, andi, slli, srli, srai
            case (arith_funct3)
                add:begin
                    // select proper operands and do calculation
                    setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_add);
                    // load result to regfile
                    loadRegfile(rd, regfilemux::alu_out);
                    // load PC forward +4 for next round
                    loadPC(pcmux::pc_plus4);
                end
                slt:begin // use cmp module
                    // select proper operands and do comparison
                    setCMP(cmpmux::i_imm, blt);
                    // load result to regfile
                    loadRegfile(rd, regfilemux::br_en);
                    // load PC forward +4 for next round
                    loadPC(pcmux::pc_plus4);
                end
                sltu:begin // use cmp module// use cmp module
                    setCMP(cmpmux::i_imm, bltu);
                    loadRegfile(rd, regfilemux::br_en);
                    loadPC(pcmux::pc_plus4);
                end
                axor:begin
                    setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_xor);
                    loadRegfile(rd, regfilemux::alu_out);
                    loadPC(pcmux::pc_plus4);
                end
                aor:begin
                    setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_or);
                    loadRegfile(rd, regfilemux::alu_out);
                    loadPC(pcmux::pc_plus4);
                end
                aand:begin
                    setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_and);
                    loadRegfile(rd, regfilemux::alu_out);
                    loadPC(pcmux::pc_plus4);
                end
                sll:begin
                    setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_sll);
                    loadRegfile(rd, regfilemux::alu_out);
                    loadPC(pcmux::pc_plus4);
                end
                sr:begin // srl & sra, check bit30 for logical/arithmetic
                    // bit 30 is the 5'th digit of funct7
                    if(funct7 == 7'b0100000) begin // 1: A
                        setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_sra);
                    end
                    else begin  // 0: L
                        setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_srl);
                    end
                    loadRegfile(rd, regfilemux::alu_out);
                    loadPC(pcmux::pc_plus4);
                    end
                default: begin
                    // default_case
                end
            endcase
            control_word.rs1 = rs1;
        end 
        
        op_reg: begin // register immediate, CP1
            // addi, slti, sltiu, xori, ori, andi, slli, srli, srai
            if (!funct7[0]) begin   // normal op_reg
                case (arith_funct3)
                    add:begin
                        if (funct7 == 7'b0100000) begin // 1 for sub
                            setALU(alumux::rs1_out, alumux::rs2_out, 1'b1, alu_sub);
                        end else begin // 0 for add
                            setALU(alumux::rs1_out, alumux::rs2_out, 1'b1, alu_add);                    
                        end
                        // load result to regfile
                        loadRegfile(rd, regfilemux::alu_out);
                        // load PC forward +4 for next round
                        loadPC(pcmux::pc_plus4);
                    end
                    slt:begin // use cmp module
                        // select proper operands and do comparison
                        setCMP(cmpmux::rs2_out, blt);
                        // load result to regfile
                        loadRegfile(rd, regfilemux::br_en);
                        // load PC forward +4 for next round
                        loadPC(pcmux::pc_plus4);
                    end
                    sltu:begin // use cmp module// use cmp module
                        setCMP(cmpmux::rs2_out, bltu);
                        loadRegfile(rd, regfilemux::br_en);
                        loadPC(pcmux::pc_plus4);
                    end
                    axor:begin
                        setALU(alumux::rs1_out, alumux::rs2_out, 1'b1, alu_xor);
                        loadRegfile(rd, regfilemux::alu_out);
                        loadPC(pcmux::pc_plus4);
                    end
                    aor:begin
                        setALU(alumux::rs1_out, alumux::rs2_out, 1'b1, alu_or);
                        loadRegfile(rd, regfilemux::alu_out);
                        loadPC(pcmux::pc_plus4);
                    end
                    aand:begin
                        setALU(alumux::rs1_out, alumux::rs2_out, 1'b1, alu_and);
                        loadRegfile(rd, regfilemux::alu_out);
                        loadPC(pcmux::pc_plus4);
                    end
                    sll:begin
                        setALU(alumux::rs1_out, alumux::rs2_out, 1'b1, alu_sll);
                        loadRegfile(rd, regfilemux::alu_out);
                        loadPC(pcmux::pc_plus4);
                    end
                    sr:begin // srl & sra, check bit30 for logical/arithmetic
                        // bit 30 is the 5'th digit of funct7
                        if(funct7 == 7'b0100000) begin // 1: SRA
                            setALU(alumux::rs1_out, alumux::rs2_out, 1'b1, alu_sra);
                        end
                        else begin  // 0: SRL
                            setALU(alumux::rs1_out, alumux::rs2_out, 1'b1, alu_srl);
                        end
                        loadRegfile(rd, regfilemux::alu_out);
                        loadPC(pcmux::pc_plus4);
                    end
                    default: begin
                        // default_case
                    end
                endcase
            end
            else begin      // M extensions
                case (arith_funct3)
                    mul, mulh, mulhsu, mulhu: setMUL();
                    div: setDIV(1'b1, exemux::divout_q);
                    divu: setDIV(1'b0, exemux::divout_q);
                    rem: setDIV(1'b1, exemux::divout_r);
                    remu: setDIV(1'b0, exemux::divout_r);
                    default: ;
                endcase
                loadRegfile(rd, regfilemux::alu_out);
            end
            control_word.rs1 = rs1;
            control_word.rs2 = rs2;
        end 
        
        op_csr: begin
            // what the fuck is this         
        end 
        
        op_zeros: begin
            // do nothing
        end
        default: ;
    endcase
end

endmodule : control_op