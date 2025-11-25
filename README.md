# AXI4-Lite Timer / PWM Peripheral (SystemVerilog, Artix-7)

This repository contains a simple, synthesizable **AXI4-Lite Timer/PWM peripheral** written in SystemVerilog and verified in simulation.  
The design targets a Xilinx Artix-7 device (e.g. Nexys 4 DDR, XC7A100T-CSG324) but is generic enough to be reused in other AXI-based SoCs.

---

## Features

- **AXI4-Lite slave interface** (32-bit data, single-beat transfers)
- **Memory-mapped register bank**  
  - `CONTROL` – enable + mode (timer / PWM)  
  - `STATUS` – timer_done + overflow  
  - `PERIOD` – programmable period  
  - `DUTY_CYCLE` – programmable PWM duty
- **Timer mode**
  - Counts from 0 up to `PERIOD`
  - Asserts `timer_done` when the period expires
- **PWM mode**
  - Generates a PWM signal using `PERIOD` and `DUTY_CYCLE`
  - `pwm_out` high while `count < DUTY_CYCLE`
- Fully **simulation-verified** with a SystemVerilog testbench and AXI read/write tasks

---

## Register Map

All registers are 32-bit, word-aligned, AXI4-Lite accessible.

| Address | Name         | R/W | Description                                      |
|--------:|-------------|:---:|--------------------------------------------------|
|  0x00   | CONTROL     | R/W | bit0: `enable`, bit1: `mode` (0=timer, 1=PWM)    |
|  0x04   | STATUS      | R/W | bit0: `timer_done`, bit1: `overflow`             |
|  0x08   | PERIOD      | R/W | Timer/PWM period value                           |
|  0x0C   | DUTY_CYCLE  | R/W | PWM duty value (valid when `mode=1`)            |

> Note: In the current implementation, software can overwrite `STATUS`. It is easy to change this to a W1C (write-one-to-clear) scheme if desired.

---

## Source Files

- **`axi_timer_pwm_top.sv`**  
  Top-level AXI4-Lite peripheral. Instantiates:
  - AXI-Lite slave wrapper (`axi_lite_simple_slave`)
  - Register bank (`timer_pwm_reg_bank`)
  - Timer/PWM core (`timer_pwm_core`)

- **`axi_lite_simple_slave.sv`**  
  Minimal AXI4-Lite slave:
  - Single outstanding transaction
  - Single-beat read/write
  - Exposes a simple internal register interface:
    - `wr_en`, `wr_addr`, `wr_data`
    - `rd_en`, `rd_addr`, `rd_data`

- **`timer_pwm_reg_bank.sv`**  
  Decodes AXI addresses into four 32-bit registers and connects them to the core:
  - CONTROL, STATUS, PERIOD, DUTY_CYCLE

- **`timer_pwm_core.sv`**  
  Shared counter implementing:
  - Timer mode (0): count to `period`, pulse `timer_done`
  - PWM mode (1): `pwm_out = (count < duty)` while enabled

- **`fpga_top.sv`** (optional example)  
  Example FPGA top-level that instantiates `timer_pwm_core` directly and drives a board LED with fixed `PERIOD` and `DUTY`.

- **`tb_axi_timer_pwm.sv`**  
  SystemVerilog testbench:
  - Generates 100 MHz clock and reset
  - Provides simple `axi_write` / `axi_read` tasks
  - Programs PERIOD, DUTY_CYCLE, CONTROL and observes `pwm_out` and `irq`

---

## Simulation (Vivado 2025.x)

This project was developed and tested using **Vivado 2025.x** with the SystemVerilog simulator.

### 1. Create Vivado project

1. Create a new RTL project in Vivado (no sources at first).
2. Add the following **design sources**:
   - `axi_timer_pwm_top.sv`
   - `axi_lite_simple_slave.sv`
   - `timer_pwm_reg_bank.sv`
   - `timer_pwm_core.sv`
   - `fpga_top.sv` (optional)
3. Add the following **simulation source**:
   - `tb_axi_timer_pwm.sv`

### 2. Set testbench top

1. In **Sources → Simulation Sources**, right-click `tb_axi_timer_pwm`  
2. Select **Set as Top**.

### 3. Run behavioral simulation

1. Flow Navigator → **Run Simulation → Run Behavioral Simulation**.
2. In the waveform, you should see:
   - AXI writes to:
     - `PERIOD` (0x08)
     - `DUTY_CYCLE` (0x0C)
     - `CONTROL` (0x00, setting enable + PWM mode)
   - `pwm_out` toggling with:
     - Period matching `PERIOD`
     - Duty high-time matching `DUTY_CYCLE`
   - `irq` pulsing when `count` reaches `period` (timer_done)

---

## Synthesis / FPGA Target

The RTL is fully synthesizable and was targeted at:

- **Device:** Xilinx Artix-7 XC7A100T-CSG324-1  
- **Board:** Digilent Nexys 4 DDR

An example top-level (`fpga_top.sv`) and XDC constraints can be used to map `pwm_out` to a user LED and run the PWM in hardware.  

---

## Possible Extensions

This project can be extended in multiple directions:

- Add **interrupt controller integration** for timer interrupts
- Convert STATUS to **write-one-to-clear (W1C)** semantics
- Add **SystemVerilog Assertions (SVA)** for AXI protocol and functional checks
- Add **functional coverage** for:
  - Timer vs PWM mode
  - Various PERIOD/DUTY ranges
- Package the core as a **custom AXI IP** and connect it to a MicroBlaze or other soft CPU

---

## Project Goals

This project was built to practice and demonstrate:

- RTL design in **SystemVerilog**
- AXI4-Lite protocol understanding
- Memory-mapped peripheral design
- Testbench creation with simple AXI master tasks
- Simulation-driven verification of a timer/PWM hardware block
