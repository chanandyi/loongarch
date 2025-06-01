`timescale 1ns / 1ps

`include "defines.vh"

module inst_cache(
    input  wire         cpu_clk,
    input  wire         cpu_rstn,       // low active
    // Interface to CPU
    input  wire         inst_rreq,      // 来自CPU的取指请�?
    input  wire [31:0]  inst_addr,      // 来自CPU的取指地�?
    output reg          inst_valid,     // 输出给CPU的指令有效信号（读指令命中）
    output reg  [31:0]  inst_out,       // 输出给CPU的指�?
    // Interface to Read Bus
    input  wire         dev_rrdy,       // 主存就绪信号（高电平表示主存可接收ICache的读请求�?
    output reg  [ 3:0]  cpu_ren,        // 输出给主存的读使能信�?
    output reg  [31:0]  cpu_raddr,      // 输出给主存的读地�?
    input  wire         dev_rvalid,     // 来自主存的数据有效信�?
    input  wire [`CACHE_BLK_SIZE-1:0] dev_rdata   // 来自主存的读数据
);

`ifdef ENABLE_ICACHE    /******** 不要修改此行代码 ********/

    // 主存地址分解
    wire [21:0] tag_from_cpu   = inst_addr[31:10]/* TODO */;     // 主存地址的TAG？？�?
    wire [5:0] cache_index     = inst_addr[9:4]/* TODO */;     // 主存地址的Cache索引 / ICache存储体的地址？？�?
    wire [1:0] offset          = inst_addr[3:2]/* TODO */;     // 32位字偏移量？�??

    wire [`CACHE_BLK_SIZE + 22:0] cache_line_r0;// 从ICache存储�?0读出的Cache块？？？
    wire [`CACHE_BLK_SIZE + 22:0] cache_line_r1;                   // 从ICache存储�?1读出的Cache块？？？
    wire       valid_bit0     = cache_line_r0[`CACHE_BLK_SIZE + 22]/* TODO */;     // Cache组内�?0块的有效�?
    wire       valid_bit1     = cache_line_r1[`CACHE_BLK_SIZE + 22]/* TODO */;     // Cache组内�?1块的有效�?
    wire [21:0] tag_from_set0  = cache_line_r0[`CACHE_BLK_SIZE + 21:`CACHE_BLK_SIZE]/* TODO */;     // Cache组内�?0块的TAG
    wire [21:0] tag_from_set1  = cache_line_r1[`CACHE_BLK_SIZE + 21:`CACHE_BLK_SIZE]/* TODO */;     // Cache组内�?1块的TAG

    // TODO: 定义ICache状�?�机的状态变�?
    localparam IDLE      = 2'b00;
    localparam TAG_CHECK = 2'b01;
    localparam REFILL    = 2'b10;
    reg [1:0] cur_state;
    reg [1:0] next_state;

    // �?保证命中时，hit信号仅有�?1个时钟周�?
    wire hit0 = (valid_bit0) && (tag_from_set0 == tag_from_cpu)/* TODO */ ;    // Cache组内�?0块的命中信号
    wire hit1 = (valid_bit1) && (tag_from_set1 == tag_from_cpu)/* TODO */;     // Cache组内�?1块的命中信号
    wire hit  = hit0 | hit1;

    wire [`CACHE_BLK_SIZE-1:0] hit_data_blk = {`CACHE_BLK_SIZE{hit0}} & cache_line_r0[`CACHE_BLK_SIZE-1:0] |
                                              {`CACHE_BLK_SIZE{hit1}} & cache_line_r1[`CACHE_BLK_SIZE-1:0]; //命中得到的数�?

    always @(*) begin
        inst_valid = hit;
        inst_out   = hit_data_blk[127 - offset * 32 -: 32]/* TODO: 根据字偏移，选择组内命中的Cache行中的某�?32位字作为输出??? */;
    end
    
    // 记录第i个Cache组内的Cache块的被访问情况（比如�?0被访问，则置use_bit[i]�?01，块1被访问则置use_bit[i]�?10），用于实现Cache块替�?
    reg  [1:0] use_bit [63:0];

    wire       cache_we0    = ((!hit) & (valid_bit0) & (use_bit[cache_index] == 2'b10)) | ((!hit) & (!valid_bit0))/* TODO */;       // ICache存储�?0的写使能信号
    wire       cache_we1    = ((!hit) & (valid_bit1) & (use_bit[cache_index] == 2'b01))/* TODO */;       // ICache存储�?1的写使能信号
    wire [150:0] cache_line_w = {1'b1,tag_from_cpu,dev_rdata}/* TODO */;       // 待写入ICache的Cache�?

    // ICache存储体：Block MEM IP�?
    blk_mem_gen_1 U_isram0 (        // ICache存储�?0，存储所有Cache组的�?0�?
        .clka   (cpu_clk),
        .wea    (cache_we0),
        .addra  (cache_index),
        .dina   (cache_line_w),
        .douta  (cache_line_r0)
    );

    blk_mem_gen_1 U_isram1 (        // ICache存储�?1，存储所有Cache组的�?1�?
        .clka   (cpu_clk),
        .wea    (cache_we1),
        .addra  (cache_index),
        .dina   (cache_line_w),
        .douta  (cache_line_r1)
    );

    // TODO: 编写状�?�机现�?�的更新逻辑
    always @(posedge cpu_clk or posedge cpu_rstn) begin
        cur_state <= cpu_rstn ? IDLE : next_state;
    end

    
    // TODO: 编写状�?�机的状态转移�?�辑
    always @(*) begin
        case (cur_state)
            IDLE:       next_state = inst_rreq ? TAG_CHECK : IDLE;
            TAG_CHECK:  next_state = hit ? IDLE : REFILL;
            REFILL:     next_state = dev_rvalid ? TAG_CHECK : REFILL;
            default:    next_state = IDLE;
        endcase
    end


    // TODO: 生成状�?�机的输出信号：use_bit的更新，以及访存请求（即cpu_raddr和cpu_ren）的生成
    always @(posedge cpu_clk or posedge cpu_rstn) begin
        if(!cpu_rstn) begin
            inst_valid <= 1'b0;
            cpu_ren <= 4'h0;
        end
        case(cur_state)
            IDLE: begin
                inst_valid <= 1'b0;
                cpu_ren    <= 4'h0;
                cpu_raddr  <= 32'h0;
            end
            TAG_CHECK: begin
                if(hit0) begin
                    use_bit[cache_index] <= 2'b01;
                    inst_valid <= dev_rvalid ? 1'b1 : 1'b0;
                end
                else if(hit1) begin
                    use_bit[cache_index] <= 2'b10;
                    inst_valid <= dev_rvalid ? 1'b1 : 1'b0;
                end
            end
            REFILL: begin
                cpu_ren    <= dev_rrdy ? 4'hF : 4'h0;
                cpu_raddr  <= dev_rrdy ? inst_addr : 32'h0;
            end    
        endcase
    end


  /******** 不要修改以下代码 ********/
`else

    localparam IDLE  = 2'b00;
    localparam STAT0 = 2'b01;
    localparam STAT1 = 2'b11;
    reg [1:0] state, nstat;

    always @(posedge cpu_clk or negedge cpu_rstn) begin
        state <= !cpu_rstn ? IDLE : nstat;
    end

    always @(*) begin
        case (state)
            IDLE:    nstat = inst_rreq ? (dev_rrdy ? STAT1 : STAT0) : IDLE;
            STAT0:   nstat = dev_rrdy ? STAT1 : STAT0;
            STAT1:   nstat = dev_rvalid ? IDLE : STAT1;
            default: nstat = IDLE;
        endcase
    end

    always @(posedge cpu_clk or negedge cpu_rstn) begin
        if (!cpu_rstn) begin
            inst_valid <= 1'b0;
            cpu_ren    <= 4'h0;
        end else begin
            case (state)
                IDLE: begin
                    inst_valid <= 1'b0;
                    cpu_ren    <= (inst_rreq & dev_rrdy) ? 4'hF : 4'h0;
                    cpu_raddr  <= inst_rreq ? inst_addr : 32'h0;
                end
                STAT0: begin
                    cpu_ren    <= dev_rrdy ? 4'hF : 4'h0;
                end
                STAT1: begin
                    cpu_ren    <= 4'h0;
                    inst_valid <= dev_rvalid ? 1'b1 : 1'b0;
                    inst_out   <= dev_rvalid ? dev_rdata[31:0] : 32'h0;
                end
                default: begin
                    inst_valid <= 1'b0;
                    cpu_ren    <= 4'h0;
                end
            endcase
        end
    end

`endif

endmodule