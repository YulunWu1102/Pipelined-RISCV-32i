module gbht
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

state_t pht [16];
logic [1:0] ghr;

state_t updated_state;
logic [1:0] updated_ghr;
logic [3:0] pht_index;

assign br_predicted = (state_out.state == st || state_out.state == wt);
assign pht_index = {state_out.bhr, state_out.bhrt_index};

always_comb begin
    state_out.bhrt_index = imem_address[3:2];
    state_out.bhr = ghr;
    state_out.state = pht[pht_index];
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
        for (int i = 0; i < 16; i = i + 1) begin
            pht[i] <= wn;
        end
        ghr <= '0;
    end
    else if (update) begin
        ghr <= {ghr[0], br_mem};
        pht[{{exmem_state_out.bhr, exmem_state_out.bhrt_index}}] <= updated_state;
    end
end

endmodule