module bus_adapter #(
            parameter       s_way     = 2,
            parameter       s_way_num = 2**s_way,
            parameter       s_plru    = 2**s_way-1,
            parameter       s_offset = 5,
            parameter       s_index  = 4,
            parameter       s_tag    = 32 - s_offset - s_index,
            parameter       s_mask   = 2**s_offset,
            parameter       s_line   = 8*s_mask,
            parameter       num_sets = 2**s_index,
            parameter       num_address = s_line/32,
            parameter       zero_pad = s_mask - s_offset
)
(
    input   logic   [31:0]  address,
    output  logic   [s_line-1:0] mem_wdata256,
    input   logic   [s_line-1:0] mem_rdata256,
    input   logic   [31:0]  mem_wdata,
    output  logic   [31:0]  mem_rdata,
    input   logic   [3:0]   mem_byte_enable,
    output  logic   [s_mask-1:0]  mem_byte_enable256
);

assign mem_wdata256 = {num_address{mem_wdata}};
assign mem_rdata = mem_rdata256[(32*address[s_offset-1:2]) +: 32];
assign mem_byte_enable256 = {{zero_pad{1'b0}}, mem_byte_enable} << (address[s_offset-1:2]*4);

endmodule : bus_adapter
