
# RISC-V RV32I Pipeline Processor

## Introduction

In this assignment, I implemented the RISC-V architecture for RV32I base instructions, encompassing four instruction types: **R-type, I-type, Load, and Store**. The RTL design was written in **SystemVerilog** and simulated using the **VCS simulator**. The processor includes:

- Fetch block  
- Decode block  
- Execute block  
- Memory block  
- Write-back block  

Each stage is registered to maintain synchronization. The architecture follows the standard RISC-V ISA and is implemented in a **5-stage pipeline** with **stall-based hazard handling**.

---

## Architecture

Architecture of the design is depicted in the block diagram below:

<br>

---

## Micro-Architecture

Micro-architecture of the design is shown below:

<br>

---

## Frontend

### RTL Module Hierarchy

The design hierarchy is:

<br>

Each module is described in the following sections.

---

## `definition_pkg.sv`

This package file defines system-wide constants used throughout the design:

```systemverilog
package definition_pkg;
  parameter IM_DEPTH = 64;
  parameter RF_DEPTH = 32;
  parameter SM_DEPTH = 32;
  parameter R_TYPE = 7'b0110011;
  parameter I_TYPE = 7'b0010011;
  parameter LOAD   = 7'b0000011;
  parameter STORE  = 7'b0100011;
  parameter STALL_CYCELS = 4; // stall cycles for data hazard handling
endpackage
```

---

## Top Module

This module instantiates all 5 pipeline blocks and implements:

- Data/control signal flow between stages  
- Register file (R File) memory  
- Package import (`definition_pkg`)  
- Interface for instruction injection from testbench  

---

## Fetch Module

Responsible for fetching the next instruction from memory. Includes:

- PC increment logic  
- Instruction memory access  
- Stall logic for data hazards  

<br>

---

## Decode Module

Performs instruction decoding, including:

- Opcode and operand decoding  
- R file register read  
- Generation of control signals  

<br>

---

## Execute Module

Implements the **ALU** and performs actual computation:

- Arithmetic and logical operations  
- Result forwarding to memory/write-back  
- Handles immediate values  

<br>

---

## Memory Module

Handles data memory operations:

- Calculates effective address  
- Performs load/store  
- Transfers data to write-back or receives data from execute  

<br>

---

## Write-back Module

Writes the final result back to the register file:

- Identifies destination register  
- Commits result from memory or ALU  

<br>

---

## Memory Blocks

The design includes three key memory blocks:

- **Instruction Memory** – populated from the testbench  
- **R File Memory** – 32x32-bit registers, 2 read + 1 write port  
- **System Memory** – Adjustable via `SM_DEPTH` parameter  

---

## Data Hazard Handling

Implemented via **stalling** in the Fetch module.

- Pipeline stalls for `STALL_CYCLES` (default 4) when RAW hazards are detected  
- Example:

```assembly
ADD  R1, R2, R3    // Instruction 1  
SUB  R4, R1, R5    // Dependent on R1  
MUL  R6, R4, R7    // Dependent on R4  
```

The processor stalls on instruction 2 until instruction 1's result is available.

---

## Simulation Result

- Simulation is run in **VCS**  
- Instructions are read from `basic_test.txt` using `readmemh`  
- Only instruction memory is populated in the testbench  
- Final R file contents are dumped after simulation  

<br>

**Snapshot of R File Memory:**

<br>

---

## Backend: RTL to GDS

### Synthesis & Implementation

After successful RTL simulation, the design is synthesized and compiled using **Fusion Compiler** via a `fc_synth.tcl` script.

**Changes to fc_synth.tcl:**

- Set `DESIGN_NAME` to top module name  
- Add RTL files to `rtl.f`  
- Run `make fc` to generate GDS  

---

## TSMC Memory Integration

### Existing Memory Approach

Originally used 2D flip-flop arrays for memory blocks.

### New Approach: Custom TSMC Memory

- Used **Integrator Compiler** to generate:
  - Single-port 32x32 memory (system memory)
  - Dual-port 32x32 memory (instruction memory + R file)
- Instantiated wrappers in RTL

---

### File Conversion to `.db` and `.ndm`

**Problem:** Integrator generates `.lib` and `.lef` only  
**Solution:** Convert to `.db` and `.ndm` using the `lc_script.tcl`:

```tcl
# lc_script.tcl
set LIB_NAME "Single_port_mem_IP"
set LIB_FILE "/path/to/memory.lib"
set TECH_FILE "/path/to/tech.tf"
set LEF_FILE "/path/to/memory.lef"

set lib [read_lib $LIB_FILE -return_lib_collection]
write_lib -format db [get_attr $lib name]

create_physical_lib $LIB_NAME
read_tech_file $TECH_FILE
read_lef -direct_to_frame $LEF_FILE
create_frame
write_physical_lib -force -output ${LIB_NAME}.ndm
close_lib
exit
```

Then include generated `.db` and `.ndm` in the `fc_synth.tcl`.

---

## TSMC IO Cell Integration

- IO cells used: `PDDWEW08SCDG_H` and `PDDWEW08SCDG_V`  
- Each top-level signal must pass through an IO cell  
- Instantiated above the top module  

**IO Cell Template:**

```verilog
PDDWUW08SCDG_V PDDWUW08SCDG_V_inst (
  .C  (Input_for_top_module),
  .I  (Output_of_top_module),
  .OE (Output_enable),
  .PAD(Top_wrapper_module_inout),
  .PE (Pull_enable),
  .PS (Pull_Select),
  .RTE(Retention_signal_bus)
);
```

<br>

---

## Fusion Compiler GUI

After running `make fc`, use **Fusion Compiler GUI** to:

- Analyze placement and routing  
- Visualize clock tree  
- Review GDS layout  

<br>
