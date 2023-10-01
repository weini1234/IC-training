`timescale 1ns / 1ps
module acc_bias_relu(
    input i_add4_end,               // 输入，用于指示计算结束
    input clk,                     // 输入，时钟信号
    input rst_n,                   // 输入，复位信号
    input layer1,                  // 输入，用于选择层次1
    output o_acc_end,              // 输出，用于指示累积结束

    input [15:0] i_acc_bias_fm_col, // 输入，积累偏置特征图的列数
    input i_add4_valid,            // 输入，用于指示add4有效性
    input signed [22*32-1:0] i_add4_data, // 输入，add4数据
    input signed [22*32-1:0] i_bias,     // 输入，偏置数据
    input [15:0] i_bias_addr_base,        // 输入，偏置地址基准

    output [15:0] o_sel_bias_addr,        // 输出，选定的偏置地址
    output [8*32-1:0] o_acc_data_out,    // 输出，累积数据输出
    output o_acc_data_out_valid            // 输出，累积数据有效性
    );

reg signed [23*32-1:0] add4_bias_buf;      // 寄存器，用于存储加上偏置后的add4数据
reg [8*32-1:0] data_out_buf;                // 寄存器，用于存储输出数据
reg [15:0] sel_bias_addr_buf;               // 寄存器，用于存储偏置地址
reg add4_valid_ff1;                        // 寄存器，用于存储延迟版本的i_add4_valid
reg add4_valid_ff2;                        // 寄存器，用于存储延迟版本的add4_valid_ff1
reg acc_end_ff1;                           // 寄存器，用于存储延迟版本的i_add4_end
reg acc_end_ff2;                           // 寄存器，用于存储延迟版本的acc_end_ff1
integer i;                                 // 循环变量
integer j;                                 // 循环变量

// 时序逻辑块
always @(posedge clk) begin
    if (!rst_n) begin
        // 复位值
        add4_bias_buf <= 0;
        data_out_buf <= 0;
        add4_valid_ff1 <= 0;
        add4_valid_ff2 <= 0;
        sel_bias_addr_buf = i_bias_addr_base;
        acc_end_ff1 <= 0;
        acc_end_ff2 <= 0;
    end else begin
        // 在第一个时钟周期中将偏置添加到add4数据
        if (i_add4_valid == 1) begin
            for (i = 0; i < 32; i = i + 1) begin
                add4_bias_buf[23 * i +: 23] <= i_bias[22 * i +: 22] + i_add4_data[22 * i +: 22];
            end
            add4_valid_ff1 <= 1;
        end else begin
            add4_valid_ff1 <= 0;
        end

        // 在第二个时钟周期中应用ReLU
        if (add4_valid_ff1) begin
            for (j = 0; j < 32; j = j + 1) begin
                data_out_buf[8 * j +: 8] <= (add4_bias_buf[23 * j +: 23] < 0) ? 0 : (add4_bias_buf[23 * j + 7 +: 8] >= 127) ? 8'b01111111 : (add4_bias_buf[23 * i + 6] ? (add4_bias_buf[23 * j + 7 +: 8] + 1) : add4_bias_buf[23 * j + 7 +: 8]);
            end
            add4_valid_ff2 <= add4_valid_ff1;
        end else begin
            add4_valid_ff2 <= 0;
        end

        // 当i_add4_end信号为真时，更新偏置地址并指示累积结束
        if (i_add4_end) begin
            sel_bias_addr_buf <= sel_bias_addr_buf + 32;
            acc_end_ff1 <= 1;
        end else begin
            acc_end_ff1 <= 0;
        end
        acc_end_ff2 <= acc_end_ff1;
    end
end

wire [8 * 32 - 1:0] fifo_out;           // FIFO数据的输出线

reg [15:0] wr_cnt;                     // FIFO的写入计数器
reg [15:0] rd_cnt;                     // FIFO的读取计数器
reg rd_en;                              // FIFO的读取使能信号
reg out_valid;                          // 输出数据的有效性信号

wire full;                             // FIFO满标志
wire empty;                            // FIFO空标志

// 时序逻辑块，用于FIFO控制
always @(posedge clk) begin
    if (!rst_n) begin
        wr_cnt <= 0;
        rd_cnt <= 0;
        rd_en <= 0;
        out_valid <= 0;
    end else begin
        // 当add4_valid_ff2为真时，增加写入计数器
        if (add4_valid_ff2) begin
            wr_cnt <= wr_cnt + 1;
        end
        if (wr_cnt >= 1) begin
            rd_en <= 1;
            rd_cnt <= rd_cnt + 1;
        end
        if (rd_cnt == i_acc_bias_fm_col) begin
            rd_en <= 0;
            wr_cnt <= 0;
            rd_cnt <= 0;
        end
        out_valid <= rd_en;
    end
end

// 实例化FIFO模块
acc_syn_fifo acc_syn_fifo_ins (
    .clk(clk),
    .din(data_out_buf),
    .wr_en(add4_valid_ff2),
    .rd_en(rd_en),
    .dout(fifo_out),
    .full(full),
    .empty(empty)
);

assign o_acc_data_out = layer1 == 1 ? fifo_out : fifo_out[8 * 16 - 1:0]; // 选择输出数据
assign o_acc_data_out_valid = out_valid; // 输出数据的有效性信号
assign o_sel_bias_addr = sel_bias_addr_buf; // 选定的偏置地址
assign o_acc_end = acc_end_ff2; // 输出结束信号
endmodule