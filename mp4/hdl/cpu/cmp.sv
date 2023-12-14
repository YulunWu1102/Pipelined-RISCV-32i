module cmp
import types::*;
(
    input branch_funct3_t cmpop,
    input logic [31:0] rs1_out, cmpmux_out,
    output logic br_en
);

logic cmp_out;

always_comb
begin
    unique case(cmpop)
        beq: cmp_out = (rs1_out == cmpmux_out);
        bne: cmp_out = (rs1_out != cmpmux_out);
        blt: cmp_out = (signed'(rs1_out) < signed'(cmpmux_out));
        bge: cmp_out = (signed'(rs1_out) >= signed'(cmpmux_out));
        bltu: cmp_out = (rs1_out < cmpmux_out);
        bgeu: cmp_out = (rs1_out >= cmpmux_out);
        default: cmp_out = '0;
    endcase
end

assign br_en = cmp_out;


endmodule