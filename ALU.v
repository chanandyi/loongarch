`timescale 1ns / 1ps

`include "defines.vh"

module ALU (
    input  wire [31:0]  A,
    input  wire [31:0]  B,
    input  wire [ 4:0]  alu_op,
    output reg  [31:0]  C,
    output reg          jump_flag
);




// 根据alu_op完成不同的运算操�???
always @(*) begin
    case (alu_op)
        `ALU_ADD: C = A + B;
        `ALU_SUB: C = A - B;
        `ALU_AND: C = A & B;
        `ALU_OR:  C = A | B;
        `ALU_XOR: C = A ^ B;
        `ALU_NOR: C = ~(A | B);
        `ALU_SLL: C = A << B[4:0];
        `ALU_SRL: C = A >> B[4:0];
        `ALU_SRA: C = $signed(A) >>> B[4:0];
        `ALU_SLT: C = $signed(A) < $signed(B);    // 有符号小于比�???
        `ALU_SLTU: C = A < B;                     // 无符号小于比�???
        `ALU_SLLI: C = A << B[14:10];
        `ALU_ADDI: C = A + B;
        `ALU_ANDI: C = A & B;
        `ALU_BL:   C = A + 4;
        `ALU_JIRL: C = A + 4;

        `ALU_LDW:  C = A + B;
        `ALU_STW: C = A + B;
        
        default : C = A + B;
    endcase
end

always @(*) begin
    case (alu_op)
            `ALU_BEQ:  jump_flag = A == B;
            `ALU_BGE:  jump_flag = $signed(A) >= $signed(B);
            default :  jump_flag = 0;
    endcase
end

endmodule
