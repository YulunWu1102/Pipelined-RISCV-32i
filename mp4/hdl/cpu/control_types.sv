// package control_types;

// import rv32i_types::*; /* Import types defined in rv32i_types.sv */

// typedef struct {
//     // 5 x pcmux_sel (no more mar mux)
//     pcmux::pcmux_sel_t pcmux_sel,
//     alumux::alumux1_sel_t alumux1_sel,
//     alumux::alumux2_sel_t alumux2_sel,
//     regfilemux::regfilemux_sel_t regfilemux_sel,
//     cmpmux::cmpmux_sel_t cmpmux_sel,
    
//     // 2x ops
//     alu_ops aluop,
//     branch_funct3_t cmpop

//     // D-cache enable bits
//     logic [3:0] dmem_wmask, 

//     logic [3:0] rd,

//     // signal for D-cache/memory
//     logic dmem_read, dmem_write
// } control_word_t;

// endpackage control_types;
