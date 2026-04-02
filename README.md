# AI Accelerator + Digital Design Playground

你可以把這個 repo 當成「AI 加速器 + CPU/數位系統」練習場。

## 目前內容

1. **基礎 ALU 範例**
   - `alu.v`

2. **小型 5-stage CPU（教學版）**
   - `cpu5.v`
   - `cpu5_tb.v`

3. **較大型 5-stage CPU 系統**
   - `rtl/cpu5_system.v`
   - `rtl/control_unit.v`
   - `rtl/alu32.v`
   - `rtl/regfile32.v`
   - `rtl/forward_unit.v`
   - `rtl/hazard_unit.v`
   - `tb/cpu5_system_tb.v`

4. **APB 外設子系統（新增）**
   - `rtl/apb_periph_subsys.v`
   - `rtl/apb_uart.v`
   - `rtl/apb_spi.v`
   - `rtl/apb_i2c.v`
   - `tb/apb_periph_subsys_tb.v`

---

## APB 外設子系統說明

這一塊讓你可以把「外部 APB 匯流排訊號」接到三個常見週邊：

- UART
- SPI
- I2C

### APB 介面

- `PCLK`, `PRESETn`
- `PSEL`, `PENABLE`, `PWRITE`
- `PADDR[31:0]`, `PWDATA[31:0]`
- `PRDATA[31:0]`, `PREADY`, `PSLVERR`

### 位址映射（`PADDR[15:12]`）

- `0x0`: UART
- `0x1`: SPI
- `0x2`: I2C
- 其他：回報 `PSLVERR=1`

### 每個 peripheral 的用途（示範版）

- UART: TX data / status / baud divisor 暫存器
- SPI: TX/RX data / mode / clock divisor 暫存器
- I2C: addr+data command / status / SCL divisor 暫存器

> 目前是 **可驗證的示範模型**，不是完整時序精準的協定實作（例如 SPI shift engine、I2C start/stop 波形、UART oversampling）。

---

## 如何測試

### APB 子系統（推薦）

```bash
make test-apb
```

預期 testbench 會印出：

- `PASS: APB subsystem connects UART/SPI/I2C.`

### 較大型 CPU 系統

```bash
make test-cpu-large
```

### 小型 CPU 教學版

```bash
make test-cpu
```

### 原本 accelerator 測試

```bash
make test
```

> 如果環境沒有 `iverilog`，上述測試會無法執行。
