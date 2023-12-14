module arbiter #(
            parameter       s_way     = 2,
            parameter       s_way_num = 2**s_way,
            parameter       s_plru    = 2**s_way-1,
            parameter       s_offset = 5,
            parameter       s_index  = 4,
            parameter       s_tag    = 32 - s_offset - s_index,
            parameter       s_mask   = 2**s_offset,
            parameter       s_line   = 8*s_mask,
            parameter       num_sets = 2**s_index
)
(
    //ports from cpu
    input                   clk,
    input                   rst,
    // ports to i_cache
    input   logic           i_cache_read,
    input   logic [31:0]    i_cache_addr,
    output  logic [s_line-1:0]   i_cache_rdata,
    output  logic           i_cache_resp,
    //ports to d_cache
    input   logic           d_cache_read,
    input   logic           d_cache_write,
    input   logic [31:0]    d_cache_addr,
    input   logic [s_line-1:0]   d_cache_wdata, 
    output  logic [s_line-1:0]   d_cache_rdata,
    output  logic           d_cache_resp,
    //ports to memory
    output  logic           ca_read,
    output  logic           ca_write,
    output  logic [31:0]    ca_addr,
    output  logic [s_line-1:0]   ca_wdata,
    input   logic [s_line-1:0]   ca_rdata,
    input   logic           ca_resp
);

enum logic[1:0] {
    /* List of states */
    IDLE, D_OP, I_OP
} state, next_state;

function void set_arbiter_defaults();
    i_cache_rdata   = '0;
    i_cache_resp    = '0;
    d_cache_rdata   = '0;
    d_cache_resp    = '0;
    ca_read         = '0;
    ca_write        = '0;
    ca_addr         = '0;
    ca_wdata        = '0;
endfunction

always_ff @(posedge clk) begin
    if(rst) begin
        state <= IDLE;
    end
    else state <= next_state;
end

always_comb begin : assign_out_signals
    set_arbiter_defaults();
    unique case (state)
        IDLE: ;
        D_OP: begin
            ca_addr = d_cache_addr;
            d_cache_resp = ca_resp;
            if(d_cache_read) begin 
                ca_read = 1'b1;
                d_cache_rdata = ca_rdata;
            end
            else if(d_cache_write) begin
                ca_write = 1'b1;
                ca_wdata = d_cache_wdata;
            end
            else ;
        end
        I_OP: begin
            i_cache_resp = ca_resp;
            ca_addr = i_cache_addr;
            i_cache_rdata = ca_rdata;
            ca_read = 1'b1;
        end
        default: ;
    endcase
end

always_comb begin: assign_next_state
    unique case (state)
        IDLE: begin
            if(d_cache_read || d_cache_write) 
                next_state = D_OP;
            else if(i_cache_read)
                next_state = I_OP;
            else 
                next_state = IDLE;
        end
        D_OP: begin
            if(ca_resp) begin
                next_state = IDLE;
            end
            else 
                next_state = D_OP;
        end
        I_OP: begin
            if(ca_resp) begin
                next_state = IDLE;
            end
            else
                next_state = I_OP;
        end
        default: next_state = IDLE;
    endcase
end


endmodule 