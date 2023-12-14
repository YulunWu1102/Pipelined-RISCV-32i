module mp4
import types::*; /* Import types defined in rv32i_types.sv */#(
            parameter       s_way     = 1,
            parameter       s_way_num = 2**s_way,
            parameter       s_plru    = 2**s_way-1,
            parameter       s_offset = 5,
            parameter       s_index  = 4,
            parameter       s_tag    = 32 - s_offset - s_index,
            parameter       s_mask   = 2**s_offset,
            parameter       s_line   = 8*s_mask,
            parameter       num_sets = 2**s_index,
            parameter       num_address = s_line/32,
            parameter       zero_pad = s_mask - s_offset,
            parameter       num_states = (s_line / 64)-1
)
(
    input   logic           clk,
    input   logic           rst,

    // Use these for CP1 (magic memory)
    // output  logic   [31:0]  imem_address,
    // output  logic           imem_read,
    // input   logic   [31:0]  imem_rdata,
    // input   logic           imem_resp,
    // output  logic   [31:0]  dmem_address,
    // output  logic           dmem_read,
    // output  logic           dmem_write,
    // output  logic   [3:0]   dmem_wmask,
    // input   logic   [31:0]  dmem_rdata,
    // output  logic   [31:0]  dmem_wdata,
    // input   logic           dmem_resp

    // Use these for CP2+ (with caches and burst memory)
    output  logic   [31:0]  bmem_address,
    output  logic           bmem_read,
    output  logic           bmem_write,
    input   logic   [63:0]  bmem_rdata,
    output  logic   [63:0]  bmem_wdata,
    input   logic           bmem_resp
);

            logic           monitor_valid;
            logic   [63:0]  monitor_order;
            logic   [31:0]  monitor_inst;
            logic   [4:0]   monitor_rs1_addr;
            logic   [4:0]   monitor_rs2_addr;
            logic   [31:0]  monitor_rs1_rdata;
            logic   [31:0]  monitor_rs2_rdata;
            logic   [4:0]   monitor_rd_addr;
            logic   [31:0]  monitor_rd_wdata;
            logic   [31:0]  monitor_pc_rdata;
            logic   [31:0]  monitor_pc_wdata;
            logic   [31:0]  monitor_mem_addr;
            logic   [3:0]   monitor_mem_rmask;
            logic   [3:0]   monitor_mem_wmask;
            logic   [31:0]  monitor_mem_rdata;
            logic   [31:0]  monitor_mem_wdata;

 // ========================== connect control and datapath ==========================
    // define inter-signals
    rv32i_opcode opcode;
    logic [2:0] funct3;
    logic [6:0] funct7;
    logic [4:0] rd;
    logic [4:0] rs1;
    logic [4:0] rs2;
    logic [4:0] rs1_addr;
    logic [4:0] rs2_addr;
    control_word_t control_word;
    logic [1:0] byte_pos;
    logic pc_brjl_load;
    control_word_t ifid_control_out;
    control_word_t idex_control_out;
    control_word_t exmem_control_out;
    control_word_t memwb_control_out;
    logic ifid_flush;
    logic idex_flush;
    logic exmem_flush;
    logic memwb_flush;
    logic ifid_stall;
    forwardmux::forwardmux_sel_t forwardmux1_sel;
    forwardmux::forwardmux_sel_t forwardmux2_sel;
    logic all_ready;
    state_word_t state_out;
    state_word_t ifid_state_out;
    state_word_t idex_state_out;
    state_word_t exmem_state_out;
    logic        br_mem;
    logic mispredicted;
    logic br_predicted; 
    logic update;
    logic [63:0] branch_count, mispred_count;

    // Fill this out
    // Only use hierarchical references here for verification
    // **DO NOT** use hierarchical references in the actual design!
    logic [63:0] order;
    always @(posedge clk) begin
        if(rst) order <= '0;
        else if(monitor_valid) order <= order + 1;
        else ;

        if (rst) begin
            mispred_count <= '0;
            branch_count <= '0;
        end
        else if (datapath.load_memwb) begin 
                if (datapath.exmem_control_out.pcmux_sel == pcmux::br) begin
                    if (datapath.mispredicted) begin
                        mispred_count <= mispred_count + 1'b1;
                    end
                    branch_count <= branch_count + 1'b1;
                end
            end
    end


    // ~~~~~~~~~~ BUFFER FOR PASS ALL SIGNALS TO WB AND READ BY MONITOR ~~~~~~~~~~
    logic [3:0] dmem_rmask;
    logic [31:0]  id_inst, ex_inst, mem_inst, wb_inst; // monitor_inst
    logic [4:0] ex_rs1_addr, mem_rs1_addr, wb_rs1_addr; // monitor_rs1_addr
    logic [4:0] ex_rs2_addr, mem_rs2_addr, wb_rs2_addr; // monitor_rs2_addr
    logic [31:0] ex_rs1_data, mem_rs1_data, wb_rs1_data; // monitor_rs1_addr
    logic [31:0] ex_rs2_data, mem_rs2_data, wb_rs2_data; // monitor_rs2_addr
    logic [31:0]  id_pc_rdata, ex_pc_rdata, mem_pc_rdata, wb_pc_rdata; // monitor_pc_rdata
    logic [31:0]  id_pc_wdata, ex_pc_wdata, mem_pc_wdata, wb_pc_wdata; // monitor_pc_wdata
    logic [31:0]  mem_mem_address, wb_mem_address; // monitor_mem_address
    logic [3:0]  ex_mem_rmask, mem_mem_rmask, wb_mem_rmask; // monitor_mem_rmask
    logic [3:0]  mem_mem_wmask, wb_mem_wmask; // monitor_mem_dmask
    logic [31:0]  mem_mem_rdata, wb_mem_rdata; // monitor_mem_rdata
    logic [31:0]  mem_mem_wdata, wb_mem_wdata; // monitor_mem_wdata

    // ============ cache signals ===========
    logic           imem_resp;
    logic           imem_read;
    logic           imem_write;
    rv32i_word      imem_rdata;
    rv32i_word      imem_wdata;
    rv32i_word      imem_address;
    logic [3:0]     imem_byte_enable;
    
    logic           dmem_resp;
    logic           dmem_read;
    logic           dmem_write;
    rv32i_word      dmem_rdata;
    rv32i_word      dmem_wdata;
    rv32i_word      dmem_address;
    logic [3:0]     dmem_byte_enable;
    logic   [3:0]   dmem_wmask;
    assign imem_write = '0;
    assign imem_wdata = '0;
    assign dmem_byte_enable = dmem_wmask;
    assign imem_byte_enable = '0;

    // signals for bus adaptor (only those 256's unique)
    logic   [s_line-1:0] imem_wdata256;
    logic   [s_line-1:0] imem_rdata256;
    logic   [s_mask-1:0]  imem_byte_enable256;
    logic   [s_line-1:0] dmem_wdata256;
    logic   [s_line-1:0] dmem_rdata256;
    logic   [s_mask-1:0]  dmem_byte_enable256;
    // signals for cache (only those pmem's)
    rv32i_word      ipmem_address;
    logic           ipmem_read;
    logic           ipmem_write;
    logic   [s_line-1:0] ipmem_rdata;
    logic   [s_line-1:0] ipmem_wdata;
    logic           ipmem_resp;
    rv32i_word      dpmem_address;
    logic           dpmem_read;
    logic           dpmem_write;
    logic   [s_line-1:0] dpmem_rdata;
    logic   [s_line-1:0] dpmem_wdata;
    logic           dpmem_resp;
    
    rv32i_word      pmem_address;
    logic           pmem_read;
    logic           pmem_write;
    logic   [s_line-1:0] pmem_rdata;
    logic   [s_line-1:0] pmem_wdata;
    logic           pmem_resp;
    
    always_ff @( posedge clk ) begin : pass_signals
        if(datapath.all_ready) begin // set all_ready as non-stall signal for now
            // ======== monitor_inst (id-ex-mem-wb, imem_rdata) ========
            if (datapath.load_ifid && !datapath.ifid_stall) id_inst <= imem_rdata;
            if (datapath.load_idex) ex_inst <= id_inst;
            if (datapath.load_exmem) mem_inst <= ex_inst;
            if (datapath.load_memwb) wb_inst <= mem_inst;

            // // ======== monitor_rs1_addr (ex-mem-wb, datapath.rs1_addr) ========
            // ex_rs1_addr <= datapath.rs1_addr;
            // mem_rs1_addr <= ex_rs1_addr;
            // wb_rs1_addr <= mem_rs1_addr;

            // // ======== monitor_rs2_addr (ex-mem-wb, datapath.rs1_addr) ========
            // ex_rs2_addr <= datapath.rs2_addr;
            // mem_rs2_addr <= ex_rs2_addr;
            // wb_rs2_addr <= mem_rs2_addr;

            // ======== monitor_rs1_addr (ex-mem-wb, datapath.rs1_addr) ========
            if (datapath.load_idex) ex_rs1_data <= datapath.updated_rs1_out;
            if (datapath.load_exmem) mem_rs1_data <= ex_rs1_data;
            if (datapath.load_memwb) wb_rs1_data <= mem_rs1_data;

            // ======== monitor_rs2_addr (ex-mem-wb, datapath.rs1_addr) ========
            if (datapath.load_idex) ex_rs2_data <= datapath.updated_rs2_out;
            if (datapath.load_exmem) mem_rs2_data <= ex_rs2_data;
            if (datapath.load_memwb) wb_rs2_data <= mem_rs2_data;
            
            // ======== monitor_pc_rdata (id-ex-mem-wb, pc_out) ========
            if (datapath.load_ifid && ~datapath.ifid_stall) id_pc_rdata <= datapath.pc_out;
            if (datapath.load_idex) ex_pc_rdata <= id_pc_rdata;
            if (datapath.load_exmem) mem_pc_rdata <= ex_pc_rdata;
            if (datapath.load_memwb) wb_pc_rdata <= mem_pc_rdata;

            // ======== monitor_pc_wdata (id-ex-mem-wb, pcmux_out) ========
            if (datapath.load_ifid && ~datapath.ifid_stall) id_pc_wdata <= datapath.pcmux_out;
            if (datapath.load_idex) ex_pc_wdata <= id_pc_wdata;
            if (datapath.load_exmem) mem_pc_wdata <= ex_pc_wdata;
            if (datapath.load_memwb) begin 
                if (datapath.pc_brjl_load) begin
                    unique case(datapath.exmem_control_out.pcmux_sel)
                        pcmux::alu_mod2: wb_pc_wdata <= {datapath.exmem_aluout[31:1], 1'b0};
                        pcmux::alu_out: wb_pc_wdata <= datapath.exmem_aluout;
                        pcmux::br: wb_pc_wdata <= ((datapath.exmem_cmpout == 32'b1) ? datapath.exmem_aluout : datapath.exmem_pc_out + 4);
                        default:;
                    endcase
                end
                else begin
                    wb_pc_wdata <= mem_pc_wdata;
                end
            end


            // ======== monitor_mem_address (mem-wb, datapath.dmem_address) ========
            // if (datapath.load_exmem) mem_mem_address <= datapath.dmem_address;
            if (datapath.load_memwb) wb_mem_address <= datapath.dmem_address;
            
            // ======== monitor_mem_rmask (mem-wb, datapath.dmem_wmask) ========
            if (datapath.load_memwb) wb_mem_rmask <= datapath.dmem_rmask;

            // ======== monitor_mem_wmask (mem-wb, datapath.dmem_wmask) ========
            // if (datapath.load_exmem) mem_mem_wmask <= datapath.dmem_wmask;
            if (datapath.load_memwb) wb_mem_wmask <= datapath.dmem_wmask;

            // ======== monitor_mem_rdata (mem-wb, dmem_rdata) ========
            if (datapath.load_memwb) wb_mem_rdata <= dmem_rdata;

            // ======== monitor_mem_wdata (mem-wb, dmem_wdata) ========
            // if (datapath.load_exmem) mem_mem_wdata <= datapath.dmem_wdata;
            if (datapath.load_memwb) wb_mem_wdata <= datapath.dmem_wdata;


        end
    end
    
    logic [23:0] dcache_hit_counter;
    logic [23:0] dcache_miss_counter;
    logic [23:0] icache_hit_counter;
    logic [23:0] icache_miss_counter;

    assign monitor_valid     = ((datapath.memwb_control_out.opcode != op_zeros) && datapath.load_memwb);
    assign monitor_order     = order;
    assign monitor_inst      = wb_inst;                         // imem_rdata;
    assign monitor_rs1_addr  = datapath.memwb_control_out.rs1;                     // datapath.rs1_addr;
    assign monitor_rs2_addr  = datapath.memwb_control_out.rs2;                     // datapath.rs2_addr;
    assign monitor_rs1_rdata = wb_rs1_data;                     // datapath.rs1_out; 
    assign monitor_rs2_rdata = wb_rs2_data;                     // datapath.rs2_out;
    assign monitor_rd_addr   = datapath.memwb_control_out.rd;   // already from wb
    assign monitor_rd_wdata  = datapath.memwb_regmuxout_out;    // already from wb
    assign monitor_pc_rdata  = wb_pc_rdata;                     // datapath.pc_out;
    assign monitor_pc_wdata  = wb_pc_wdata;                     // datapath.pcmux_out;
    assign monitor_mem_addr  = wb_mem_address;                  // dmem_address;
    assign monitor_mem_rmask = wb_mem_rmask;                    // dmem_wmask;// 暂时和wmask一样
    assign monitor_mem_wmask = wb_mem_wmask;                    // dmem_wmask;
    assign monitor_mem_rdata = wb_mem_rdata;                    // dmem_rdata;
    assign monitor_mem_wdata = wb_mem_wdata;                    // dmem_wdata;

    // connect control and datapath
    control_op control_op(
        .opcode(opcode),
        .funct3(funct3),
        .funct7(funct7),
        .rd(rd),
        .control_word(control_word),
        .byte_pos(byte_pos),
        .rs1(rs1),
        .rs2(rs2)
    );

    hdu hazard_detection_unit(
        .pc_brjl_load(pc_brjl_load),
        .ifid_control_out(ifid_control_out),
        .idex_control_out(idex_control_out),
        .exmem_control_out(exmem_control_out),
        .memwb_control_out(memwb_control_out),
        .ifid_flush(ifid_flush),
        .idex_flush(idex_flush),
        .exmem_flush(exmem_flush),
        .memwb_flush(memwb_flush),
        .ifid_stall(ifid_stall),
        .forwardmux1_sel(forwardmux1_sel),
        .forwardmux2_sel(forwardmux2_sel),
        .all_ready(all_ready)
    );

    // lbht local_branch_history_table(
    //     .clk(clk),
    //     .rst(rst),
    //     .br_mem(br_mem),
    //     .imem_address(imem_address),
    //     .ifid_state_out(ifid_state_out),
    //     .idex_state_out(idex_state_out),
    //     .exmem_state_out(exmem_state_out),
    //     .state_out(state_out),
    //     .mispredicted(mispredicted),
    //     .br_predicted(br_predicted),
    //     .update(update)
    // );

    gbht global_branch_history_table(
        .clk(clk),
        .rst(rst),
        .br_mem(br_mem),
        .imem_address(imem_address),
        .ifid_state_out(ifid_state_out),
        .idex_state_out(idex_state_out),
        .exmem_state_out(exmem_state_out),
        .state_out(state_out),
        .mispredicted(mispredicted),
        .br_predicted(br_predicted),
        .update(update)
    );

    datapath datapath(
        .clk(clk),
        .rst(rst),
        .imem_read(imem_read),
        .imem_address(imem_address),
        .imem_rdata(imem_rdata),
        .dmem_read(dmem_read),
        .dmem_write(dmem_write),
        .dmem_wmask(dmem_wmask),
        .dmem_address(dmem_address),
        .dmem_rdata(dmem_rdata),
        .dmem_wdata(dmem_wdata),
        .control(control_word),
        .opcode(opcode),
        .funct3(funct3),
        .funct7(funct7),
        .rd(rd),
        .imem_resp(imem_resp),
        .dmem_resp(dmem_resp),
        .byte_pos(byte_pos),
        .pc_brjl_load(pc_brjl_load),
        .ifid_control_out(ifid_control_out),
        .idex_control_out(idex_control_out),
        .exmem_control_out(exmem_control_out),
        .memwb_control_out(memwb_control_out),
        .ifid_flush(ifid_flush),
        .idex_flush(idex_flush),
        .exmem_flush(exmem_flush),
        .memwb_flush(memwb_flush),
        .ifid_stall(ifid_stall),
        .forwardmux1_sel(forwardmux1_sel),
        .forwardmux2_sel(forwardmux2_sel),
        .rs1(rs1),
        .rs2(rs2),
        .all_ready(all_ready),
        .br_mem(br_mem),
        .ifid_state_out(ifid_state_out),
        .idex_state_out(idex_state_out),
        .exmem_state_out(exmem_state_out),
        .state_out(state_out),
        .mispredicted(mispredicted),
        .br_predicted(br_predicted),
        .update(update)
    );

    //================================ Cache Interface ================================
    bus_adapter #(s_way, s_way_num, s_plru, s_offset, s_index, s_tag, s_mask, s_line, num_sets, num_address, zero_pad)
    i_bus_adapter (
        .address(imem_address),
        .mem_wdata256(imem_wdata256),
        .mem_rdata256(imem_rdata256),
        .mem_wdata(imem_wdata),
        .mem_rdata(imem_rdata),
        .mem_byte_enable(imem_byte_enable),
        .mem_byte_enable256(imem_byte_enable256)
    );

    bus_adapter #(s_way, s_way_num, s_plru,  s_offset, s_index, s_tag, s_mask, s_line, num_sets, num_address, zero_pad)
    d_bus_adapter (
        .address(dmem_address),
        .mem_wdata256(dmem_wdata256),
        .mem_rdata256(dmem_rdata256),
        .mem_wdata(dmem_wdata),
        .mem_rdata(dmem_rdata),
        .mem_byte_enable(dmem_byte_enable),
        .mem_byte_enable256(dmem_byte_enable256)
    );

    cache #(s_way, s_way_num, s_plru,  s_offset, s_index, s_tag, s_mask, s_line, num_sets)
    icache (
        // cpu's
        .clk(clk),
        .rst(rst),
        .mem_address(imem_address),
        .mem_read(imem_read), 
        .mem_write(imem_write), 
        .mem_byte_enable(imem_byte_enable256), 
        .mem_rdata(imem_rdata256),
        .mem_wdata(imem_wdata256),
        .mem_resp(imem_resp), 
        // pmem's
        .pmem_address(ipmem_address),
        .pmem_read(ipmem_read),
        .pmem_write(ipmem_write),
        .pmem_rdata(ipmem_rdata),
        .pmem_wdata(ipmem_wdata),
        .pmem_resp(ipmem_resp),
        .hit_counter(icache_hit_counter),
        .miss_counter(icache_miss_counter)
    );

    cache #(s_way, s_way_num, s_plru,  s_offset, s_index, s_tag, s_mask, s_line, num_sets)
    dcache (
        // cpu's
        .clk(clk),
        .rst(rst),
        .mem_address(dmem_address),
        .mem_read(dmem_read), 
        .mem_write(dmem_write), 
        .mem_byte_enable(dmem_byte_enable256), 
        .mem_rdata(dmem_rdata256),
        .mem_wdata(dmem_wdata256),
        .mem_resp(dmem_resp), 
        // pmem's
        .pmem_address(dpmem_address),
        .pmem_read(dpmem_read),
        .pmem_write(dpmem_write),
        .pmem_rdata(dpmem_rdata),
        .pmem_wdata(dpmem_wdata),
        .pmem_resp(dpmem_resp),
        .hit_counter(dcache_hit_counter),
        .miss_counter(dcache_miss_counter)
    );

    arbiter #(s_way, s_way_num, s_plru,  s_offset, s_index, s_tag, s_mask, s_line, num_sets)
    arbiter (
        .clk(clk),
        .rst(rst),
        .i_cache_read(ipmem_read),
        .i_cache_addr(ipmem_address),
        .i_cache_rdata(ipmem_rdata),
        .i_cache_resp(ipmem_resp),
        .d_cache_read(dpmem_read),
        .d_cache_write(dpmem_write),
        .d_cache_addr(dpmem_address),
        .d_cache_wdata(dpmem_wdata),
        .d_cache_rdata(dpmem_rdata),
        .d_cache_resp(dpmem_resp),
        .ca_read(pmem_read),
        .ca_write(pmem_write),
        .ca_addr(pmem_address),
        .ca_wdata(pmem_wdata),
        .ca_rdata(pmem_rdata),
        .ca_resp(pmem_resp)
    );

    cacheline_adaptor #(s_way, s_way_num, s_plru,  s_offset, s_index, s_tag, s_mask, s_line, num_sets, num_states)
    cacheline_adaptor (
        .clk,
        .reset_n(!rst),
        .line_i(pmem_wdata),
        .line_o(pmem_rdata),
        .address_i(pmem_address),
        .read_i(pmem_read),
        .write_i(pmem_write),
        .resp_o(pmem_resp),
        // to memory
        .burst_i(bmem_rdata),
        .burst_o(bmem_wdata),
        .address_o(bmem_address),
        .read_o(bmem_read),
        .write_o(bmem_write),
        .resp_i(bmem_resp)
    );

    /*
    *                        _oo0oo_
    *                       o8888888o
    *                       88" . "88
    *                       (| -_- |)
    *                       0\  =  /0
    *                     ___/`---'\___
    *                   .' \\|     |// '.
    *                  / \\|||  :  |||// \
    *                 / _||||| -:- |||||- \
    *                |   | \\\  - /// |   |
    *                | \_|  ''\---/''  |_/ |
    *                \  .-\__  '-'  ___/-. /
    *              ___'. .'  /--.--\  `. .'___
    *           ."" '<  `.___\_<|>_/___.' >' "".
    *          | | :  `- \`.;`\ _ /`;.`/ - ` : | |
    *          \  \ `_.   \_ __\ /__ _/   .-` /  /
    *      =====`-.____`.___ \_____/___.-`___.-'=====
    *                        `=---='
    * 
    * 
    *      ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    * 
    *            佛祖保佑       永不宕机     永无BUG
    */

endmodule : mp4
