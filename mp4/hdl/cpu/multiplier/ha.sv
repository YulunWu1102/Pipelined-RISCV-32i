module half_adder(
    input logic A,
    input logic B,
    output logic S,
    output logic Cout
);

assign S = A ^ B;     // XOR operation for sum
assign Cout = A & B;    // AND operation for carry-out

endmodule