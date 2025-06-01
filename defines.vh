//`define ENABLE_ICACHE
// `define ENABLE_DCACHE

 `define CACHE_BLK_LEN  4
 `define CACHE_BLK_SIZE (`CACHE_BLK_LEN*32)

// PC复位初始�???
`define PC_INIT_VAL     32'h1C000000

// NPC op
`define NPC_PC4     2'b00
`define NPC_PC_OFFS_DIR  2'b01
`define NPC_RD1_OFFS_DIR 2'b10
`define NPC_PC_OFFS_CON  2'b11

// 立即数扩展op
`define EXT_20   3'b110
`define EXT_12_ZEXT   3'b001
`define EXT_12_SEXT   3'b010
`define EXT_NONE 3'b000

// ѡ���ַƫ������չ��ʽ
`define OFFS_16_SEXT    1'b0
`define OFFS_26_SEXT    1'b1

// Load指令读数据后的扩展op
`define RAM_EXT_H  3'b001
`define RAM_EXT_N  3'b000

// Store指令写数据op
`define RAM_WE_N 4'b0000

// ALU op
`define ALU_ADD     5'b00000
`define ALU_SUB     5'b00001
`define ALU_AND     5'b00010
`define ALU_OR      5'b00011
`define ALU_XOR     5'b00100
`define ALU_NOR     5'b00101
`define ALU_SLL     5'b00110
`define ALU_SRL     5'b00111
`define ALU_SRA     5'b01000
`define ALU_SLT     5'b01001
`define ALU_SLTU    5'b01010

`define ALU_SLLI    5'b01011

`define ALU_ADDI    5'b01110
`define ALU_ANDI    5'b01111
`define ALU_BEQ     5'b11100
`define ALU_BGE     5'b11101
`define ALU_JIRL    5'b11110
`define ALU_BL      5'b11111

`define ALU_LDW     5'b10000
`define ALU_STW     5'b10001
// 指令译码相关
`define FR5_ADD   5'b00000
`define FR5_SUB    5'b00010
`define FR5_AND   5'b01001
`define FR5_OR      5'b01010
`define FR5_XOR    5'b01011
`define FR5_NOR    5'b01000
`define FR5_SLL      5'b01110
`define FR5_SRL      5'b01111
`define FR5_SRA     5'b10000
`define FR5_SLT      5'b00100
`define FR5_SLTU    5'b00101
`define FR5_SLLI    5'b00001
`define FR5_ADDI    3'b010
`define FR5_ANDI    3'b101
`define FR5_BEQ     2'b10
`define FR5_BGE     2'b01
`define FR5_BL      2'b01
`define FR5_JIRL    2'b11
`define FR5_LDW     4'b0010
`define FR5_STW     4'b0110
// 源操作数2的�?�择：�?�择rk或rd
`define R2_RK  1'b1
`define R2_RD  1'b0

// 目的操作数的选择：�?�择择rd或r1
`define WR_RD  1'b1
`define WR_Rr1  1'b0

// 写数据�?�择择：选择择将ALU数据或将读主存的数据写回寄存器堆
`define WD_ALU  2'b11
`define WD_RAM  2'b01
`define WD_PC4  2'b10

// ALU操作数A的�?�择：�?�择源寄存器1或PC??
`define ALUA_R1  1'b1
`define ALUA_PC  1'b0

// ALU操作数B的�?�择：�?�择源寄存器2或立即数
`define ALUB_R2  1'b1
`define ALUB_EXT 1'b0
