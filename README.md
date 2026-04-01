# AI 加速器 Verilog 專案（含 5-stage CPU 範例）

這個專案目前包含兩個方向：

- AI 加速器練習（原始目標）
- **5-stage pipeline CPU 教學範例（新增）**

> 目前 repo 內的 AI accelerator 檔案結構仍在整理中；本次新增重點是可跑的 5-stage CPU。

## 新增：5-stage CPU

新增檔案：

- `cpu5.v`：簡化版 5-stage CPU（IF / ID / EX / MEM / WB）
- `cpu5_tb.v`：testbench，驗證基本運算、load/store、branch

### CPU 支援指令（簡化 MIPS-like）

- R-type: `add`, `sub`, `and`, `or`, `xor`
- I-type: `addi`, `lw`, `sw`, `beq`
- J-type: `j`
- `nop`（`32'h00000000`）

### 目前實作特性

- 5 階段管線：IF, ID, EX, MEM, WB
- 內建 instruction/data memory（`imem`, `dmem`）
- 基本 branch/jump 控制流程
- 無 forwarding / hazard detection（測試程式用 `nop` 避免資料冒險）

## 執行 CPU 測試

```bash
make test-cpu
```

預期輸出會包含：

- `PASS: 5-stage CPU basic flow works.`

## 原本 AI accelerator 測試

```bash
make test
```

> 注意：如果 `src/mac.v` / `src/matmul_accel.v` / `tb/matmul_accel_tb.v` 尚未存在，`make test` 會失敗。
