
module victim_compare #(
            parameter       s_way     = 2,
            parameter       s_way_num = 2**s_way,
            parameter       s_plru    = 2**s_way-1,
            parameter       s_offset = 5,
            parameter       s_index  = 4,
            parameter       s_tag    = 32 - s_offset - s_index,
            parameter       s_mask   = 2**s_offset,
            parameter       s_line   = 8*s_mask,
            parameter       num_sets = 2**s_index
)(    
    input logic [s_tag-1:0] tag,
    input logic [s_tag-1:0] victim_tag_out_sram,
    output logic victim_hit
);

always_comb
begin 
    if (victim_tag_out_sram == tag) begin
        victim_hit = 1'b1;
    end else begin
        victim_hit = 1'b0;    
    end
end


endmodule : victim_compare