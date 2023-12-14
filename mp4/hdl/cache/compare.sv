
module compare #(
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
    input logic [s_tag-1:0] tag_out_sram [s_way_num],
    output logic [s_way-1:0] way_index,
    output logic hit
);

    logic [s_way_num-1:0] hit_array;

    genvar i;
    generate for (i = 0; i < s_way_num; i++) begin : arrays
        onetag_compaare #(s_way, s_way_num, s_plru, s_offset, s_index, s_tag, s_mask, s_line, num_sets)
        compare_onetag (
            .tag       (tag),
            .tag_out_sram_single       (tag_out_sram[i]),
            .hit       (hit_array[i])
        );
    end endgenerate


    logic [31:0] j;
    always_comb begin
        way_index = '0;
        j = '0;
        while (j<s_way_num && !hit_array[j]) j = j + 32'b1;
        way_index = j[s_way-1:0];

        // for (int i=0; i<s_way_num; ++i) begin
        //     if (hit_array[i] == 1'b1) begin
        //         way_index = i[s_way-1:0];
        //     end else begin
        //         way_index = way_index;
        //     end
        // end

        if(hit_array != {s_way_num{1'b0}}) begin
            hit = 1'b1;
        end else begin
            hit = 1'b0;
        end
    end


endmodule : compare