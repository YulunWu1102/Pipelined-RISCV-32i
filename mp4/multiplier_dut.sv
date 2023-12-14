module tb();
import types::*;
    // Parameters
    parameter WIDTH = 64;

    // Signals
    class POS_Sigs;
        rand logic [31:0] A;
        rand logic [31:0] B;
        
        constraint input_limit { A >= 0; B>= 0;};
    endclass

    class SU_Sigs;
        rand logic signed [31:0]  A;
        rand logic [31:0]  B;
        
        constraint input_limit { A <= 0;};
    endclass

    class SS_Sigs;
        rand logic signed [31:0]  A;
        rand logic signed [31:0]  B;
        
        // constraint input_limit { A <= 0;};
    endclass

    // DUT
    logic clk, rst, mul_en, resp;
    logic [31:0] A, B;
    logic signed [31:0] result;
    logic [2:0] funct3;
    initial begin
        clk = 1'b0;
        forever begin
            #5;
            clk = ~clk;
        end
    end
    Multiplier dut (
        .clk(clk),
        .rst(rst),
        .mul_en(mul_en),
        .multiplier(A),
        .multiplicand(B),
        .mul_funct3(funct3),
        .mul_out(result),
        .resp(resp)
    );
    logic signed [63:0] golden_result;
    // Stimulus
    initial begin
        // Initialize
        // Test
        $display("Starting unsigned x unsigned multiplier tests -- lower");
        for (integer i = 0; i < 100; i++) begin
            POS_Sigs sig = new();
            sig.randomize();
            A <= sig.A;
            B <= sig.B;
            mul_en <= 1;
            rst <= 0;
            funct3 <= mul;
            golden_result <= sig.A * sig.B;
            @(posedge clk iff resp);
            $display("Starting iteration %d, A: %b, B: %b", i, A, B);
            // Check
            if (result !== golden_result[31:0])
                $display("Test failed: A = %0d, B = %0d, RESULT: %0d", A, B, result[31:0]);
        end
        $display("Starting unsigned x unsigned multiplier tests -- higher");
        for (integer i = 0; i < 100; i++) begin
            POS_Sigs sig = new();
            sig.randomize();
            A <= sig.A;
            B <= sig.B;
            mul_en <= 1;
            rst <= 0;
            funct3 <= mulhu;
            golden_result <= sig.A * sig.B;
            @(posedge clk iff resp);
            $display("Starting iteration %d, A: %b, B: %b", i, A, B);
            // Check
            if (result !== golden_result[63:32])
                $display("Test failed: RESULT vs EXPECTED: \n%b\n%b\n", result, golden_result[63:32]);
        end

        $display("Starting signed x unsigned multiplier tests -- higher");
        for (integer i = 0; i < 100; i++) begin
            SU_Sigs sig = new();
            sig.randomize();
            A <= sig.A;
            B <= sig.B;
            mul_en <= 1;
            rst <= 0;
            funct3 <= mulhsu;
            golden_result <= sig.A * sig.B;
            @(posedge clk iff resp);
            $display("Starting iteration %d, A: %b, B: %b", i, A, B);
            // Check
            if (result !== golden_result[63:32])
                $display("Test failed: RESULT vs EXPECTED: \n%b\n%b\n", result, golden_result[63:32]);
        end
        $display("Starting signed x signed multiplier tests -- higher");
        for (integer i = 0; i < 100; i++) begin
            SS_Sigs sig = new();
            sig.randomize();
            A <= sig.A;
            B <= sig.B;
            mul_en <= 1;
            rst <= 0;
            funct3 <= mulh;
            golden_result <= sig.A * sig.B;
            @(posedge clk iff resp);
            $display("Starting iteration %d, A: %b, B: %b", i, A, B);
            // Check
            if (result !== golden_result[63:32])
                $display("Test failed: RESULT vs EXPECTED: \n%b\n%b\n", result, golden_result[63:32]);
        end
        $display("Starting to test signed edge cases");
        A <= 32'd123;
        B <= 32'hffffffff;
        mul_en <= 1;
        rst <= 0;
        funct3 <= mul;
        golden_result <= 64'hffffffffffffff85;
        @(posedge clk iff resp);
        if (result !== golden_result)
                $display("Test failed: RESULT vs EXPECTED: \n%b\n%b\n", result, golden_result);
        $display("Test completed");
        $finish;
    end

    initial begin
        $fsdbDumpfile("dump.fsdb");
        $fsdbDumpvars(0, "+all");
    end
endmodule
