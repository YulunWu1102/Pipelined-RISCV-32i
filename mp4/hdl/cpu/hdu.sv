module hdu
import types::*;
(
    input pc_brjl_load,

    input control_word_t ifid_control_out,
    input control_word_t idex_control_out,
    input control_word_t exmem_control_out,
    input control_word_t memwb_control_out,

    input logic all_ready,
    
    output logic ifid_flush,
    output logic idex_flush,
    output logic exmem_flush,
    output logic memwb_flush,

    output logic ifid_stall,
    output forwardmux::forwardmux_sel_t forwardmux1_sel,
    output forwardmux::forwardmux_sel_t forwardmux2_sel
);


always_comb begin
    ifid_flush = 1'b0;
    idex_flush = 1'b0; 
    exmem_flush = 1'b0;
    memwb_flush = 1'b0;
    ifid_stall = 1'b0;
    forwardmux1_sel = forwardmux::regfile_out;
    forwardmux2_sel = forwardmux::regfile_out;

    if (pc_brjl_load) begin
        if (all_ready) begin
            ifid_flush = 1'b1;
            idex_flush = 1'b1;
            exmem_flush = 1'b1;
        end
    end
    
    if (ifid_control_out.rs1) begin
        if (ifid_control_out.rs1 == idex_control_out.rd) begin
            unique case(idex_control_out.regfilemux_sel)
                regfilemux::alu_out:  begin
                    if(idex_control_out.mul_en || idex_control_out.div_en) begin
                        forwardmux1_sel = forwardmux::m_out;
                        if (all_ready) begin
                            ifid_stall = 1'b1;
                            idex_flush = 1'b1;
                        end
                    end
                    else 
                        forwardmux1_sel = forwardmux::alu_out;
                end
                regfilemux::br_en:  forwardmux1_sel = forwardmux::cmp_out;
                regfilemux::u_imm:  forwardmux1_sel = forwardmux::idex_umm_out;
                regfilemux::pc_plus4: forwardmux1_sel = forwardmux::idex_pc_out_plus4;
                regfilemux::lw, regfilemux::lb, regfilemux::lbu, regfilemux::lh,regfilemux::lhu: begin
                    if (all_ready) begin
                        ifid_stall = 1'b1;
                        idex_flush = 1'b1;
                    end
                end
                default: ;
            endcase     
        end
        else if (ifid_control_out.rs1 == exmem_control_out.rd) begin
            unique case(exmem_control_out.regfilemux_sel)
                regfilemux::lw, regfilemux::lb, regfilemux::lbu, regfilemux::lh,regfilemux::lhu: begin
                    if (all_ready) begin
                        ifid_stall = 1'b1;
                        idex_flush = 1'b1;
                    end
                end
                default: forwardmux1_sel = forwardmux::exmem_regfilemux_out;
            endcase     
            
        end
        else if (ifid_control_out.rs1 == memwb_control_out.rd) begin
            forwardmux1_sel = forwardmux::memwb_regmuxout_out;
        end
    end

    if (ifid_control_out.rs2) begin
        if (ifid_control_out.rs2 == idex_control_out.rd) begin
            unique case(idex_control_out.regfilemux_sel)
                regfilemux::alu_out:  begin
                    if(idex_control_out.mul_en || idex_control_out.div_en) begin
                        forwardmux2_sel = forwardmux::m_out;
                        if (all_ready) begin
                            ifid_stall = 1'b1;
                            idex_flush = 1'b1;
                        end
                    end
                    else 
                        forwardmux2_sel = forwardmux::alu_out;
                end
                regfilemux::br_en:  forwardmux2_sel = forwardmux::cmp_out;
                regfilemux::u_imm:  forwardmux2_sel = forwardmux::idex_umm_out;
                regfilemux::pc_plus4: forwardmux2_sel = forwardmux::idex_pc_out_plus4;
                regfilemux::lw, regfilemux::lb, regfilemux::lbu, regfilemux::lh,regfilemux::lhu: begin
                    if (all_ready) begin
                        ifid_stall = 1'b1;
                        idex_flush = 1'b1;
                    end
                end
                default: ;
            endcase     
        end
        else if (ifid_control_out.rs2 == exmem_control_out.rd) begin
            unique case(exmem_control_out.regfilemux_sel)
                regfilemux::lw, regfilemux::lb, regfilemux::lbu, regfilemux::lh,regfilemux::lhu: begin
                    if (all_ready) begin
                        ifid_stall = 1'b1;
                        idex_flush = 1'b1;
                    end
                end
                default: forwardmux2_sel = forwardmux::exmem_regfilemux_out;
            endcase
            
        end
        else if (ifid_control_out.rs2 == memwb_control_out.rd) begin
            forwardmux2_sel = forwardmux::memwb_regmuxout_out;
        end
    end

end

endmodule