`timescale 1ns / 1ps

module peak_detect (
    input  wire        clk,
    input  wire        rst_n,
    // 来自 FFT 的输入
    input  wire [31:0] s_axis_tdata,
    input  wire        s_axis_tvalid,
    input  wire        s_axis_tlast,
    output wire        s_axis_tready,
    // 输出给 DMA
    output reg  [31:0] m_axis_tdata,
    output reg         m_axis_tvalid,
    output reg         m_axis_tlast,
    input  wire        m_axis_tready
);

    reg [12:0] cnt;          
    reg [31:0] max_value;    
    reg [12:0] max_index;    
    reg [1:0]  state;        

    assign s_axis_tready = (state == 2'd0);

    // 声明两个有符号的乘法器结果，强制使用 DSP 按补码计算
    wire signed [15:0] i_s = s_axis_tdata[15:0];
    wire signed [15:0] q_s = s_axis_tdata[31:16];
    wire signed [31:0] i_sq = i_s * i_s;  // 强制有符号乘法
    wire signed [31:0] q_sq = q_s * q_s;  // 强制有符号乘法
    wire [31:0] mag_sq = i_sq + q_sq;      // 两个正数相加，结果必为正

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt <= 13'd0; max_value <= 32'd0; max_index <= 13'd0; state <= 2'd0;
            m_axis_tdata <= 32'd0; m_axis_tvalid <= 1'b0; m_axis_tlast <= 1'b0;
        end else begin
            case (state)
                2'd0: begin // 接收数据
                    if (s_axis_tvalid) begin
                        if (mag_sq > max_value) begin
                            max_value <= mag_sq;
                            max_index <= cnt;
                        end
                        cnt <= cnt + 1'b1;
                        
                        if (s_axis_tlast) begin
                            state <= 2'd1;
                            cnt <= 13'd0;
                        end
                    end
                end
                2'd1: begin // 发送峰值索引
                    if (m_axis_tready) begin
                        m_axis_tdata <= {19'd0, max_index};
                        m_axis_tvalid <= 1'b1;
                        m_axis_tlast <= 1'b0;
                        state <= 2'd2;
                    end
                end
                2'd2: begin // 发送峰值幅值
                    if (m_axis_tready) begin
                        m_axis_tdata <= max_value;
                        m_axis_tvalid <= 1'b1;
                        m_axis_tlast <= 1'b1;
                        state <= 2'd3;
                    end
                end
                2'd3: begin // 结束
                    m_axis_tvalid <= 1'b0;
                    m_axis_tlast <= 1'b0;
                    state <= 2'd0;
                    max_value <= 32'd0;
                    max_index <= 13'd0;
                end
            endcase
        end
    end

endmodule