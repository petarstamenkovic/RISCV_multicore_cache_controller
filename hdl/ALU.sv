`timescale 1ns / 1ps

module ALU
(
	input logic [31:0] A, B, 
	input logic [3:0] alu_op,
	output logic [31:0] C
);

    always_comb begin
		case (alu_op)
		    0:  C = A + B;
		    1:  C = A << B;
		    2:  C = (A < B)?1:0;
		    3:  C = (A < B)?1:0;
		    4:  C = A ^ B;
		    5:  C = A >> B;
		    6:  C = A >>> B;
		    7:  C = A | B;
		    8:  C = A & B;
		    9:  C = A - B;
		    10: C = B;
		    default: C = 0;
		endcase
    end
endmodule
