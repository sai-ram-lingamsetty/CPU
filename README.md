# 8-bit CPU RTL (Verilog)

A small CPU implemented in Verilog for learning and simulation. The design uses a 16-bit instruction word, an 8-bit program counter and datapath, eight 8-bit general-purpose registers, and byte-addressed data memory.

## Features

* 8-bit program counter with active-low asynchronous reset.
* 16-bit instruction memory with 256 entries.
* Eight 8-bit registers with two combinational read ports and one clocked write port.
* 256-byte data memory, with combinational reads and clocked writes.
* ALU operations used by the instruction set: addition, subtraction, bitwise AND, and bitwise OR.
* Immediate arithmetic, conditional branch, jump, load, store, and NOP instructions.
* Testbench with directed scenarios and randomized differential checking against a reference model.

> **Design notes:**
> * Register `r0` is writable; it is not hard-wired to zero.
> * The ALU also contains left- and right-shift cases, but the current control unit does not expose them as CPU instructions.
> * Reset clears the PC and register file. Data memory is initialized to zero at simulation startup, not cleared by `rst_n`.
> * Data-memory writes are blocked while `rst_n` is low, so a `STORE` at address 0 cannot modify memory during reset.
> * Opcodes `0x9`–`0xE` are undefined and behave like `NOP` (all control signals are deasserted).

## Repository layout

```text
cpu/
├── README.md
├── .gitignore
├── RTL/
│   ├── alu.v
│   ├── alu_mux.v
│   ├── control_unit.v
│   ├── cpu.v
│   ├── data_memory.v
│   ├── instruction_decoder.v
│   ├── instruction_memory.v
│   ├── pc_incrementer.v
│   ├── pc_mux.v
│   ├── pc_reg.v
│   ├── register_file.v
│   └── write_back_mux.v
└── tb_cpu.v
```

## Module overview

| Module | Purpose |
|-|-|
| `cpu` | Top-level datapath and control wiring |
| `control_unit` | Decodes the opcode into control signals |
| `instruction_decoder` | Splits the instruction into opcode, registers, and immediate/offset fields |
| `alu` | Performs arithmetic and logical operations |
| `alu_mux` | Selects a register operand or immediate for the ALU |
| `register_file` | Eight 8-bit general-purpose registers |
| `instruction_memory` | Stores 256 16-bit instructions |
| `data_memory` | Stores 256 bytes of data |
| `pc_reg` | Program counter register |
| `pc_incrementer` | Computes `PC + 1` |
| `pc_mux` | Selects sequential, branch, or jump PC |
| `write_back_mux` | Selects ALU output or loaded data for register write-back |
| `tb_cpu_full` (in `tb_cpu.v`) | Testbench: directed tests and randomized reference-model checking |

## Instruction set

The opcode is `instruction[15:12]`.

| Opcode | Mnemonic | Operation |
|-:|-|-|
| `0x0` | `ADD` | `rd = rs1 + rs2` |
| `0x1` | `SUB` | `rd = rs1 - rs2` |
| `0x2` | `AND` | `rd = rs1 & rs2` |
| `0x3` | `OR` | `rd = rs1 \| rs2` |
| `0x4` | `ADDI` | `rd = rs1 + sign_extend(imm6)` |
| `0x5` | `BEQ` | If `rs1 == rs2`, branch to `PC + 1 + sign_extend(offset3)` |
| `0x6` | `JUMP` | Set `PC` to the sign-extended 6-bit target field |
| `0x7` | `LOAD` | `rd = MEM[rs1 + sign_extend(imm6)]` |
| `0x8` | `STORE` | `MEM[rs1 + sign_extend(imm6)] = rd` |
| `0xF` | `NOP` | No architectural state change other than normal PC advance |

Values are 8-bit, so arithmetic results and effective addresses wrap modulo 256. Branch offsets are signed 3-bit values. Immediate values are signed 6-bit values. The jump target is also sign-extended from 6 bits (for example, `-1` selects PC 255 and `-32` selects PC 224).

### Instruction formats

* **R-type** (`ADD`, `SUB`, `AND`, `OR`): `{opcode[3:0], rd[2:0], rs1[2:0], rs2[2:0], unused[2:0]}`
* **I-type** (`ADDI`, `LOAD`): `{opcode[3:0], rd[2:0], rs1[2:0], imm[5:0]}`
* **S-type** (`STORE`): `{opcode[3:0], data_reg[2:0], rs1[2:0], imm[5:0]}`. The data register is encoded in bits `[11:9]`.
* **B-type** (`BEQ`): `{opcode[3:0], unused[2:0], rs1[2:0], rs2[2:0], offset[2:0]}`
* **J-type** (`JUMP`): `{opcode[3:0], unused[5:0], target[5:0]}`

## Simulation

The testbench module is named `tb_cpu_full` (file `tb_cpu.v`). It exercises arithmetic edge cases, load/store, branches, jumps, NOP/undefined opcodes, reset behavior, example programs, and randomized programs (50 seeds x 2000 cycles) checked against a reference model. It prints a pass/fail summary and writes a waveform file named `cpu_full.vcd`.

### Before running

`RTL/instruction_memory.v` loads `program.mem` through the `INIT_FILE` parameter (default `"program.mem"`, relative to the simulator's working directory). Either place your own `program.mem` there, or override `INIT_FILE` with a full path. If you are running only `tb_cpu.v`, a missing `program.mem` is harmless: the testbench initializes the instruction memory itself. No `program.mem` file is included in this repository, and `.gitignore` excludes it by default.

### Run with Vivado Simulator

1. Create or open a Vivado project and add all Verilog files under `RTL/` as design sources.
2. Add `tb_cpu.v` as a simulation source.
3. Set `tb_cpu_full` as the simulation top.
4. If you want to run your own program, add `program.mem` to the simulation directory (or set `INIT_FILE`).
5. Run Behavioral Simulation and inspect the console summary and waveforms.

## Current scope and possible next steps

This is a compact educational RTL project, not a pipelined or production-ready processor. Useful follow-up improvements include adding a committed example `program.mem`, defining the ISA in a separate document, adding assertions, and checking synthesis/lint results.
