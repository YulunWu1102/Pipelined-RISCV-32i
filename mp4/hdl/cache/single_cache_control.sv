module single_cache_control #(
            parameter       s_way     = 2,
            parameter       s_way_num = 2**s_way,
            parameter       s_plru    = 2**s_way-1,
            parameter       s_offset = 5,
            parameter       s_index  = 4,
            parameter       s_tag    = 32 - s_offset - s_index,
            parameter       s_mask   = 2**s_offset,
            parameter       s_line   = 8*s_mask,
            parameter       num_sets = 2**s_index
) (
    input logic clk,
    input logic rst,

    // mem related
    input logic mem_read,
    input logic mem_write,
    output logic mem_resp,
    input logic [s_mask-1:0] mem_byte_enable256,
    input logic [31:0] mem_address,
    output logic [s_index-1:0] index,
    output logic [s_tag-1:0] tag,

    // pmem_related
    input logic pmem_resp,
    output logic pmem_read,
    output logic pmem_write,
    output logic [31:0] pmem_address,

    // we's
    output logic [s_way_num-1:0] data_we,
    output logic [s_way_num-1:0] tag_we,
    output logic [s_way_num-1:0] dirty_we,
    output logic [s_way_num-1:0] valid_we,
    output logic plru_we,
    output logic [s_mask-1:0] mask_val,

    // sel's:
    output logic data_in_sel,
    output logic data_out_sel,

    // inputs from datapath
    input logic [s_plru-1:0] plru_o,
    input logic hit,
    input logic dirty_o,
    input logic valid_o,
    input logic [s_way-1:0] way_index,

    // outputs to datapath
    output logic valid_i,
    output logic dirty_i,
    output logic [s_plru-1:0] plru_i, 
    output logic [s_way-1:0] evict_index,

    input logic [s_tag-1:0] evict_tag,

    // for counter
    output logic [23:0] hit_counter,
    output logic [23:0] miss_counter
);


    // ~~~~~~~~ define 'local' signals ~~~~~~~~
    logic [2:0] next_plru_evict;
    logic [s_plru-1:0] next_plru_hit;
    logic [s_plru-1:0] next_plru_hit_mask;
    logic [s_way_num-1:0] we_mask;
    logic [s_way-1:0] way_next;
    logic [s_way-1:0] way_next_para;
    logic [s_way_num-1:0] write_hit_mask;

    logic [s_way-1:0] whm_shifter; 
    logic [s_way_num-1:0] wm_shifter;
    assign whm_shifter = {{(s_way-1){1'b0}}, 1'b1};
    assign wm_shifter = {{(s_way_num-1){1'b0}}, 1'b1};

    assign write_hit_mask = whm_shifter << way_index;
    assign evict_index = way_next;
    
    // decode index and tag
    assign index = mem_address[s_offset + s_index-1:s_offset];
    assign tag = mem_address[31:s_offset + s_index];
    enum int unsigned {
        /* List of states */
        rest,
        compare_tag,
        write_back,
        allocate
    } state, next_states, prev_states;



    logic [31:0] mem_address_1;

    logic [s_mask-1:0] mem_byte_enable256_1;

    logic mem_read_1;

    logic mem_write_1;

    logic same_addr;
    logic same_mbe;
    logic same_read;
    logic same_write;

    logic dont_go_to_comparetag;

    always_ff @( posedge clk ) begin : pass
            mem_address_1 <= mem_address;

            mem_byte_enable256_1 <= mem_byte_enable256;

            mem_read_1 <= mem_read;
            
            mem_write_1 <= mem_write;

    end

    assign same_addr = (mem_address == mem_address_1) &&  (mem_address != 32'h40000000);
    assign same_mbe = (mem_byte_enable256_1 == mem_byte_enable256);
    assign same_read = (mem_read == mem_read_1);
    assign same_write = (mem_write == mem_write_1); 

    assign dont_go_to_comparetag = {same_addr, same_read, same_write, same_mbe} == 4'b1111;


    // ~~~~~~~~~~ define functions ~~~~~~~~~~
    function void load_valid(logic valid_val);
        valid_we = we_mask;
        valid_i = valid_val;
    endfunction

    function void load_dirty(logic dirty_val, logic [s_way_num-1:0] we_mask);
        dirty_we = we_mask;
        dirty_i = dirty_val;
    endfunction

    function void load_plru(logic [s_plru-1:0] plru_val);
        plru_we = 1'b1;
        plru_i = plru_val;
    endfunction

    function void load_data(logic [s_way_num-1:0] we_mask);
        data_we = we_mask;
    endfunction

    function void load_tag(logic [s_way_num-1:0] we_mask);
        tag_we = we_mask;
    endfunction

    function void set_data_in(logic data_in_sel_val);
        data_in_sel = data_in_sel_val;
    endfunction

    function void set_data_out(logic data_out_sel_val);
        data_out_sel = data_out_sel_val;
    endfunction




    function void set_defaults();
        // to do when all signals are defined:
        // 5 en
        data_we = '0;
        tag_we = '0;
        plru_we = '0;
        dirty_we = '0;
        valid_we = '0;

        // 2 x sel
        data_in_sel = 1'b1;
        data_out_sel = 1'b0;

        // valid/dirty
        valid_i = 1'b0;
        dirty_i = 1'b0;

        // to plru
        plru_i = '0;

        // to pmem
        pmem_read = 1'b0;
        pmem_write = 1'b0;
        mem_resp = 1'b0;
    endfunction



    always_comb
    begin : state_actions
        /* Default output assignments */
        set_defaults();
        /* Actions for each state */
        case (state)
            rest: begin
                mem_resp = dont_go_to_comparetag;
            end

            compare_tag: begin
                if(hit) begin
                    load_plru(next_plru_hit);
                    if (mem_read) begin
                        set_data_out(0);
                        mem_resp = 1'b1;

                    end else if (mem_write) begin
                        set_data_in(0);
                        load_dirty(1, write_hit_mask);
                        load_data(write_hit_mask);
                        set_data_out(0); 
                        mem_resp = 1'b1;
                        
                    end else begin
                        // do nothing
                    end

                
                end
                else begin
                    // do nothing, only exception
                end
                
            end

            write_back: begin
                set_data_out(1); // output from evicted array
                pmem_write = 1'b1;
            end

            allocate: begin
                pmem_read = 1'b1;
                set_data_in(1); // load data from pmem
                load_dirty(0, we_mask);
                load_valid(1);
                load_data(we_mask);
                load_tag(we_mask);

            end
        endcase

    end

    always_comb
    begin : next_state_logic
        if (rst) begin
            next_states = rest;
        end
        else begin
            case (state)
                rest: begin
                    if ((mem_write || mem_read) && ~dont_go_to_comparetag) begin
                        next_states = compare_tag;
                    end else begin
                        next_states = rest;
                    end
                end

                compare_tag: begin
                    if (hit && valid_o) begin
                        next_states = rest;
                    end else if (~hit && dirty_o) begin
                        next_states = write_back;
                    end else if (~hit && ~dirty_o) begin
                        next_states = allocate;
                    end else begin // to be determined
                        next_states = allocate;
                    end
                end

                write_back: begin
                    if (pmem_resp) begin
                        next_states = allocate;
                    end else begin
                        next_states = write_back;                    
                    end
                end

                allocate: begin
                    if (pmem_resp) begin
                        next_states = compare_tag;
                    end else begin
                        next_states = allocate;                    
                    end
                end

                default: next_states = rest;

            endcase
        end
    end



    logic miss_curr_way_digit;
    int miss_mask_pos_high;
    int miss_mask_pos_low;
    int miss_shift_digit_high;
    int miss_shift_digit_low;

    logic [s_way-1:0] miss_shifted_way;



    // always_comb for plru miss/evict
    always_comb begin
        
        for (logic [31:0] k='0; k<$unsigned(s_way); k=k+ 31'b1) begin
            miss_mask_pos_low = (s_plru)-(2**(k+1)-1);
            miss_mask_pos_high = (s_plru)-(2**(k+1)-1) + (2**k-1);

            if(k==0) begin
                way_next_para[$unsigned(s_way)-1-k] = plru_o[miss_mask_pos_high];
                miss_shifted_way = '0;

            end else begin
                miss_shifted_way = way_next_para >> (s_way-k);
                way_next_para[$unsigned(s_way)-1-k] = plru_o[$unsigned(miss_mask_pos_high)-miss_shifted_way];
            end

        end

        way_next = way_next_para;
        we_mask = wm_shifter << way_next;

    end



    logic curr_way_digit;
    int hit_mask_pos_high;
    int hit_mask_pos_low;
    int shift_digit_high;
    int shift_digit_low;

    logic [s_way-1:0] shifted_way;
    logic [s_plru-1:0] next_plru_hit_test;

    logic [s_plru-1:0] next_plru_hit_mask_pos_record;

    // always_comb for plru hit
    always_comb begin
        next_plru_hit_mask = '0;
        next_plru_hit_mask_pos_record = '0;
        for (logic [31:0] i='0; i<$unsigned(s_way); i = i + 31'b1) begin
            curr_way_digit = way_index[$unsigned(s_way)-1-i];

            hit_mask_pos_low = (s_plru)-(2**(i+1)-1);
            hit_mask_pos_high = (s_plru)-(2**(i+1)-1) + (2**i-1);

            shift_digit_high = 2**s_way-1;
            shift_digit_low = 2**s_way-1 - ($signed(i)+1);



            if(i==0) begin
                next_plru_hit_mask[hit_mask_pos_high]  = ~curr_way_digit;
                next_plru_hit_mask_pos_record[hit_mask_pos_high] = 1'b1;
                shifted_way = way_index;

            end else begin
                shifted_way = way_index >> (s_way-i);
                next_plru_hit_mask[$unsigned(hit_mask_pos_high)-shifted_way]  = ~curr_way_digit;
                next_plru_hit_mask_pos_record[$unsigned(hit_mask_pos_high)-shifted_way] = 1'b1;
            end
        end

        for (int j=0; j<s_plru; ++j) begin
            if (next_plru_hit_mask_pos_record[j]==1'b1) begin
                next_plru_hit_test[j] = next_plru_hit_mask[j];
            end else begin
                next_plru_hit_test[j] = plru_o[j];                
            end
        end

        next_plru_hit = next_plru_hit_test;

    end


    always_comb begin : PMEM_OP        
        unique case (pmem_read)
            1'b0: mask_val = mem_byte_enable256;
            1'b1: mask_val = {s_mask{1'b1}};
            default: mask_val = {s_mask{1'b1}};
            // etc.
        endcase
        
        unique case (pmem_write)
            1'b0: pmem_address = {mem_address[31:s_offset], {s_offset{1'b0}}};
            1'b1: pmem_address = {evict_tag, index, {s_offset{1'b0}}};
            default: pmem_address = {mem_address[31:s_offset], {s_offset{1'b0}}};
            // etc.
        endcase               

    end

    always_ff @(posedge clk)
    begin: next_state_assignment
        state <= next_states;
        prev_states <= state;
    end


    // ======================================== performance counter ========================================


    always @(posedge clk) begin
        if (rst) begin
            hit_counter <= 24'b0;
            miss_counter <= 24'b0;
        end else if (state == compare_tag) begin
            if ((next_states == rest) && (prev_states == rest)) begin
                hit_counter <= hit_counter + 24'b1;
            end else if ((next_states == write_back) || (next_states == allocate)) begin
                miss_counter <= miss_counter + 24'b1;
            end

        end
    end

endmodule : single_cache_control
