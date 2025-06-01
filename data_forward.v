`timescale 1ns / 1ps

`include "defines.vh"

module data_forward (
    input  wire [ 4:0] id_rR1,          // ID�׶ε�Դ�Ĵ���rR1
    input  wire [ 4:0] id_rR2,          // ID�׶ε�Դ�Ĵ���rR2
    input  wire        id_rR1_re,       // ID�׶ε�ָ���Ƿ���Ҫ��rR1��ȡ����
    input  wire        id_rR2_re,       // ID�׶ε�ָ���Ƿ���Ҫ��rR2��ȡ����

    input  wire [31:0] ex_wd,           // EX�׶β�����ִ�н��
    input  wire [ 4:0] ex_wr,           // EX�׶ε�Ŀ��Ĵ���wR
    input  wire        ex_we,           // EX�׶ε�дʹ���ź�

    input  wire [31:0] mem_wd,          // MEM�׶β�����ִ�н��
    input  wire [ 4:0] mem_wr,          // MEM�׶ε�Ŀ��Ĵ���wR
    input  wire        mem_we,          // MEM�׶ε�дʹ���ź�

    input  wire [31:0] wb_wd,           // WB�׶β�����ִ�н��
    input  wire [ 4:0] wb_wr,           // WB�׶ε�Ŀ��Ĵ���wR
    input  wire        wb_we,           // WB�׶ε�дʹ���ź�

    input  wire        ex_sel_ram,      // EX�׶��Ƿ��Ƿô�ָ�� (��ָLoadָ��)
    input  wire        suspend_finish,  // ���ź���Ч��ʾ��ô�ָ����ɵ���ˮ����ͣ�ѽ���
    output wire        load_use,        // ���ź���Ч��ʾ��⵽ID��EX�׶δ���Load-Useð��

    output reg  [31:0] fd_rD1,          // ǰ�ݵ�ID�׶ε�Դ������1
    output reg         fd_rD1_sel,      // ����ǰ�ݵ�����ѡ���ź�
    output reg  [31:0] fd_rD2,          // ǰ�ݵ�ID�׶ε�Դ������2
    output reg         fd_rD2_sel       // ����ǰ�ݵ�����ѡ���ź�
);

assign load_use = ((id_rR1 == ex_wr) & id_rR1_re | (id_rR2 == ex_wr) & id_rR2_re) & ex_we & ex_sel_ram;

// ID�׶�Դ������1������ǰ���߼�
always @(*) begin
    if (id_rR1 == 5'h0) begin                                       // 0�żĴ���ֻ�����ų�֮
        fd_rD1     = 32'h0;
        fd_rD1_sel = 1'b0;      // 0��ʾ��ǰ��
    end else if ((id_rR1 == ex_wr) & id_rR1_re & ex_we) begin       // ID��EX��������ð��
        fd_rD1     = ex_wd;
        fd_rD1_sel = 1'b1;
    end else if ((id_rR1 == mem_wr) & id_rR1_re & mem_we) begin     // ID��MEM��������ð��
        fd_rD1     = mem_wd;
        fd_rD1_sel = 1'b1;
    end else if ((id_rR1 == wb_wr) & id_rR1_re & wb_we) begin       // ID��WB��������ð��
        fd_rD1     = wb_wd;
        fd_rD1_sel = 1'b1;
    end else begin
        fd_rD1     = 32'h0;
        fd_rD1_sel = 1'b0;
    end
end

// ID�׶�Դ������2������ǰ���߼�
always @(*) begin
    if (id_rR2 == 5'h0) begin
        fd_rD2     = 32'h0;
        fd_rD2_sel = 1'b0;
    end else if ((id_rR2 == ex_wr) & id_rR2_re & ex_we) begin
        fd_rD2     = ex_wd;
        fd_rD2_sel = 1'b1;
    end else if ((id_rR2 == mem_wr) & id_rR2_re & mem_we) begin
        fd_rD2     = mem_wd;
        fd_rD2_sel = 1'b1;
    end else if ((id_rR2 == wb_wr) & id_rR2_re & wb_we) begin
        fd_rD2     = wb_wd;
        fd_rD2_sel = 1'b1;
    end else begin
        fd_rD2     = 32'h0;
        fd_rD2_sel = 1'b0;
    end
end

endmodule