# 基于Zynq异构平台的软硬件协同数字频谱分析仪

## 1. 项目简介
本作品面向无线通信系统中数字基带IQ信号的实时频谱分析需求，设计了一款基于Xilinx Zynq-7020异构平台（PYNQ-Z2）的软硬件协同频谱分析系统。
系统采用“软件定义无线电（SDR）”架构，PS端（ARM）使用Python动态生成高灵活度的IQ基带信号，通过AXI DMA注入PL端（FPGA）。PL端完成实时汉明窗、8192点FFT加速计算及硬件峰值检测，仅将峰值索引与幅值回传PS端解析与绘图。
**核心指标**：100MHz主频，端到端硬件处理延迟1.776 ms，10MHz输入信号检测结果为9.998 MHz（误差0.002 MHz)。

## 2. 开发环境
- **硬件平台**：PYNQ-Z2 (Xilinx Zynq-7020)
- **FPGA开发工具**：Vivado 2024.1 
- **软件运行环境**：PYNQ v2.7 (Jupyter Notebook)
- **Python依赖库**：numpy, matplotlib, pynq

## 3. 目录结构说明
- `README.md` : 项目简介与复现步骤（本文件）
- `src/` : 源代码（包含RTL源码 `.v` 和 Python/Jupyter控制脚本 `.ipynb`）
- `sim/` : RTL模块仿真文件（包含Testbench激励与波形截图）
- `build/` : 硬件工程文件（包含 `.bit`、`.hwh` 比特流文件，以及Vivado综合、时序报告截图）
- `board/` : 上板实测结果（包含Jupyter运行截图与开发板实物照片）
- `data/` : 测试数据与参考结果（包含Python黄金模型时域/频域仿真图）
- `skill/` : 技能包与踩坑记录（死锁排查等工程复盘）
- `report/` : 完整版PDF设计报告和包含大模型协作记录设计报告

## 4. 快速复现步骤（上板验证）

**Step 1：准备硬件与文件**
1. 将 PYNQ-Z2 开发板连接网线（与PC同网段）和电源并开机。
2. 将 `build/` 目录下的 `spectrum_window.bit` 和 `spectrum_window.hwh` 两个文件拷贝至开发板Jupyter根目录下（如 `/home/xilinx/jupyter_notebooks/`）。
3. 将 `src/` 目录下的 Python 运行脚本（如 `spectrum_test.ipynb`）拷贝至同一目录。

**Step 2：运行测试**
1. 在PC浏览器中输入开发板IP（如 `192.168.2.99`）进入 Jupyter Notebook 界面。
2. 打开拷贝好的 `.ipynb` 文件。
3. 按顺序运行代码块。
   - 代码将自动通过 `Overlay()` 加载 `.bit` 文件并获取 DMA 句柄。
   - 生成10MHz IQ信号并启动 DMA 传输。
   - 解析硬件回传的峰值索引与幅度，计算物理频率。

**Step 3：观察结果**
- Jupyter 界面将打印出：硬件计算的峰值频率 `9.998 MHz`，纯硬件处理耗时 `1.776 ms`。
- 界面将输出时频图，观察到10MHz处的尖峰。

## 5. 工程重新构建（可选）
如需从源码重新生成比特流：
1. 打开 Vivado，使用 `src/` 目录下的源码构建工程。
2. 配置 AXI DMA (Direct Register模式)、FFT (8192点, Pipelined Streaming I/O)、AXI4-Stream FIFO 等 IP 核。
3. 添加约束并综合、实现，导出包含 `.hwh` 文件的 `.bit` 比特流。