module cacheline_adaptor#(
            parameter       s_way     = 2,
            parameter       s_way_num = 2**s_way,
            parameter       s_plru    = 2**s_way-1,
            parameter       s_offset = 5,
            parameter       s_index  = 4,
            parameter       s_tag    = 32 - s_offset - s_index,
            parameter       s_mask   = 2**s_offset,
            parameter       s_line   = 8*s_mask,
            parameter       num_sets = 2**s_index,
            parameter       num_states = (s_line / 64)-1
) 
(
    input clk,
    input reset_n,

    // Port to LLC (Lowest Level Cache)
    input logic [s_line-1:0] line_i,
    output logic [s_line-1:0] line_o,
    input logic [31:0] address_i,
    input read_i,
    input write_i,
    output logic resp_o,

    // Port to memory
    input logic [63:0] burst_i,
    output logic [63:0] burst_o,
    output logic [31:0] address_o,
    output logic read_o,
    output logic write_o,
    input resp_i
);


// global settings:
// states:

// 0: initial state, based on the request of read (read_i) or write (write_i)
//    to decide whether to load (->1) or to store (->5)

// LOAD: DRAM -> LLC
// 1, 2, 3, 4: resp_i is high, receive from burst_i, 
// 5: raise resp_o, keep cacheline data stable, set next to 0

// STORE: LLC -> DRAM
// 6, 7, 8, 9: raise 'write_o', send corresponding burst. 
// 10: disassert 'write_o', set next to 0

typedef enum int{
    INIT_STATE = 0,
    LOADING = 1,
    LOAD_END = 2,
    STORING = 3,
    STORE_END = 4
} CA_states;

CA_states state_curr;
CA_states state_next;
logic [2:0] state_counter;

always_ff @(posedge clk) begin

    case (state_curr)
        // LOAD states
        INIT_STATE: begin
            state_counter <= 3'b0;
            if (read_i) begin
                read_o <= 1'b1;
                write_o <= 1'b0;
                address_o <= address_i;
            end else if (write_i) begin
                read_o <= 1'b0;
                write_o <= 1'b1;
                address_o <= address_i;
                burst_o <= line_i [63:0]; 
            end else begin
                read_o <= 1'b0;
                write_o <= 1'b0;
            end

        end
        LOADING: begin
            if (resp_i) begin
                if (state_counter==num_states[2:0]) begin
                    resp_o <= 1'b1; 
                    read_o <= 1'b0;   
                end
                line_o [64*state_counter +: 64] <= burst_i;  

                // case (state_counter)
                //     3'b000: line_o [63:0] <= burst_i;   
                //     3'b001: line_o [127:64] <= burst_i;
                //     3'b010: line_o [191:128] <= burst_i; 
                //     3'b011: line_o [255:192] <= burst_i; 
                //     default: line_o <= 256'b0;
                // endcase

                state_counter <= state_counter + 3'b1;  
            end
        end

        LOAD_END: begin
            resp_o <= 1'b0;
            state_counter <= 3'b0;
        end

        // STORE states
        STORING: begin
            if (resp_i) begin
                if (state_counter == num_states[2:0]) begin
                    resp_o <= 1'b1;          
                    write_o <= 1'b0;             
                end else begin
                    burst_o <= line_i [64+64*state_counter +: 64]; 
                    // case (state_counter)
                    //     3'b000: burst_o <= line_i [127:64]; 
                    //     3'b001: burst_o <= line_i [191:128]; 
                    //     3'b010: burst_o <= line_i [255:192]; 
                    //     default: burst_o <= 64'b0; 
                    // endcase               
                end
                state_counter <= state_counter + 3'b1;              
            end
        end
        
        STORE_END: begin
            resp_o <= 1'b0;
            write_o <= 1'b0;
            state_counter <= 3'b0;  
        end
    endcase
end


    always_comb 
    begin 
        if(~reset_n)begin
            state_next = INIT_STATE;
        end else begin
            case (state_curr)
                INIT_STATE: begin
                    if (read_i) begin
                        state_next = LOADING;
                    end else if (write_i) begin
                        state_next = STORING;                      
                    end else begin
                        state_next = INIT_STATE;
                    end
                end

                LOADING: begin
                    if (state_counter < num_states[2:0]) begin
                        state_next = LOADING;
                    end else begin
                        state_next = LOAD_END;
                    end
                end

                LOAD_END: begin
                    state_next = INIT_STATE;
                end
                
                STORING: begin
                    if (state_counter < num_states[2:0]) begin
                        state_next = STORING;
                    end else begin
                        state_next = STORE_END;
                    end

                end

                STORE_END: begin
                    state_next = INIT_STATE;
                end
                
                default: state_next = INIT_STATE;
            endcase
        end
        
    end


always_ff @(posedge clk)
begin: next_state_assignment
    state_curr <= state_next;
end


endmodule : cacheline_adaptor
