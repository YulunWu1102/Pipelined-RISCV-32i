module single_cache_datapath #(
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

    input clk,
    input rst,
    // mem_related
    input logic      [s_line-1:0] mem_wdata256,
    input logic [s_index-1:0] index,
    input logic [s_tag-1:0] tag,

    // pmem_related
    input logic [s_line-1:0] pmem_rdata,

    // we's
    input logic     [s_way_num-1:0] data_we,
    input logic     [s_way_num-1:0] tag_we,
    input logic     [s_way_num-1:0] dirty_we,
    input logic     [s_way_num-1:0] valid_we,
    input logic     plru_we,
    input logic     [s_mask-1:0] mask_val,

    // sel's
    input logic data_in_sel,
    input logic data_out_sel,

    // inputs value from control
    input logic valid_i,
    input logic dirty_i,
    input logic     [s_plru-1:0] plru_i, 
    input logic     [s_way-1:0] evict_index,


    // main cache info out
    output logic    [s_plru-1:0] plru_o,
    output logic    hit,
    output logic    dirty_o,
    output logic    valid_o,
    output logic    [s_way-1:0] way_index,
    output logic    [s_line-1:0] data_out,
    output logic    [s_tag-1:0] evict_tag
);

    logic   [s_line-1:0] data_in;
    logic   [s_line-1:0] data_out_sram [s_way_num];
    logic   [s_tag-1:0] tag_out_sram [s_way_num];
    logic   [s_plru-1:0] plru_out;
    logic   valid_ff [s_way_num];
    logic   dirty_ff [s_way_num];
    logic [s_way-1:0] out_sel;


    genvar i;
    generate for (i = 0; i < s_way_num; i++) begin : arrays
        mp4_data_array #(s_mask, s_line,  s_index, 1<<s_index, 0, 0, 1)
        data_array (
            .clk0       (clk),
            .csb0       (1'b0),
            .web0       (!data_we[i]),
            .wmask0     (mask_val),
            .addr0      (index),
            .din0       (data_in),
            .dout0      (data_out_sram[i])
        );

        mp4_tag_array #(s_tag, s_index, 1<<s_index, 0, 0, 1)
        tag_array (
            .clk0       (clk),
            .csb0       (1'b0), // always asserted
            .web0       (!tag_we[i]),
            .addr0      (index),
            .din0       (tag),
            .dout0      (tag_out_sram[i])
        );

        ff_array #(s_index, 1)
        valid_array (
            .clk0       (clk),
            .rst0       (rst),
            .csb0       (1'b0), // always asserted
            .web0       (!valid_we[i]),
            .addr0      (index),
            .din0       (valid_i),
            .dout0      (valid_ff[i])
        );

        ff_array #(s_index, 1)
        dirty_array (
            .clk0       (clk),
            .rst0       (rst),
            .csb0       (1'b0), // always asserted
            .web0       (!dirty_we[i]),
            .addr0      (index),
            .din0       (dirty_i),
            .dout0      (dirty_ff[i])
        );
    end endgenerate

    ff_array #(s_index, s_plru)
    plru_array (
        .clk0       (clk),
        .rst0       (rst),
        .csb0       (1'b0), // always asserted
        .web0       (!plru_we),
        .addr0      (index),
        .din0       (plru_i),
        .dout0      (plru_o)
    );


    compare #(s_way, s_way_num, s_plru, s_offset, s_index, s_tag, s_mask, s_line, num_sets)
    compare (
        .tag(tag),
        .tag_out_sram(tag_out_sram),
        .way_index(way_index),
        .hit(hit)
    );



/******************************** Muxes **************************************/
always_comb begin : MUXES
    unique case (data_in_sel)
        1'b0: data_in = mem_wdata256;
        1'b1: data_in = pmem_rdata;     
        default: data_in = mem_wdata256;
        // etc.
    endcase

    unique case (data_out_sel)
        1'b0: out_sel = way_index;
        1'b1: out_sel = evict_index;  
        default: out_sel = way_index;
        // etc.
    endcase

    
    data_out = data_out_sram[out_sel];
    evict_tag = tag_out_sram[evict_index];
    dirty_o = dirty_ff [evict_index];
    valid_o = valid_ff[way_index];
    
    

end

endmodule : single_cache_datapath