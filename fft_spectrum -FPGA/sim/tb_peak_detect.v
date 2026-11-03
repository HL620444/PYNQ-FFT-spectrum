`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/10/06 10:16:23
// Design Name: 
// Module Name: tb_peak_detect
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////
`timescale 1ns / 1ps

module tb_peak_detect;

    reg clk;
    reg rst_n;
    reg [31:0] s_axis_tdata;
    reg s_axis_tvalid;
    reg s_axis_tlast;
    wire s_axis_tready;
    wire [31:0] m_axis_tdata;
    wire m_axis_tvalid;
    wire m_axis_tlast;
    reg m_axis_tready;

    peak_detect u_peak (
        .clk(clk), .rst_n(rst_n),
        .s_axis_tdata(s_axis_tdata), .s_axis_tvalid(s_axis_tvalid), .s_axis_tlast(s_axis_tlast),
        .s_axis_tready(s_axis_tready),
        .m_axis_tdata(m_axis_tdata), .m_axis_tvalid(m_axis_tvalid), .m_axis_tlast(m_axis_tlast),
        .m_axis_tready(m_axis_tready)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    integer i;
    initial begin
        rst_n = 0;
        s_axis_tdata = 32'd0;
        s_axis_tvalid = 0;
        s_axis_tlast = 0;
        m_axis_tready = 1; // 下游永远准备好
        
        #100;
        rst_n = 1;
        #20;

        // 连续输入 8192 个数据
        for (i = 0; i < 8192; i = i + 1) begin
            @(posedge clk);
            s_axis_tvalid = 1;
            s_axis_tlast = (i == 8191) ? 1 : 0; // ⚠️ 关键修复：在第 8192 个点时拉高 TLAST
            
            if (i == 819) begin
                s_axis_tdata = 32'd999999; // 在第 819 个点制造峰值
            end else begin
                s_axis_tdata = 32'd100 + i;
            end
        end

        // 结束
        @(posedge clk);
        s_axis_tvalid = 0;
        s_axis_tlast = 0;
        #500;
        
        $display("========== 峰值检测模块仿真结束 ==========");
        $finish;
    end

endmodule