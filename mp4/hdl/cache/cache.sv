module cache #(
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
    input                   clk,
    input                   rst,

    /* CPU side signals */
    input   logic   [31:0]  mem_address, //
    input   logic           mem_read, //
    input   logic           mem_write, //
    input   logic   [s_mask-1:0]  mem_byte_enable, //
    output  logic   [s_line-1:0] mem_rdata,
    input   logic   [s_line-1:0] mem_wdata,
    output  logic           mem_resp, //

    /* Memory side signals */
    output  logic   [31:0]  pmem_address,
    output  logic           pmem_read, //
    output  logic           pmem_write, //
    input   logic   [s_line-1:0] pmem_rdata,
    output  logic   [s_line-1:0] pmem_wdata,
    input   logic           pmem_resp, //

    // counters
    output logic [23:0] hit_counter,
    output logic [23:0] miss_counter
);


    // data out
    logic [s_line-1:0] data_out;

    // we;s
    logic [s_way_num-1:0] data_we;
    logic [s_way_num-1:0] tag_we;
    logic [s_way_num-1:0] dirty_we;
    logic [s_way_num-1:0]valid_we;
    logic plru_we;
    // sel's
    logic data_in_sel;
    logic data_out_sel;
    // mask
    logic [s_mask-1:0] mask_val;


    // datapath->control

    logic [s_plru-1:0] plru_o;
    logic hit;
    logic dirty_o;
    logic valid_o;
    logic [s_way-1:0] way_index;

    // inputs value from control
    logic valid_i;
    logic dirty_i;
    logic [s_plru-1:0] plru_i;
    logic [s_way-1:0] evict_index;

    // new add-ons
    logic [s_index-1:0] index;
    logic [s_tag-1:0] tag;
    logic [s_tag-1:0] evict_tag;
    
    // victim outs
    logic     [s_line-1:0] victim_data_o;
    logic     [s_tag-1:0] victim_tag_o;
    logic     victim_valid_o;
    logic     victim_dirty_o;
    logic     victim_hit;

    // victim we's
    logic victim_data_we;
    logic victim_tag_we;
    logic victim_valid_we;
    logic victim_dirty_we;


    // assign pmem_wdata = victim_data_o;
    // assign mem_rdata = data_out;

    // cache_control #(s_way, s_way_num, s_plru, s_offset, s_index, s_tag, s_mask, s_line, num_sets)
    // control
    // (
    //     .clk(clk),
    //     .rst(rst),
    //     // mem
    //     .mem_read(mem_read),
    //     .mem_write(mem_write),
    //     .mem_resp(mem_resp),
    //     .mem_byte_enable256(mem_byte_enable),
    //     .mem_address(mem_address),
    //     .index(index),
    //     .tag(tag),
    //     // pmem
    //     .pmem_resp(pmem_resp),
    //     .pmem_read(pmem_read),
    //     .pmem_write(pmem_write),
    //     .pmem_address(pmem_address),
    //     // we
    //     .data_we(data_we),
    //     .tag_we(tag_we),
    //     .dirty_we(dirty_we),
    //     .valid_we(valid_we),
    //     .plru_we(plru_we),
    //     .mask_val(mask_val),
    //     // sel
    //     .data_in_sel(data_in_sel),
    //     .data_out_sel(data_out_sel),
    //     // inputs from datapath
    //     .plru_o(plru_o),
    //     .hit(hit),
    //     // .dirty_o(dirty_o),
    //     .valid_o(valid_o),
    //     .way_index(way_index),
    //     // victim cache we's
    //     .victim_data_we(victim_data_we),
    //     .victim_tag_we(victim_tag_we),
    //     .victim_dirty_we(victim_dirty_we),
    //     .victim_valid_we(victim_valid_we),
    //     // inputs from victim cache
    //     .victim_hit(victim_hit),
    //     .victim_dirty_o(victim_dirty_o),
    //     // .victim_valid_o(victim_valid_o),
    //     // outputs to datapath
    //     .valid_i(valid_i),
    //     .dirty_i(dirty_i),
    //     .plru_i(plru_i),
    //     .evict_index(evict_index),

    //     // evict cache tag for pmem
    //     .victim_tag_o(victim_tag_o),

    //     // counters
    //     .hit_counter(hit_counter),
    //     .miss_counter(miss_counter)
    // );


    // main_cache_datapath #(s_way, s_way_num, s_plru, s_offset, s_index, s_tag, s_mask, s_line, num_sets)
    // main_cache_datapath
    // (
    //     .clk(clk),
    //     .rst(rst),
    //     // mem
    //     .mem_wdata256(mem_wdata),
    //     .index(index),
    //     .tag(tag),
    //     // victim cache out
    //     .victim_data_o(victim_data_o),
    //     .victim_tag_o(victim_tag_o),
    //     .victim_valid_o(victim_valid_o),
    //     .victim_dirty_o(victim_dirty_o),
    //     // we
    //     .data_we(data_we),
    //     .tag_we(tag_we),
    //     .dirty_we(dirty_we),
    //     .valid_we(valid_we),
    //     .plru_we(plru_we),
    //     .mask_val(mask_val),
    //     // sel
    //     .data_in_sel(data_in_sel),
    //     .data_out_sel(data_out_sel),
    //     // inputs value from control        
    //     .valid_i(valid_i),
    //     .dirty_i(dirty_i),
    //     .plru_i(plru_i),
    //     .evict_index(evict_index),
    //     // main cache info out
    //     .plru_o(plru_o),
    //     .hit(hit),
    //     .dirty_o(dirty_o),
    //     .valid_o(valid_o),
    //     .way_index(way_index),
    //     .data_out(data_out),
    //     .evict_tag(evict_tag)
    // );

    // victim_cache_datapath #(s_way, s_way_num, s_plru, s_offset, s_index, s_tag, s_mask, s_line, num_sets)
    // victim_cache_datapath 
    // (
    //     .clk(clk),
    //     .rst(rst),
    //     // input data from main cache
    //     .cache_index(index),
    //     .cache_tag(evict_tag),
    //     .cache_data_out(data_out),
    //     .cache_dirty(dirty_o),
    //     .cache_valid(valid_o),
    //     // input data from pmem and mem related
    //     .mem_address(mem_address),
    //     .pmem_rdata(pmem_rdata),
    //     // victim we's 
    //     .victim_data_we(victim_data_we),
    //     .victim_tag_we(victim_tag_we),
    //     .victim_dirty_we(victim_dirty_we),
    //     .victim_valid_we(victim_valid_we),
    //     .mask_val(mask_val),
    //     // sel's
    //     .data_in_sel(data_in_sel), 
    //     // victim outputs value
    //     .victim_hit(victim_hit),
    //     .victim_dirty_o(victim_dirty_o),
    //     .victim_valid_o(victim_valid_o),
    //     .victim_data_o(victim_data_o),
    //     .victim_tag_o(victim_tag_o)    
    // );



    assign pmem_wdata = data_out;
    assign mem_rdata = data_out;
    single_cache_control #(s_way, s_way_num, s_plru, s_offset, s_index, s_tag, s_mask, s_line, num_sets)
    single_control
    (
        .clk(clk),
        .rst(rst),
        // mem
        .mem_read(mem_read),
        .mem_write(mem_write),
        .mem_resp(mem_resp),
        .mem_byte_enable256(mem_byte_enable),
        .mem_address(mem_address),
        .index(index),
        .tag(tag),
        // pmem
        .pmem_resp(pmem_resp),
        .pmem_read(pmem_read),
        .pmem_write(pmem_write),
        .pmem_address(pmem_address),
        // we
        .data_we(data_we),
        .tag_we(tag_we),
        .dirty_we(dirty_we),
        .valid_we(valid_we),
        .plru_we(plru_we),
        .mask_val(mask_val),
        // sel
        .data_in_sel(data_in_sel),
        .data_out_sel(data_out_sel),
        .plru_o(plru_o),
        .hit(hit),
        .dirty_o(dirty_o),
        .valid_o(valid_o),
        .way_index(way_index),
        .valid_i(valid_i),
        .dirty_i(dirty_i),
        .plru_i(plru_i),
        .evict_index(evict_index),
        // main cache info out
        .evict_tag(evict_tag),
        .hit_counter(hit_counter),
        .miss_counter(miss_counter)
    );


    single_cache_datapath #(s_way, s_way_num, s_plru, s_offset, s_index, s_tag, s_mask, s_line, num_sets)
    single_cache_datapath
    (
        .clk(clk),
        .rst(rst),
        // mem
        .mem_wdata256(mem_wdata),
        // pmem
        .pmem_rdata(pmem_rdata),
        .index(index),
        .tag(tag),
        // we
        .data_we(data_we),
        .tag_we(tag_we),
        .dirty_we(dirty_we),
        .valid_we(valid_we),
        .plru_we(plru_we),
        .mask_val(mask_val),
        // sel
        .data_in_sel(data_in_sel),
        .data_out_sel(data_out_sel),
        // main cache info in        
        .valid_i(valid_i),
        .dirty_i(dirty_i),
        .plru_i(plru_i),
        .evict_index(evict_index),
        // main cache info out
        .plru_o(plru_o),
        .hit(hit),
        .dirty_o(dirty_o),
        .valid_o(valid_o),
        .way_index(way_index),
        .data_out(data_out),
        .evict_tag(evict_tag)
    );



endmodule : cache
