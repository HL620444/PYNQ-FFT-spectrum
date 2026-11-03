`timescale 1ns / 1ps

module hamming_windon (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [31:0] s_axis_tdata,   // 高16位Q，低16位I
    input  wire        s_axis_tvalid,
    input  wire        s_axis_tlast,
    output wire        s_axis_tready,
    output reg  [31:0] m_axis_tdata,
    output reg         m_axis_tvalid,
    output reg         m_axis_tlast,
    input  wire        m_axis_tready
);

    reg [12:0] cnt;
    wire signed [15:0] i_val = s_axis_tdata[15:0];
    wire signed [15:0] q_val = s_axis_tdata[31:16];

    // ================= 1. 系数计算流水线 (抛物线近似) =================
    // 抛物线公式: w = 1 - ( (cnt - 4096) / 4096 )^2
    // 定点化: 令 y = (cnt - 4096)，w_coef = 32768 - (y*y) >> 14
    wire signed [31:0] y = cnt - 13'd4096;
    wire signed [31:0] y_sq = y * y; 
    
    reg signed [15:0] win_coef_d1;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            win_coef_d1 <= 0;
        end else if (m_axis_tready) begin
            // 🚨 修复：右移 14 位，而不是 7 位。 32768 - (4096*4096 >> 14) = 32768 - 1024 = 31744，绝对不会溢出
            win_coef_d1 <= 32768 - (y_sq >>> 14); 
        end
    end

    // ================= 2. 数据与握手信号的延迟流水线 (打1拍) =================
    reg signed [15:0] i_d1, q_d1;
    reg v_d1, l_d1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            i_d1 <= 0; q_d1 <= 0; v_d1 <= 0; l_d1 <= 0;
        end else if (m_axis_tready) begin
            i_d1 <= i_val; q_d1 <= q_val;
            v_d1 <= s_axis_tvalid; l_d1 <= s_axis_tlast;
        end
    end

    // ================= 3. 乘法与输出流水线 (打1拍) =================
    reg signed [31:0] mult_i_d2, mult_q_d2;
    reg m_valid_d2, m_last_d2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mult_i_d2 <= 0; mult_q_d2 <= 0;
            m_valid_d2 <= 0; m_last_d2 <= 0;
        end else if (m_axis_tready) begin
            mult_i_d2 <= i_d1 * win_coef_d1;
            mult_q_d2 <= q_d1 * win_coef_d1;
            m_valid_d2 <= v_d1;
            m_last_d2 <= l_d1;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            m_axis_tdata <= 0; m_axis_tvalid <= 0; m_axis_tlast <= 0;
        end else if (m_axis_tready) begin
            m_axis_tdata <= {mult_q_d2[30:15], mult_i_d2[30:15]};
            m_axis_tvalid <= m_valid_d2;
            m_axis_tlast <= m_last_d2;
        end
    end

    // ================= 4. 计数器控制 =================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) cnt <= 13'd0;
        else if (s_axis_tvalid && m_axis_tready) begin
            if (cnt == 13'd8191) cnt <= 13'd0;
            else cnt <= cnt + 1'b1;
        end
    end

    assign s_axis_tready = m_axis_tready;

endmodule