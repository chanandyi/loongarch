`timescale 1ns / 1ps

`include "defines.vh"

module myCPU (
    input  wire         cpu_rstn,
    input  wire         cpu_clk,
    
    // Instruction Fetch Interface
    output wire         ifetch_rreq,    // CPUȡָ�����ź�(ȡָʱΪ1)
    output wire [31:0]  ifetch_addr,    // ȡָ��ַ
    input  wire         ifetch_valid,   // ����ָ����������Ч�ź�
    input  wire [31:0]  ifetch_inst,    // ���ص�ָ�������
    
    // Data Access Interface
    output wire [ 3:0]  daccess_ren,    // ��ʹ�ܣ�����������ʱ��Ϊ4'hF
    output wire [31:0]  daccess_addr,   // ??/д��??
    input  wire         daccess_valid,  // ��������Ч��??
    input  wire [31:0]  daccess_rdata,  // ����??
    output wire [ 3:0]  daccess_wen,    // дʹ??
    output wire [31:0]  daccess_wdata,  // д��??
    input  wire         daccess_wresp,  // д��??

    // inc_dev
    input  wire         ex_flag,        // ���ź���Ч��ʾ��Ҫִ��ָ���Ч��������ִ�м���ָ��
    input  wire [31:0]  ex_inst,        // ��ִ��ָ��
    output wire         ex_finish,      // ִ�н��������ߴ��ź�
    input  wire         sync_pc_inc,    // PCͬ���źţ�˳��ִ�У�
    input  wire         sync_pc_we,     // PCͬ���źţ���֧��ת���쳣��
    input  wire [31:0]  sync_pc,        // PCͬ��??  ����֧��ת���쳣��
    input  wire         sync_wb_we,     // WB�׶ε�д��ͬ����дʹ??
    input  wire [31:0]  sync_wb_pc,     // WB�׶ε�д��ͬ����д�ؽ׶ε�PC??
    input  wire [ 4:0]  sync_wb_wreg,   // WB�׶ε�д��ͬ������д�ļĴ���??
    input  wire [31:0]  sync_wb_wdata,  // WB�׶ε�д��ͬ������д����
`ifndef IMPL_TRAP
    input  wire         excp_occur,     // ��???CPUִ��ָ����쳣
`endif

    // Debug Interface
    output wire         debug_wb_valid, // д�ؽ׶���Ч�ź�
    output wire [31:0]  debug_wb_pc,    // д�ؽ׶�PC
    output wire [ 3:0]  debug_wb_ena,   // д�ؽ׶εļĴ�����дʹ��
    output wire [ 4:0]  debug_wb_reg,   // д�ؽ׶α�д�Ĵ����ļĴ�����
    output wire [31:0]  debug_wb_value  // д�ؽ׶�д��Ĵ���������
);

/****** inc_dev ******/
wire        jump_taken;
assign      ex_finish = wb_valid;
`ifndef IMPL_TRAP
wire        wb_we_no_excp;
assign      wb_we_no_excp = wb_rf_we & !excp_occur;     // �����쳣ʱ����WB�׶ε�дʹ�ܣ�ʹ�쳣ָ�д
`endif

reg suspend_restore;
always @(posedge cpu_clk or negedge cpu_rstn) begin
    suspend_restore <= !cpu_rstn ? 1'b0 : (ldst_suspend | jump_taken | suspend_restore) & ex_flag;
end

reg [31:0] ex_inst_r;
always @(posedge cpu_clk or negedge cpu_rstn) begin
    ex_inst_r <= !cpu_rstn ? 32'h0 : ex_inst; 
end

assign      ifetch_rreq = ex_flag;          // ��Ҫִ��ָ��ʱmyCPU����ȡָ����
assign      ifetch_addr = if_pc;            // �Ե�ǰPCֵ����ȡָ����
wire        inst_valid  = ifetch_valid;
wire [31:0] inst        = ifetch_inst;

/****** inc_dev ******/

// IF stage signals
wire        if_valid;           // IF�׶���Ч�źţ���Ч��ʾ��ǰ��ָ��������IF�׶�??
reg         ldst_suspend;       // ִ�зô�ָ��ʱ����ˮ����ͣ��??
reg         ldst_unalign;       // �ô�ָ��ķô��??�Ƿ������������
wire        load_use;

wire [31:0] if_pc;              // IF�׶ε�PC??
wire [31:0] if_npc;             // IF�׶ε���??��ָ��PC??
wire [31:0] if_pc4;             // IF�׶�PC??+4

// ID stage signals
wire        id_valid;           // ID�׶���Ч�źţ���Ч��ʾ��ǰ��ָ��������ID�׶�??
wire [31:0] id_pc;              // ID�׶ε�PC??
wire [31:0] id_pc4;             // ID�׶�PC??+4
wire [31:0] id_inst;            // ID�׶ε�ָ����

wire [ 1:0] id_npc_op;          // ID�׶ε�npc_op�����ڿ�����??��ָ��PCֵ������
wire [ 2:0] id_ext_op;          // ID�׶ε���������չop�����ڿ�����������չ��ʽ
wire        id_offs_sel;        // ID�׶ε���ת��ַƫ����ѡ��
wire [ 2:0] id_ram_ext_op;      // ID�׶εĶ�����������չop�����ڿ�������������ݵ���չ��ʽ�����loadָ��??
wire [ 4:0] id_alu_op;          // ID�׶ε�alu_op�����ڿ���ALU���㷽ʽ
wire        id_rf_we;           // ID�׶εļĴ���дʹ�ܣ�ָ��??Ҫд��ʱrf_we??1??
wire [ 3:0] id_ram_we;          // ID�׶ε�����дʹ���źţ����storeָ��??
wire        id_r2_sel;          // ID�׶ε�Դ�Ĵ�??2ѡ���źţ�???��rk��rd??
wire        id_wr_sel;          // ID�׶ε�Ŀ�ļĴ���ѡ���źţ�???��rd��r1??
wire [ 1:0] id_wd_sel;          // ID�׶ε�д������???��???��ALUִ�н��д�أ���ѡ��ô�����д�أ�etc.??
wire        id_rR1_re;          // ID�׶ε�Դ�Ĵ�??1����־�źţ���Чʱ��ʾָ����Ҫ��Դ�Ĵ���1��ȡ��������
wire        id_rR2_re;          // ID�׶ε�Դ�Ĵ�??2����־�źţ���Чʱ��ʾָ����Ҫ��Դ�Ĵ���2��ȡ��������
wire        id_alua_sel;        // ID�׶ε�ALU������Aѡ���źţ�???��Դ�Ĵ���1��???��PC??
wire        id_alub_sel;        // ID�׶ε�ALU������Bѡ���źţ�???��Դ�Ĵ���2��???����չ�����������

wire [31:0] id_rD1;             // ID�׶ε�Դ�Ĵ�??1��???
wire [31:0] id_rD2;             // ID�׶ε�Դ�Ĵ�??2��???
wire [31:0] id_ext;             // ID�׶ε���չ���������
wire [31:0] id_offs;            // ID�׶ε���ת��ַƫ����
wire [ 4:0] id_rR1 = id_inst[9:5];                                  // ��ָ�����н�����Դ�Ĵ���1�ı�??
wire [ 4:0] id_rR2 = id_r2_sel ? id_inst[14:10] : id_inst[4:0];     // ѡ��Դ�Ĵ���2
wire [ 4:0] id_wR  = id_wr_sel ? id_inst[ 4: 0] : 5'h1;             // ѡ��Ŀ�ļĴ�??

wire [31:0] fd_rD1;             // ǰ???��ID�׶ε�Դ����??1
wire [31:0] fd_rD2;             // ǰ???��ID�׶ε�Դ����??2
wire        fd_rD1_sel;         // ID�׶ε�Դ����??1ѡ���źţ�???��ǰ???���ݻ�Դ�Ĵ���1��???��
wire        fd_rD2_sel;         // ID�׶ε�Դ����??2ѡ���źţ�???��ǰ???���ݻ�Դ�Ĵ���2��???��
wire [31:0] id_real_rD1 = fd_rD1_sel ? fd_rD1 : id_rD1;     // ID�׶ε�Դ�Ĵ�??1��ʵ����??
wire [31:0] id_real_rD2 = fd_rD2_sel ? fd_rD2 : id_rD2;     // ID�׶ε�Դ�Ĵ�??2��ʵ����??

// EX stage signals
wire        ex_valid;           // EX�׶���Ч�źţ���Ч��ʾ��ǰ��ָ��������EX�׶�??
wire [ 1:0] ex_npc_op;          // EX�׶ε�npc_op�����ڿ�����??��ָ��PCֵ������
wire [ 2:0] ex_ram_ext_op;      // EX�׶εĶ�����������չop�����ڿ�������������ݵ���չ��ʽ�����loadָ��??
wire [ 4:0] ex_alu_op;          // EX�׶ε�alu_op�����ڿ���ALU���㷽ʽ
wire        ex_rf_we;           // EX�׶εļĴ���дʹ�ܣ�ָ��??Ҫд��ʱrf_we??1??
wire [ 3:0] ex_ram_we;          // EX�׶ε�����дʹ���źţ����storeָ��??
wire [ 1:0] ex_wd_sel;          // EX�׶ε�д������???��???��ALUִ�н��д�أ���ѡ��ô�����д�أ�etc.??
wire        ex_alua_sel;        // EX�׶ε�ALU������Aѡ���źţ�???��Դ�Ĵ���1��???��PC??
wire        ex_alub_sel;        // EX�׶ε�ALU������Bѡ���źţ�???��Դ�Ĵ���2��???����չ�����������

wire [ 4:0] ex_wR;              // EX�׶ε�Ŀ�ļĴ���
wire [31:0] ex_rD1;             // EX�׶ε�Դ�Ĵ�??1��???
wire [31:0] ex_rD2;             // EX�׶ε�Դ�Ĵ�??2��???
wire [31:0] ex_pc;              // EX�׶ε�PC??
wire [31:0] ex_pc4;             // EX�׶ε�PC??+4
wire [31:0] ex_ext;             // EX�׶ε�������

wire [31:0] ex_alu_A = ex_alua_sel ? ex_rD1 : ex_pc;    // EX�׶ε�ALU������A
wire [31:0] ex_alu_B = ex_alub_sel ? ex_rD2 : ex_ext;   // EX�׶ε�ALU������B
wire [31:0] ex_alu_C;                                   // EX�׶ε�ALU������
wire        ex_jump_flag;                                  // EX�׶ε�������ָ֧����ת��־

reg  [31:0] ex_wd;                                      // EX�׶εĴ�д������
wire        ex_sel_ram = (ex_wd_sel == `WD_RAM);        // EX�׶��Ƿ��Ƿô�ָ�� (��ָLoadָ��)

// MEM stage signals
wire        mem_valid;          // MEM�׶���Ч�źţ���Ч��ʾ��ǰ��ָ������MEM�׶Σ�
wire [ 4:0] mem_wR;             // MEM�׶ε�Ŀ�ļĴ���
wire [31:0] mem_alu_C;          // MEM�׶ε�ALU������
wire [31:0] mem_rD2;            // MEM�׶ε�Դ�ļĴ���2��???
wire [31:0] mem_pc4;            // MEM�׶ε�PC+4
wire [31:0] mem_ext;            // MEM�׶ε�������

wire [ 2:0] mem_ram_ext_op;     // MEM�׶εĶ�����������չop�����ڿ�������������ݵ���չ��ʽ�����loadָ�
wire [ 1:0] mem_wd_sel;         // MEM�׶ε�д������???��???��ALUִ�н��д�أ���ѡ��ô�����д�أ�etc.??
wire        mem_rf_we;          // MEM�׶εļĴ���дʹ�ܣ�ָ��??Ҫд��ʱrf_we??1??
wire [ 3:0] mem_ram_we;         // MEM�׶ε�����дʹ���źţ����storeָ��)
wire [31:0] mem_ram_ext;        // MEM�׶ξ�����չ�Ķ���������
reg  [31:0] mem_wd;             // MEM�׶εĴ�д������

// WB stage signals
wire        wb_valid;           // WB�׶���Ч�źţ���Ч��ʾ��ǰ��ָ��������WB�׶�??
wire [ 4:0] wb_wR;              // WB�׶ε�Ŀ�ļĴ���
wire [31:0] wb_pc4;             // WB�׶ε�PC??+4
wire [31:0] wb_alu_C;           // WB�׶ε�ALU������
wire [31:0] wb_ram_ext;         // WB�׶εľ�����չ�Ķ�������??
wire        wb_rf_we;           // WB�׶εļĴ���дʹ??
wire [ 1:0] wb_wd_sel;          // WB�׶ε�д������???��???��ALUִ�н��д�أ���ѡ��ô�����д�أ�etc.??
reg  [31:0] wb_wd;              // WB�׶ε�д����??

// IF
PC u_PC(
    .cpu_clk        (cpu_clk),
    .cpu_rstn       (cpu_rstn),
    .suspend        (load_use | ldst_suspend),     // ��ˮ����ͣ�ź�
    .din            (if_npc),           // ��һ��ָ���ַ
    .pc             (if_pc),            // ��ǰPC
    .valid          (if_valid),         // IF�׶���Ч�ź�

    // inc_dev
    .ex_flag        (inst_valid ),  // inst_valid��Ч��ʾָ���Ѵ�����ȡ�أ��ʿ�ʼִ��ָ��
    .sync_inc       (sync_pc_inc),
    .sync_we        (sync_pc_we),
    .sync_pc        (sync_pc),
    .jump_taken     (jump_taken),
    .suspend_restore(suspend_restore)
);

NPC u_NPC(
    .npc_op     (ex_valid ? ex_npc_op : `NPC_PC4),  // ��EX�׶���Ч����IF�׶�Ĭ��˳��ִ��
    .if_pc      (if_pc),
    .id_offs    (id_offs),
    .id_rD1     (id_rD1),
    .ex_pc      (ex_pc),
    .jump_flag  (ex_jump_flag),
    .pc4        (if_pc4),
    .npc        (if_npc),

    // inc_dev
    .jump_taken (jump_taken)
);

// IF/ID
IF_ID u_IF_ID(
    .cpu_clk    (cpu_clk),
    .cpu_rstn   (cpu_rstn),
    .suspend    (load_use | ldst_suspend),         // ִ�зô�ָ��ʱ��ͣ��ˮ��
    .valid_in   (if_valid),

    .pc_in      (if_pc),
    .pc4_in     (if_pc4),
    .inst_in    (inst),

    .valid_out  (id_valid),
    .pc_out     (id_pc),
    .pc4_out    (id_pc4),
    .inst_out   (id_inst)
);

// ID
CU u_CU(
    .din        (id_inst[31:15]),
    .npc_op     (id_npc_op),
    .ext_op     (id_ext_op),
    .offs_sel   (id_offs_sel),
    .ram_ext_op (id_ram_ext_op),
    .alu_op     (id_alu_op),
    .rf_we      (id_rf_we),
    .ram_we     (id_ram_we),
    .r2_sel     (id_r2_sel),
    .wr_sel     (id_wr_sel),
    .wd_sel     (id_wd_sel),
    .rR1_re     (id_rR1_re),
    .rR2_re     (id_rR2_re),
    .alua_sel   (id_alua_sel),
    .alub_sel   (id_alub_sel)
);

RF u_RF(
    .cpu_clk    (cpu_clk),
    .rR1        (id_rR1),
    .rR2        (id_rR2),
    .wR         (wb_wR),
`ifndef IMPL_TRAP
    .we         (wb_we_no_excp),        // �����쳣ʱ����д��
`else
    .we         (wb_rf_we),
`endif
    .wD         (wb_wd),
    .rD1        (id_rD1),
    .rD2        (id_rD2),
    
    // inc_dev
    .sync_we    (sync_wb_we),
    .sync_dst   (sync_wb_wreg),
    .sync_val   (sync_wb_wdata)
);

EXT u_EXT(
    .din    (id_inst[25:0]),            // ָ�����е��������ֶ�
    .ext_op (id_ext_op),                // ��չ��ʽ
    .ext    (id_ext)                    // ��չ���������
);

OFFS u_OFFS(
    .din     (id_inst[25:0]),   // ָ�����еĵ�ַƫ�����ֶ�
    .offs_sel (id_offs_sel),       // ��ַƫ����ѡ��
    .offs    (id_offs)            // ��չ��ĵ�ַƫ����
);

// ID/EX
ID_EX u_ID_EX(
    .cpu_clk        (cpu_clk),
    .cpu_rstn       (cpu_rstn),
    .suspend        (ldst_suspend),
    .valid_in       (id_valid & !load_use),

    .wR_in          (id_wR),
    .pc_in          (id_pc),
    .pc4_in         (id_pc4),
    .rD1_in         (id_real_rD1),
    .rD2_in         (id_real_rD2),
    .ext_in         (id_ext),

    .npc_op_in      (id_npc_op),
    .rf_we_in       (id_rf_we & id_valid & !load_use),  // ��ID�׶α���Ϊ��Ч������Ĵ���дʹ��
    .wd_sel_in      (id_wd_sel),
    .alu_op_in      (id_alu_op),
    .alua_sel_in    (id_alua_sel),
    .alub_sel_in    (id_alub_sel),
    .ram_we_in      (id_ram_we),
    .ram_ext_op_in  (id_ram_ext_op),

    .valid_out      (ex_valid),
    .wR_out         (ex_wR),
    .pc_out         (ex_pc),
    .pc4_out        (ex_pc4),
    .rD1_out        (ex_rD1),
    .rD2_out        (ex_rD2),
    .ext_out        (ex_ext),

    .npc_op_out     (ex_npc_op),
    .rf_we_out      (ex_rf_we),
    .wd_sel_out     (ex_wd_sel),
    .alu_op_out     (ex_alu_op),
    .alua_sel_out   (ex_alua_sel),
    .alub_sel_out   (ex_alub_sel),
    .ram_we_out     (ex_ram_we),
    .ram_ext_op_out (ex_ram_ext_op)
);

// EX
ALU u_ALU(
    .A          (ex_alu_A),
    .B          (ex_alu_B),
    .C          (ex_alu_C),
    .jump_flag  (ex_jump_flag),
    .alu_op     (ex_alu_op)
);

always @(*) begin
    // ����ѡ���źţ���EX�׶�ѡ����Ӧ����������ǰ��
    case (ex_wd_sel)
        `WD_RAM: ex_wd = 32'h0;
        `WD_ALU: ex_wd = ex_alu_C;
        default: ex_wd = 32'h12345678;
    endcase

    // �жϷô��ַ�Ƿ���룬��ַ������ʱ���ô�
    case (ex_ram_we)
    `RAM_WE_N :begin ldst_unalign = (ex_alu_C == 2'b00); end
    default: 
            case (ex_ram_ext_op)
                `RAM_EXT_H : ldst_unalign = (ex_alu_C[1:0] != 2'h0) & (ex_alu_C[1:0] != 2'h2);
                default    : ldst_unalign = 1'b0;
            endcase
    endcase
end
always @(posedge cpu_clk or negedge cpu_rstn) begin
    if (!cpu_rstn | daccess_valid | daccess_wresp)
        ldst_suspend <= 1'b0;       // �ô������λ��ˮ����ͣ�ź�
    else if (ex_valid & (ex_wd_sel == `WD_RAM) & !ldst_unalign)
        ldst_suspend <= 1'b1;       // ִ�зô�ָ��ʱ��������ˮ����ͣ�ź�
end

// EX/MEM
EX_MEM u_EX_MEM(
    .cpu_clk        (cpu_clk),
    .cpu_rstn       (cpu_rstn),
    .suspend        (ldst_suspend),
    .valid_in       (ex_valid),

    .wR_in          (ex_wR),
    .pc4_in         (ex_pc4),
    .alu_C_in       (ex_alu_C),
    .rD2_in         (ex_rD2),
    .ext_in         (ex_ext),

    .rf_we_in       (ex_rf_we & !ldst_unalign),     // ����??�����룬��д??
    .wd_sel_in      (ex_wd_sel),
    .ram_we_in      (ex_ram_we),
    .ram_ext_op_in  (ex_ram_ext_op),

    .valid_out      (mem_valid),
    .wR_out         (mem_wR),
    .pc4_out        (mem_pc4),
    .alu_C_out      (mem_alu_C),
    .rD2_out        (mem_rD2),
    .ext_out        (mem_ext),

    .rf_we_out      (mem_rf_we),
    .wd_sel_out     (mem_wd_sel),
    .ram_we_out     (mem_ram_we),
    .ram_ext_op_out (mem_ram_ext_op)
);

// MEM
RAM_EXT u_RAM_EXT(
    .din            (daccess_rdata),    // ��������ص�����
    .byte_offset    (mem_alu_C[1:0]),   // �ô��ַ���2λ
    .ram_ext_op     (mem_ram_ext_op),   // ��չ��ʽ
    .ext_out        (mem_ram_ext)       // ��չ�������
);
// ����ѡ���źţ���MEM�׶�ѡ����Ӧ����������ǰ??
always @(*) begin
    case (mem_wd_sel)
        `WD_RAM: mem_wd = mem_ram_ext;
        `WD_ALU: mem_wd = mem_alu_C;
        default: mem_wd = 32'h87654321;
    endcase
end

// Generate load/store requests
MEM_REQ u_MEM_REQ (
    .clk            (cpu_clk       ),
    .rstn           (cpu_rstn      ),
    .ex_valid       (ex_valid      ),       // EX�׶���Ч�ź�
    .mem_wd_sel     (mem_wd_sel    ),       // ���ֵ�ǰ�Ƿ��Ƿô�ָ��
    .mem_ram_addr   (mem_alu_C     ),       // ��ALU����õ��ķô��ַ

    .mem_ram_ext_op (mem_ram_ext_op),       // ���ֵ�ǰ������loadָ��
    .da_ren         (daccess_ren   ),
    .da_addr        (daccess_addr  ),

    .mem_ram_we     (mem_ram_we    ),       // ���ֵ�ǰ��loadָ���storeָ��Լ�����һ��storeָ��
    .mem_ram_wdata  (mem_rD2       ),
    .da_wen         (daccess_wen   ),
    .da_wdata       (daccess_wdata )
);

// MEM/WB
MEM_WB u_MEM_WB(
    .cpu_clk        (cpu_clk),
    .cpu_rstn       (cpu_rstn),
    .suspend        (ldst_suspend),
    .valid_in       (mem_valid),

    .wR_in          (mem_wR),
    .pc4_in         (mem_pc4),
    .alu_C_in       (mem_alu_C),
    .ram_ext_in     (mem_ram_ext),
    .ext_in         (mem_ext),

    .rf_we_in       (mem_rf_we),
    .wd_sel_in      (mem_wd_sel),

    .valid_out      (wb_valid),
    .wR_out         (wb_wR),
    .pc4_out        (wb_pc4),
    .alu_C_out      (wb_alu_C),
    .ram_ext_out    (wb_ram_ext),

    .rf_we_out      (wb_rf_we),
    .wd_sel_out     (wb_wd_sel)
);

// WB
// ����ѡ���źţ���WB�׶�ѡ����Ӧ����������ǰ��
always @(*) begin
    case (wb_wd_sel)
        `WD_RAM: wb_wd = wb_ram_ext;
        `WD_ALU: wb_wd = wb_alu_C;
        `WD_PC4: wb_wd = wb_pc4;
        default: wb_wd = 32'haabbccdd;
    endcase
end

// Data Hazard Detection & Data Forward
data_forward u_DF(
    .id_rR1         (id_rR1),
    .id_rR2         (id_rR2),
    .id_rR1_re      (id_rR1_re),
    .id_rR2_re      (id_rR2_re),

    .ex_wd          (ex_wd),
    .ex_wr          (ex_wR),
    .ex_we          (ex_rf_we & ex_valid),

    .mem_wd         (mem_wd),
    .mem_wr         (mem_wR),
    .mem_we         (mem_rf_we),

    .wb_wd          (wb_wd),
    .wb_wr          (wb_wR),
    .wb_we          (wb_rf_we),

    .ex_sel_ram     (ex_sel_ram),
    .suspend_finish (!ldst_suspend),
    .load_use       (load_use),

    .fd_rD1         (fd_rD1),
    .fd_rD1_sel     (fd_rD1_sel),
    .fd_rD2         (fd_rD2),
    .fd_rD2_sel     (fd_rD2_sel)
);



// Debug Interface
assign debug_wb_valid = wb_valid;
assign debug_wb_pc    = sync_wb_we ? sync_wb_pc      : wb_pc4 - 4;
`ifndef IMPL_TRAP
assign debug_wb_ena   = sync_wb_we ? {4{sync_wb_we}} : {4{wb_we_no_excp}};
`else
assign debug_wb_ena   = sync_wb_we ? {4{sync_wb_we}} : {4{wb_rf_we}};
`endif
assign debug_wb_reg   = sync_wb_we ? sync_wb_wreg    : wb_wR;
assign debug_wb_value = sync_wb_we ? sync_wb_wdata   : wb_wd;

endmodule
