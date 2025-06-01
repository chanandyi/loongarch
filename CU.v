`timescale 1ns / 1ps

`include "defines.vh"

module CU (
    input  wire [16:0]  din,            // ?????????17??
    output wire [ 1:0]  npc_op,         // ?????????????PC
    output reg  [ 2:0]  ext_op,         // ?????????????????
    output reg          offs_sel,       // ??????????????????
    output reg  [ 2:0]  ram_ext_op,     // ?????????????????????????load?????
    output reg  [ 4:0]  alu_op,         // ????????????
    output reg          rf_we,          // ???????§Õ????????
    output reg  [ 3:0]  ram_we,         // §Õ?????§Õ??????????store?????
    output wire         r2_sel,         // ??????????2???????
    output wire         wr_sel,         // ????????????????
    output reg  [ 1:0]  wd_sel,         // ????§Õ??????
    output reg          rR1_re,         // ????????rR1????????????????
    output reg          rR2_re,         // ????????rR2????????????????
    output wire         alua_sel,       // ???ALU??????A??????
    output reg          alub_sel        // ???ALU??????B??????
);

assign npc_op = din[15] ? (din[14:12] == 3'b010  ? `NPC_PC_OFFS_DIR : ( din[14:12] == 3'b001 ? `NPC_RD1_OFFS_DIR : `NPC_PC_OFFS_CON) ): `NPC_PC4;     // ?????????????PC????????? ?? PC + 4

// ??????????????????
always @(*) begin
    case (din[15:11]) 
        5'b10100:   offs_sel = `OFFS_26_SEXT;
        5'b10101:   offs_sel = `OFFS_26_SEXT;
        default:    offs_sel = `OFFS_16_SEXT;
    endcase
end

// ????????????????
always @(*) begin
    case (din[15:13])
        3'b001 : ext_op=`EXT_20;
        3'b000 : begin 
                if (din[10]) begin
                    case (din[9:7])
                        3'b010: ext_op=`EXT_12_SEXT;
                        3'b101: ext_op=`EXT_12_ZEXT;
                        3'b110: ext_op=`EXT_12_ZEXT;
                        3'b111: ext_op=`EXT_12_ZEXT;
                        3'b000: ext_op=`EXT_12_SEXT;
                        3'b001: ext_op=`EXT_12_SEXT;
                        default: ext_op=`EXT_NONE;
                    endcase
                end else ext_op=`EXT_NONE;
        end
        default: ext_op=`EXT_NONE;
    endcase
end

//  MEM
always @(*) begin
    case (din[15:13])
        3'b010: begin
            case (din[10:7])
                4'b0110: ram_ext_op = `RAM_EXT_N;
                4'b0010: ram_ext_op = `RAM_EXT_N;
                default: ram_ext_op = `RAM_EXT_H;
            endcase
        end
        default: ram_ext_op = `RAM_EXT_H;
    endcase
end

always @(*) begin
    case (din[15:13])
        3'b010: begin
            ext_op = `EXT_12_SEXT;
        end
        default: ext_op=`EXT_NONE;
    endcase
end
// ALU???????????????
always @(*) begin
    case (din[15:13])
        3'b000: begin
            if (!din[10]) begin
                if (!din[7]) begin
                    case (din[4:0]) 
                        `FR5_ADD: alu_op = `ALU_ADD;
	                   `FR5_SUB:  alu_op = `ALU_SUB;
	                   `FR5_AND: alu_op = `ALU_AND;
	                   `FR5_OR  : alu_op = `ALU_OR;
	                   `FR5_XOR: alu_op = `ALU_XOR;
	                   `FR5_NOR: alu_op = `ALU_NOR;
	                   `FR5_SLL: alu_op = `ALU_SLL;
	                   `FR5_SRL: alu_op = `ALU_SRL;
	                   `FR5_SRA: alu_op = `ALU_SRA;
                       `FR5_SLT: alu_op = `ALU_SLT;
                       `FR5_SLTU: alu_op = `ALU_SLTU;
                        default : alu_op = `ALU_ADD;
                    endcase
                end else begin
                        case (din[4:0])
                            `FR5_SLLI: alu_op = `ALU_SLLI;
                            default:   alu_op = `ALU_SLLI;
                        endcase
                end
            end else begin
                    case (din[9:7])
                        `FR5_ADDI: alu_op = `ALU_ADDI;
                        `FR5_ANDI: alu_op = `ALU_ANDI;
                        default:   alu_op = `ALU_ADDI;
                    endcase
            end
        end
        
        3'b100: begin
            case (din[14:13])
                `FR5_JIRL:  alu_op = `ALU_JIRL;
                default:  alu_op = `ALU_JIRL;
            endcase
        end

        3'b101: begin
            case (din[12:11])
                `FR5_BEQ: alu_op = `ALU_BEQ;
                `FR5_BL:  alu_op = `ALU_BL;
                default:  alu_op = `ALU_BL;
            endcase
        end
        
        3'b110: begin
            case (din[12:11])
                `FR5_BGE: alu_op = `ALU_BGE;
                default:  alu_op = `ALU_BGE;
            endcase
        end

        3'b010: begin
            case (din[10:7])
                `FR5_LDW: alu_op = `ALU_LDW;
                `FR5_STW: alu_op = `ALU_STW;
                default:  alu_op = `ALU_LDW;
            endcase
        end
        default: alu_op=`ALU_ADD;
    endcase
end

always @(*) begin
    case (din[15:13])
        3'b010 : begin
            if (!din[9]) rf_we = 1'b1;
            else         rf_we = 1'b0;
        end
        3'b101: begin
                if (din[12])    rf_we = 1'b0;
                else            rf_we = 1'b1;
        end
        3'b110:          rf_we = 1'b0;
         
        default: rf_we = 1'b1;
    endcase
end

always @(*) begin
    case (din[15:13])
        3'b010:begin
            case (din[10:7]) 
                4'b0110: ram_we = `RAM_WE_N;
                default: ram_we = 4'hf;
            endcase
        end
        default: ram_we = 4'hf;
    endcase
end

// assign r2_sel = XXX ? `R2_RK : `R2_RD;
// assign wr_sel = XXX ? `WR_Rr1: `WR_RD;
assign r2_sel = (din[15:13] == 3'b110 || din[15:11] == 5'b10110 || din[15:11] == 5'b10111) ? `R2_RD : `R2_RK;     // ???rk??rd?????2
assign wr_sel = (din[15:11] == 5'b10101) ? `WR_Rr1 : `WR_RD;     // ???rd or r1????????

always @(*) begin
    case (din[15:13])
        3'b000 : wd_sel = `WD_ALU;
        3'b010 : wd_sel = `WD_RAM;
        3'b001 : wd_sel = `WD_ALU;
        default: wd_sel = `WD_ALU;
    endcase
end

always @(*) begin
    if (din[15:13] == 3'b001)
        rR1_re = 1'b0;
    else
        rR1_re = 1'b1;
end

always @(*) begin
    case (din[15:12])
        4'b0000: rR2_re=1'b1;
        default: rR2_re=1'b0;
    endcase
end

assign alua_sel = (din[15:11] == 5'b00111 || din[15:11] == 5'b10011 || din[15:11] == 5'b10101) ? `ALUA_PC : `ALUA_R1;     // ??????A?????PC ?? R1

// ??????B?????
always @(*) begin
    case (din[15:13])
        3'b000 : case (din[10:7])
                    4'b0000: alub_sel = `ALUB_R2;
                    default: alub_sel = `ALUB_EXT;
                endcase
        3'b001 : alub_sel = `ALUB_EXT;
        3'b010 : alub_sel = `ALUB_EXT;
        default: alub_sel = `ALUB_R2;
    endcase
end

endmodule
