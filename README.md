# AI 加速器 Verilog 專案（2x2 Matrix Multiply Accelerator）

這個專案是一個 **AI 加速器入門骨架**，主題是神經網路中最核心的運算：

- **MAC（Multiply-Accumulate）**
- **矩陣乘法（GEMM 的最小版本）**

目前提供一個可合成的 2x2 矩陣乘法加速器，未來可擴展為更大的 systolic array / NPU。

## 專案結構

- `src/mac.v`：可重用的 signed MAC 單元
- `src/matmul_accel.v`：2x2 矩陣乘法加速器（時序版，`start/busy/done`）
- `tb/matmul_accel_tb.v`：自檢式 testbench
- `Makefile`：`make test` / `make clean`

## 模組功能

### `matmul_accel`

輸入：
- `clk`, `rst_n`
- `start`：拉高一拍啟動運算
- `a_mat`：4 個 int8，row-major 打包（`[31:0]`）
- `b_mat`：4 個 int8，row-major 打包（`[31:0]`）

輸出：
- `busy`：運算中
- `done`：完成脈衝（1 cycle）
- `c_mat`：4 個 int32，row-major 打包（`[127:0]`）

計算內容：

\[
C = A \times B
\]

其中 `A`,`B`,`C` 都是 2x2 矩陣。

## 執行測試

```bash
make test
```

> 若本機沒有 `iverilog`，請先安裝 Icarus Verilog。

## 下一步擴展方向

1. 將 2x2 推廣成參數化 NxN
2. 改成串流介面（valid/ready）
3. 加上 on-chip SRAM buffer（A/B/C tile）
4. 做成 systolic array + weight stationary / output stationary 資料流
5. 增加量化支援（int8 / int4）與飽和邏輯
