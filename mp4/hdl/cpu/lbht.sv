module lbht
import types::*;
(   
    input clk,
    input rst,
    input update,
    input br_mem,
    input rv32i_word imem_address,
    input state_word_t ifid_state_out,
    input state_word_t idex_state_out,
    input state_word_t exmem_state_out,
    output state_word_t state_out,
    output logic mispredicted,
    output logic br_predicted 
);

state_t pht [64];
logic [5:0] bhrt [32];

state_t updated_state;
logic [5:0] updated_bhr;

assign br_predicted = (state_out.state == st || state_out.state == wt);

always_comb begin
    state_out.bhrt_index = imem_address[6:2];
    state_out.bhr = bhrt[state_out.bhrt_index];
    state_out.state = pht[state_out.bhr];
end

always_comb begin
    updated_state = exmem_state_out.state;
    mispredicted = '0;

    if (update) begin
        unique case (exmem_state_out.state)
            sn: begin
                if (br_mem) begin
                    updated_state = wn;
                    mispredicted = '1;
                end
                else begin
                    updated_state = sn;
                end
            end
            wn: begin
                if (br_mem) begin
                    updated_state = wt;
                    mispredicted = '1;
                end
                else begin
                    updated_state = sn;
                end
            end
            wt: begin
                if (!br_mem) begin
                    updated_state = wn;
                    mispredicted = '1;
                end
                else begin
                    updated_state = st;
                end
            end
            st: begin
                if (!br_mem) begin
                    updated_state = wt;
                    mispredicted = '1;
                end
                else begin
                    updated_state = st;
                end
            end
            default: ;
        endcase
    end
end

always_ff @(posedge clk) begin
    if (rst) begin
        for (int i = 0; i < 64; i = i + 1) begin
            pht[i] <= wn;
        end
        for (int j = 0; j < 32; j = j + 1) begin
            bhrt[j] <= 6'b0;
        end
    end
    else if (update) begin
        bhrt[exmem_state_out.bhrt_index] <= {bhrt[exmem_state_out.bhrt_index][4:0], br_mem};
        pht[exmem_state_out.bhr] <= updated_state;
    end
end

endmodule