`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/10/06 10:06:54
// Design Name: 
// Module Name: tb_hamming_windon
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
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

module tb_hamming_windon;

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

    // 实例化你的加窗模块
    hamming_windon u_hamming (
        .clk(clk),
        .rst_n(rst_n),
        .s_axis_tdata(s_axis_tdata),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tlast(s_axis_tlast),
        .s_axis_tready(s_axis_tready),
        .m_axis_tdata(m_axis_tdata),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tlast(m_axis_tlast),
        .m_axis_tready(m_axis_tready)
    );

    // 100MHz 时钟 (周期 10ns)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    integer i;
    initial begin
        // 初始化
        rst_n = 0;
        s_axis_tdata = 32'h0000_1000; // 固定输入数据 (I=4096, Q=0)
        s_axis_tvalid = 0;
        s_axis_tlast = 0;
        m_axis_tready = 1; // 下游(FFT)永远准备好接收
        
        #100;
        rst_n = 1;
        #20;

        // 连续输入 8192 个数据
        for (i = 0; i < 8192; i = i + 1) begin
            @(posedge clk);
            s_axis_tvalid = 1;
            s_axis_tdata = 32'h0000_1000; 
        end

        // 第 8192 个数据时拉高 TLAST
        @(posedge clk);
        s_axis_tlast = 1;
        @(posedge clk);
        s_axis_tvalid = 0;
        s_axis_tlast = 0;
        #200;
        
        $display("========== 加窗模块仿真结束 ==========");
        $finish;
    end

endmodule
