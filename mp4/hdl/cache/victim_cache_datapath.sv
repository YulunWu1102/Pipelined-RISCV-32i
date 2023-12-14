module victim_cache_datapath #(
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

    input           clk,
    input           rst,

    // input data from main cache
    input logic     [s_index-1:0] cache_index,
    input logic     [s_tag-1:0] cache_tag,
    input logic     [s_line-1:0] cache_data_out,
    input logic     cache_dirty,
    input logic     cache_valid,

    // input data from pmem and mem related
    input logic     [31:0] mem_address,
    input logic     [s_line-1:0] pmem_rdata,

    // victim we's 
    input logic     victim_data_we,
    input logic     victim_tag_we,
    input logic     victim_dirty_we,
    input logic     victim_valid_we,
    input logic     [s_mask-1:0] mask_val,

    // sel's
    input logic     data_in_sel, // from main cache or memory

    // victim outputs value to control
    output logic    victim_hit,
    output logic    victim_dirty_o,
    output logic    victim_valid_o,
    output logic    [s_line-1:0] victim_data_o,    
    output logic    [s_tag-1:0] victim_tag_o
    
);

    // signals stores output of SRAM/FF

    // input to all SRAM and FF, muxed by signal
    logic   [s_line-1:0] victim_data_i;
    logic   [s_tag-1:0]    victim_tag_i;
    logic   [s_index-1:0]  victim_index;
    logic   victim_valid_i;
    logic   victim_dirty_i;

    // decode index and tag (data: pmem_data, valid/dirty harcoded)
    logic [s_index-1:0] mem_index;
    logic [s_tag-1:0] mem_tag;
    assign mem_index = mem_address[s_offset + s_index-1:s_offset];
    assign mem_tag = mem_address[31:s_offset + s_index]; 


    // victim shit
    mp4_data_array #(s_mask, s_line,  s_index, 1<<s_index, 0, 0, 1)
    victim_data_array (
        .clk0       (clk),
        .csb0       (1'b0),
        .web0       (!victim_data_we),
        .wmask0     (mask_val),
        .addr0      (victim_index),
        .din0       (victim_data_i),
        .dout0      (victim_data_o)
    );

    mp4_tag_array #(s_tag, s_index, 1<<s_index, 0, 0, 1)
    victim_tag_array (
        .clk0       (clk),
        .csb0       (1'b0), // always asserted
        .web0       (!victim_tag_we),
        .addr0      (victim_index),
        .din0       (victim_tag_i),
        .dout0      (victim_tag_o)
    );

    ff_array #(s_index, 1)
    victim_valid_array (
        .clk0       (clk),
        .rst0       (rst),
        .csb0       (1'b0), // always asserted
        .web0       (!victim_valid_we),
        .addr0      (victim_index),
        .din0       (victim_valid_i),
        .dout0      (victim_valid_o)
    );

    ff_array #(s_index, 1)
    victim_dirty_array (
        .clk0       (clk),
        .rst0       (rst),
        .csb0       (1'b0), // always asserted
        .web0       (!victim_dirty_we),
        .addr0      (victim_index),
        .din0       (victim_dirty_i),
        .dout0      (victim_dirty_o)
    );


    victim_compare #(s_way, s_way_num, s_plru, s_offset, s_index, s_tag, s_mask, s_line, num_sets)
    victim_compare (
        .tag(mem_tag),
        .victim_tag_out_sram(victim_tag_o),
        .victim_hit(victim_hit)
    );


    /******************************** Muxes **************************************/
    always_comb begin : MUXES
        unique case (data_in_sel) // regular load: 0, switch: 1
            1'b0: begin // from memory  
                victim_data_i = pmem_rdata; 
                victim_tag_i = mem_tag; 
                victim_index = mem_index;
                victim_valid_i = 1'b1;
                victim_dirty_i = 1'b0;
            end
            1'b1: begin // from cache
                victim_data_i = cache_data_out;
                victim_tag_i = cache_tag;
                victim_index = cache_index;
                victim_valid_i = cache_valid;
                victim_dirty_i = cache_dirty;
            end   

            default: begin
                victim_data_i = pmem_rdata; 
                victim_tag_i = mem_tag; 
                victim_index = mem_index;
                victim_valid_i = 1'b1;
                victim_dirty_i = 1'b0;
            end
        
            // etc.
        endcase
    end

endmodule : victim_cache_datapath
