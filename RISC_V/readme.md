
# RISC-V RV32I Pipeline Processor

## Introduction

In this project, I implemented the RISC-V architecture for RV32I base instructions, encompassing four instruction types: **R-type, I-type, Load, and Store**. The RTL design was written in **SystemVerilog** and simulated using the **VCS simulator**. The processor includes:

- Fetch block  
- Decode block  
- Execute block  
- Memory block  
- Write-back block  

Each stage is registered to maintain synchronization. The architecture follows the standard RISC-V ISA and is implemented in a **5-stage pipeline** with **stall-based hazard handling**.

---

## Architecture

Architecture of the design is depicted in the block diagram below:

![image](https://github.com/user-attachments/assets/861bc26f-6428-456e-ab7f-0fbead838843)


---

## Micro-Architecture

Micro-architecture of the design is shown below:

![image](https://github.com/user-attachments/assets/e32d5ae0-bb1c-4911-98f3-f6434a17a4c4)


---

## Frontend

### RTL Module Hierarchy

The design hierarchy is:

![image](https://github.com/user-attachments/assets/da8b4f77-d535-4451-84f3-92fed49ac56f)


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
![image](https://github.com/user-attachments/assets/fe0c708b-6f1e-4578-9ba1-4f8d8d55059d)


Responsible for fetching the next instruction from memory. Includes:

- PC increment logic  
- Instruction memory access  
- Stall logic for data hazards  

<br>

---

## Decode Module
![image](https://github.com/user-attachments/assets/c8e9c33a-7d14-449a-ac40-50fe2f1c4ac5)

Performs instruction decoding, including:

- Opcode and operand decoding  
- R file register read  
- Generation of control signals  

<br>

---

## Execute Module
![image](https://github.com/user-attachments/assets/feaef718-1b4a-4c08-a7b0-e9541c78be5c)

Implements the **ALU** and performs actual computation:

- Arithmetic and logical operations  
- Result forwarding to memory/write-back  
- Handles immediate values  

<br>

---

## Memory Module
![image](https://github.com/user-attachments/assets/9ec1d391-4d26-4850-b70c-98520606b126)

Handles data memory operations:

- Calculates effective address  
- Performs load/store  
- Transfers data to write-back or receives data from execute  

<br>

---

## Write-back Module
![image](https://github.com/user-attachments/assets/2a1a55ba-a0f2-4f6b-a28a-4a938524da18)

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
![image](https://github.com/user-attachments/assets/b1d1d483-62d0-4310-8f9c-7e312b08faeb)

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
Following the integration of IO cells, I executed the command "make fc," which led to the execution of synthesis, compilation, and implementation steps. Once all these steps were successfully completed, I opened the Fusion Compiler (FC) shell GUI, loaded the Clock Tree Synthesis (CTS) file of my top wrapper, and observed the following view.

![image](https://github.com/user-attachments/assets/0f71ac5b-d86e-47a6-b83a-0776090e2640)

After running `make fc`, use **Fusion Compiler GUI** to:


- Analyze placement and routing  
- Visualize clock tree  
- Review GDS layout  

<br>


## Corner cell integration 

The next step involves incorporating appropriate corner cells into the design. To do this, navigate to the Task tab, proceed to design planning, and in the design planning panel, select wire bond IO. Move to the corner cell tab, choose the PCORNER_V cell as your corner cells, and click apply. This action will integrate corner cells into your design. In the Place IO tab, click apply to adjust corner cells in the four corners of your die. Following this step, the IC appeared as illustrated below.
`create_cell {CORNER1 CORNER2 CORNER3 CORNER4} tphn05_12gpiossgnp0p675v1p08vm40c/PCORNER_V`
![image](https://github.com/user-attachments/assets/f4451694-7b74-4a88-9522-17d73d00d1a6)

Filler cells integration 

The next crucial step is to incorporate filler cells into the design to ensure power connectivity between corner cells and IO cells. This can be achieved by executing the following command in your Fusion Compiler (FC) shell:

`create_io_filler_cells -reference_cells [get_attr [get_lib_cell PFILLER00051_V] name]`
Following this step, the IC appeared as illustrated below.
![image](https://github.com/user-attachments/assets/c9118273-7878-4ff6-a3ee-6b7724b2a630)

Currently, this marks the final step we've taken in generating the GDS. In the future, our upcoming tasks include integrating bumps into our design, running Layout Versus Schematics (LVS), and ultimately examining and resolving any Design Rule Checks (DRCs) in our design.

