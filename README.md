# AI Accelerator + Digital Design Playground

你可以把這個 repo 當成「AI 加速器 + CPU/數位系統」練習場。

## 目前內容

1. **基礎 ALU 範例**
   - `alu.v`

2. **小型 5-stage CPU（教學版）**
   - `cpu5.v`
   - `cpu5_tb.v`

3. **較大型 5-stage CPU 系統（新增）**
   - `rtl/cpu5_system.v`
   - `rtl/control_unit.v`
   - `rtl/alu32.v`
   - `rtl/regfile32.v`
   - `rtl/forward_unit.v`
   - `rtl/hazard_unit.v`
   - `tb/cpu5_system_tb.v`

---

## 較大型 CPU 系統特色

這版相對前一版更接近可擴展的專案架構：

- 模組化拆分（control / ALU / regfile / hazard / forwarding / top）
- 5-stage pipeline（IF/ID/EX/MEM/WB）
- 支援 forwarding（EX/MEM 與 MEM/WB）
- 支援 load-use hazard stall（自動插入 bubble）
- 支援 branch (`beq`, `bne`) 與 `j`
- 支援指令：
  - R-type: `add/sub/and/or/xor/slt`
  - I-type: `addi/andi/ori/lw/sw/beq/bne`
  - J-type: `j`

> 目前仍是教學型 CPU：內建 `imem/dmem`，沒有 cache、例外中斷、MMU。

---

## 如何測試

### 較大型 CPU 系統（推薦）

```bash
make test-cpu-large
```

預期 testbench 會印出：

- `PASS: larger 5-stage CPU system works with forwarding + load-use stall.`

### 小型 CPU 教學版

```bash
make test-cpu
```

### 原本 accelerator 測試

```bash
make test
```

> 如果環境沒有 `iverilog`，上述測試會無法執行。
