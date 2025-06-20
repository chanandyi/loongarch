`timescale 1ns / 1ps

`include "defines.vh"

module NPC (
    input  wire [31:0]  if_pc,      // 当前指令的PC值
    input  wire [ 1:0]  npc_op,     // NPC操作控制信号，用于选择下一个PC值
    input  wire [31:0]  id_offs,    // ID阶段的跳转指令的地址偏移量
    input  wire [31:0]  id_rD1,     // ID阶段的源寄存器1
    input  wire [31:0]  ex_pc,      // EX 阶段的PC
    input  wire         jump_flag,    // 条件分支指令的跳转信号

    output wire [31:0]  pc4,        // 当前PC+4 的值（顺序执行的下一条指令地址）
    output reg  [31:0]  npc,        // 下一个PC的值

    // inc_dev
    output reg          jump_taken  // 跳转信号，表示是否发生了分支或跳转
);

assign pc4 = if_pc + 32'h4;
always @(*) begin
    case (npc_op)
        `NPC_PC4:   // 如果npc_op为NPC_PC4，选择顺序执行的下一条指令地址
            npc = pc4;
        `NPC_PC_OFFS_CON:
            if (jump_flag)   npc = ex_pc + id_offs;
            else            npc = pc4;
        `NPC_PC_OFFS_DIR:   npc = ex_pc + id_offs;
        `NPC_RD1_OFFS_DIR:  npc = id_rD1 + id_offs;
        default : 
            npc = pc4;  // 默认情况下，也选择顺序执行的下一条指令地址
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
