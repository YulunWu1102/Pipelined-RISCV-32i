module control_register
import types::*;
(
    input clk,
    input rst,
    input load,
    input types::control_word_t struct_in,
    output types::control_word_t struct_out
);

    types::control_word_t data;

    always_ff @(posedge clk) begin
        if (rst) begin 
            data.pcmux_sel <= pcmux::pc_plus4; // for regular code proceed
            data.cmpmux_sel <= cmpmux::rs2_out;
            data.alumux1_sel <= alumux::rs1_out;
            data.alumux2_sel <= alumux::i_imm;
            data.regfilemux_sel <= regfilemux::alu_out;

            // 2 x ops
            data.aluop <= alu_add;
            data.cmpop <= beq;

            // dmem signal
            data.dmem_read <= 1'b0;
            data.dmem_write <= 1'b0;

            // D-cache enable bits
            data.dmem_wmask <= 4'b0000;
            // data.dmem_rmask <= 4'b0000;
            // rd: default set to 0, which by assumption will never matter
            data.rd <= '0;

            // new to rvfi issue
            data.opcode <= op_zeros;
            // data.inst <= '0;
            data.rs1 <= '0;
            data.rs2 <= '0;

            data.exemux_sel <= exemux::aluout;
            data.mul_en <= '0;
            data.div_en <= '0;
            data.div_signed_en <= '0;
            data.mul_funct3 <= m_funct3_t'(3'b000);
        end
        else if (load) begin
            data <= struct_in;
        end
    end

    
    assign struct_out = data;
    

endmodule