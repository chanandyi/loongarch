`timescale 1ns / 1ps

`include "defines.vh"

module OFFS (
    input  wire[25:0] din,         // ָ�����еĵ�ַƫ�����ֶ�
    input  wire       offs_sel,     // ��ַƫ����ѡ��
    output reg [31:0] offs           // ��չ��ĵ�ַƫ����
);

always @(*) begin
    case(offs_sel)
        `OFFS_26_SEXT:   offs = {{4{din[9]}}, din[9:0], din[25:10], 2'b0};
        `OFFS_16_SEXT:   offs = {{14{din[25]}}, din[25:10], 2'b0};
        default:         offs = {{14{din[25]}}, din[25:10], 2'b0};
    endcase
end

endmodule