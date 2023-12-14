module tb();
import types::*;
    // Parameters
    parameter WIDTH = 64;

    // Signals
    class POS_Sigs;
        rand logic [31:0] A;
        rand logic [31:0] B;
        
        constraint input_limit { A > B;};
    endclass

    class SU_Sigs;
        rand logic signed [31:0]  A;
        rand logic [31:0]  B;
        
        constraint input_limit { A <= 0;};
    endclass

    class SS_Sigs;
        rand logic signed [31:0]  A;
        rand logic signed [31:0]  B;
        
        constraint input_limit { A <= 0; B <= 0;};
    endclass

    // DUT
    logic clk, rst, div_en, resp, signed_en;
    logic signed [31:0] dividend, divisor, quotient, remainder;
    logic signed [31:0] result;
    logic [2:0] funct3;
    initial begin
        clk = 1'b0;
        forever begin
            #5;
            clk = ~clk;
        end
    end
    Divider dut (
        .clk(clk),
        .rst(rst),
        .div_en(div_en),
        .dividend(dividend),
        .divisor(divisor),
        .signed_en(signed_en),
        .quotient(quotient),
        .remainder(remainder),
        .resp(resp)
    );
    logic signed [31:0] golden_quotient, golden_remainder;
    // Stimulus
    initial begin
        // Initialize
        // Test
        $display("Starting unsigned divider tests");
        for (integer i = 0; i < 100; i++) begin
            POS_Sigs sig = new();
            sig.randomize();
            dividend <= sig.A;
            divisor <= sig.B;
            div_en <= 1;
            rst <= 0;
            signed_en <= 0;
            golden_quotient <= sig.A / sig.B;
            golden_remainder <= sig.A % sig.B;
            @(posedge clk iff resp);
            div_en <= 0;
            $display("Starting iteration %d, Dividend: %0d, Divisor: %0d, quotient: %0d, remainder: %0d", i, dividend, divisor, quotient, remainder);
            // Check
            if (quotient !== golden_quotient)
                $display("Test failed: A = %0d, B = %0d\nquotient: %0d\nexpected: %0d", dividend, divisor, quotient, golden_quotient);
            if (remainder !== golden_remainder)
                $display("Test failed: A = %0d, B = %0d\nremainder: %0d\nexpected: %0d", dividend, divisor, remainder, golden_remainder);
            @(posedge clk);
        end
        $display("Starting signed divider tests");
        signed_en <= 1;
        for (integer i = 0; i < 100; i++) begin
            SS_Sigs sig = new();
            sig.randomize();
            dividend <= sig.A;
            divisor <= sig.B;
            div_en <= 1;
            rst <= 0;
            signed_en <= 1;
            golden_quotient <= sig.A / sig.B;
            golden_remainder <= sig.A % sig.B;
            @(posedge clk iff resp);
            div_en <= 0;
            $display("Starting iteration %d, Dividend: %0d, Divisor: %0d, quotient: %0d, remainder: %0d", i, dividend, divisor, quotient, remainder);
            // Check
            if (quotient !== golden_quotient)
                $display("Test failed: quotient: %0d\nexpected: %0d", quotient, golden_quotient);
            if (remainder !== golden_remainder)
                $display("Test failed: remainder: %0d\nexpected: %0d", remainder, golden_remainder);

            $display("\n");
            @(posedge clk);
        end
        div_en <= 0;
        $display("Test completed");
        $finish;
    end
    initial begin
        $fsdbDumpfile("dump.fsdb");
        $fsdbDumpvars(0, "+all");
    end
endmodule
