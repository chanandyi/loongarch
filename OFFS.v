`timescale 1ns / 1ps

`include "defines.vh"

module OFFS (
    input  wire[25:0] din,         // 指令码中的地址偏移量字段
    input  wire       offs_sel,     // 地址偏移量选择
    output reg [31:0] offs           // 扩展后的地址偏移量
);

always @(*) begin
    case(offs_sel)
        `OFFS_26_SEXT:   offs = {{4{din[9]}}, din[9:0], din[25:10], 2'b0};
        `OFFS_16_SEXT:   offs = {{14{din[25]}}, din[25:10], 2'b0};
        default:         offs = {{14{din[25]}}, din[25:10], 2'b0};
    endcase
end

endmodule