module Divider 
import types::*;(
  input clk,
  input rst,
  input logic div_en,
  input logic [31:0] dividend,
  input logic [31:0] divisor,
  input logic signed_en,
  output logic [31:0] quotient,
  output logic [31:0] remainder,
  output logic resp
);

    logic done_flag, start;
    logic [31:0] dividend_temp, dividend_temp_in, divisor_temp, divisor_temp_in, quotient_temp, quotient_temp_in, remainder_temp_in, remainder_temp;
    enum int unsigned {IDLE, PREPARE, DIV, DONE} state, next_state;
    logic sign;
    always_ff @(posedge clk) begin
        if(rst) begin
            state <= IDLE;
            dividend_temp <= '0;
            divisor_temp <= '0;
            remainder_temp <= '0;
            quotient_temp <= 0;
        end
        else begin
            state <= next_state;
            dividend_temp <= dividend_temp_in;
            divisor_temp <= divisor_temp_in;
            remainder_temp <= remainder_temp_in;
            quotient_temp <= quotient_temp_in;
        end
    end
    always_comb begin
        next_state = state;
        unique case (state)
            IDLE: begin
                if(div_en)
                    next_state = PREPARE;
                else 
                    next_state = IDLE;
            end
            PREPARE: next_state = DIV;
            DIV: begin
                if(done_flag)
                    next_state = DONE;
                else
                    next_state = DIV;
            end
            DONE: next_state = IDLE;
        endcase
    end

    always_comb begin
        sign = dividend[31] ^ divisor[31] & signed_en;
        unique case(state)
            IDLE: begin
                resp = '0;
                start = '0;
                quotient = '0;
                remainder = '0;
                if(dividend[31] & signed_en) begin
                    dividend_temp_in = ~dividend + 1;
                end
                else begin 
                    dividend_temp_in = dividend;
                end
                if(divisor[31] & signed_en) begin 
                    divisor_temp_in = ~divisor + 1;
                end
                else begin
                    divisor_temp_in = divisor;
                end
            end
            PREPARE: begin
                resp = '0;
                start = '0;
                quotient = '0;
                remainder = '0;
                divisor_temp_in = divisor_temp;
                dividend_temp_in = dividend_temp;
            end
            DIV: begin
                resp = '0;
                start = '1;
                quotient = '0;
                remainder = '0;
                divisor_temp_in = divisor_temp;
                dividend_temp_in = dividend_temp;
            end

            DONE: begin
                resp = '1;
                start = '0;
                if(divisor_temp == 32'd0) begin
                    quotient = 32'hffffffff;
                    remainder = dividend_temp;
                end
                else begin
                    if (signed_en & dividend[31])
                        remainder = ~remainder_temp + 1;
                    else 
                        remainder = remainder_temp;
                    if(sign & signed_en) begin
                        quotient = ~quotient_temp + 1;
                    end
                    else begin
                        quotient = quotient_temp;
                    end
                end
                divisor_temp_in = divisor_temp;
                dividend_temp_in = dividend_temp;
            end
        endcase
    end

    always_ff @(posedge clk) begin
        if (start) begin
            if (divisor_temp == 32'd0) begin
                done_flag <= '1;
            end
            else if (remainder_temp >= divisor_temp) begin
                remainder_temp_in <= remainder_temp - divisor_temp;
                quotient_temp_in <= quotient_temp + 1;
            end
            else begin
                done_flag <= '1;
            end
        end
        else begin
            remainder_temp_in <= dividend_temp_in;
            quotient_temp_in <= '0;
            done_flag <= '0;
        end
            
    end
endmodule

