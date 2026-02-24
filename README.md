# AI 加速器 Verilog 專案（2x2 Matrix Multiply Accelerator）

這個專案是 AI 加速器原型，核心放在神經網路最常見的運算路徑：

- **MAC（Multiply-Accumulate）**
- **GEMM / Matrix Multiply**
- **Post-process（Bias + ReLU）**

目前實作的是一個可合成、可擴展的 2x2 矩陣乘法引擎，並提供自檢 testbench。

## 專案結構

- `src/mac.v`：signed MAC 單元
- `src/matmul_accel.v`：矩陣乘法加速器（含 `start/busy/done`、bias、ReLU、cycle counter）
- `tb/matmul_accel_tb.v`：多案例自檢 testbench（baseline / ReLU / bias）
- `Makefile`：模擬與清理目標

## 主要功能（matmul_accel）

### 1) 2x2 int8 x int8 矩陣乘法
- 輸入 `a_mat`, `b_mat`：4 個 int8，row-major 打包
- 輸出 `c_mat`：4 個 int32，row-major 打包

### 2) Bias 加法（可參數化開關）
- 輸入 `bias_mat`：4 個 int32
- 參數 `ADD_BIAS=1` 時，輸出前加上 bias

### 3) ReLU 啟用（可參數化開關）
- 參數 `USE_RELU=1` 時，負值輸出會被夾到 0

### 4) 飽和模式（可參數化開關）
- 參數 `SATURATE=1` 時，bias 加法可選擇飽和裁切

### 5) 運行觀測
- `busy`：運算中
- `done`：完成脈衝
- `cycle_count`：本次運算耗時 cycles

## 介面摘要

- input: `clk`, `rst_n`, `start`
- input: `a_mat[31:0]`, `b_mat[31:0]`, `bias_mat[127:0]`
- output: `busy`, `done`, `cycle_count[15:0]`, `c_mat[127:0]`

## 執行

```bash
make test
```

## 測試案例

`tb/matmul_accel_tb.v` 目前包含：
- Case 1: baseline matmul
- Case 2: negative output + ReLU
- Case 3: bias add correctness

## 下一步建議

1. 改成參數化 NxN（目前 DIM 固定測在 2）
2. 加上 valid/ready streaming I/O
3. 外掛 SRAM tile buffer
4. 擴展成 systolic array（PE grid）
5. 加入 quantization（int4/int8）與 scale/zero-point
