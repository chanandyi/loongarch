`timescale 1ns / 1ps

`include "defines.vh"

module NPC (
    input  wire [31:0]  if_pc,      // ��ǰָ���PCֵ
    input  wire [ 1:0]  npc_op,     // NPC���������źţ�����ѡ����һ��PCֵ
    input  wire [31:0]  id_offs,    // ID�׶ε���תָ��ĵ�ַƫ����
    input  wire [31:0]  id_rD1,     // ID�׶ε�Դ�Ĵ���1
    input  wire [31:0]  ex_pc,      // EX �׶ε�PC
    input  wire         jump_flag,    // ������ָ֧�����ת�ź�

    output wire [31:0]  pc4,        // ��ǰPC+4 ��ֵ��˳��ִ�е���һ��ָ���ַ��
    output reg  [31:0]  npc,        // ��һ��PC��ֵ

    // inc_dev
    output reg          jump_taken  // ��ת�źţ���ʾ�Ƿ����˷�֧����ת
);

assign pc4 = if_pc + 32'h4;
always @(*) begin
    case (npc_op)
        `NPC_PC4:   // ���npc_opΪNPC_PC4��ѡ��˳��ִ�е���һ��ָ���ַ
            npc = pc4;
        `NPC_PC_OFFS_CON:
            if (jump_flag)   npc = ex_pc + id_offs;
            else            npc = pc4;
        `NPC_PC_OFFS_DIR:   npc = ex_pc + id_offs;
        `NPC_RD1_OFFS_DIR:  npc = id_rD1 + id_offs;
        default : 
            npc = pc4;  // Ĭ������£�Ҳѡ��˳��ִ�е���һ��ָ���ַ
    endcase
end

// inc_dev
// when branch or jump, set jump_taken to 1
always @(*) begin
    case (npc_op)
        `NPC_PC_OFFS_CON: 
            if (jump_flag)  jump_taken = 1'b1;
            else            jump_taken = 1'b0;
        `NPC_PC_OFFS_DIR: jump_taken = 1'b1;
        `NPC_RD1_OFFS_DIR: jump_taken = 1'b1;
        default  : jump_taken = 1'b0;
    endcase
end

endmodule
