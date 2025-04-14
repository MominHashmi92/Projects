`timescale 1ns/100ps
// import "./rtl/definition_pkg"::*;
module RISCV_TB ();
localparam IM_DEPTH = 64;
localparam RF_DEPTH = 32;
localparam SM_DEPTH = 32;
  // `include "./rtl/definitions.sv"
  logic                             clk_100MHz           ;
  logic                             reset                ;
  logic [($clog2(IM_DEPTH<<2))-1:0] writeAddr_IM         ;
  logic [                     31:0] writeData_IM         ;
  logic                             writeEn_IM           ;
  logic [($clog2(RF_DEPTH<<2))-1:0] writeAddr_RF_TB      ;
  logic [                     31:0] writeData_RF_TB      ;
  logic                             writeEn_RF_TB        ;
  logic [($clog2(SM_DEPTH<<2))-1:0] writeAddr_SM_TB      ;
  logic [                     31:0] writeData_SM_TB      ;
  logic                             writeEn_SM_TB        ;
  logic                             Memory_Initialization;
  logic[31:0] Instruction_Mem   [                   0:IM_DEPTH-1]    ;
  // logic [             IM_DEPTH-1:0][  31:0] Instruction_Mem      ;
  logic [RF_DEPTH-1:0][  31:0] R_File_Mem;
  logic [SM_DEPTH-1:0][  31:0] System_Mem;

  always #5 clk_100MHz=~clk_100MHz;// 100MHz clock generation

  parameter Num_Instructions = 42; // Example: if Num_Instructions = 13 then only first 13 instructions will be stored in Instruction memory

  initial begin
    clk_100MHz = 1'b0;
    reset = 1'b1;
    Memory_Initialization = 1'b0;

    writeAddr_IM = 0;
    writeData_IM = 0;
    writeEn_IM = 0;
    writeAddr_RF_TB = 0;
    writeData_RF_TB = 0;
    writeEn_RF_TB = 0;
    writeAddr_SM_TB = 0;
    writeData_SM_TB = 0;
    writeEn_SM_TB = 0;


    Instruction_Mem = '{default:32'd0}; // setting all bits in 2D array to zero
    $readmemh("instructions.txt", Instruction_Mem);
    R_File_Mem = '{default:32'd0}; // setting all bits in 2D array to zero
    System_Mem = '{default:32'd0}; // setting all bits in 2D array to zero
    #50
    reset = 0;
    #50
      Memory_Initialization = 1'b1;

    for (int i = 0; i <= (IM_DEPTH<<2); i=i+4) begin
      #10
      writeAddr_IM = i;
      writeData_IM = Instruction_Mem[i>>2];
      writeEn_IM = 1;
    end
    writeAddr_IM = 0;
    writeData_IM = 0;
    writeEn_IM = 0;
    writeAddr_RF_TB = 0;
    writeData_RF_TB =0;
    writeEn_RF_TB = 0;
    Memory_Initialization = 1'b0;
  end
  
  top_risc_v top_risc_v_inst (
    .clk_100MHz           (clk_100MHz           ),
    .reset                (reset                ),
    .writeAddr_IM         (writeAddr_IM         ),
    .writeData_IM         (writeData_IM         ),
    .writeEn_IM           (writeEn_IM           ),
    .writeAddr_RF_TB      (writeAddr_RF_TB      ),
    .writeData_RF_TB      (writeData_RF_TB      ),
    .writeEn_RF_TB        (writeEn_RF_TB        ),
    .writeAddr_SM_TB      (writeAddr_SM_TB      ),
    .writeData_SM_TB      (writeData_SM_TB      ),
    .writeEn_SM_TB        (writeEn_SM_TB        ),
    .Memory_Initialization(Memory_Initialization)
  );

endmodule