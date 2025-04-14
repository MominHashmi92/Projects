`timescale 1ns/100ps
module decode (
  input  logic                             clk_100MHz            ,
  input  logic                             reset                 ,
  input  logic [                     31:0] instruction_fetched   ,
  input  logic [                     31:0] readData_RF           ,
  input  logic [                     31:0] readData_RF_2         ,
  output logic [($clog2(RF_DEPTH<<2))-1:0] readAddr_RF           ,
  output logic [($clog2(RF_DEPTH<<2))-1:0] readAddr_RF_2         ,
  output logic [                     31:0] data_rs1              ,
  output logic [                     31:0] data_rs2              ,
  output logic [                      4:0] rd_0                  ,
  output logic [                     11:0] I_imm                 ,
  output logic [                     31:0] instruction_fetched_R0,
  output       [                      2:0] funct3                ,
  output       [                      6:0] funct7                ,
  output       [                      4:0] shamt
);

  logic [6:0] OPCODE;
  logic [4:0] rd,rs1,rs2;
  
  assign OPCODE = instruction_fetched[06:00];
  assign rs1    = instruction_fetched[19:15]; // Source address of reg 1
  assign rs2    = instruction_fetched[24:20]; // Source address of reg 2
  assign rd     = instruction_fetched[11:07]; // Destination address
  // Variables passed to execute stage
  assign funct3        = instruction_fetched_R0[14:12];
  assign funct7        = instruction_fetched_R0[31:25];
  assign shamt         = instruction_fetched_R0[24:20];
  assign readAddr_RF   = rs1;
  assign readAddr_RF_2 = rs2;

  always_ff @(posedge clk_100MHz) begin
    // always_comb begin
    if (reset) begin
      data_rs1               <= 0;
      data_rs2               <= 0;
      rd_0                   <= 0;
      instruction_fetched_R0 <= 0;
      I_imm                  <= 0;
    end
    else begin
      data_rs1               <= readData_RF;
      data_rs2               <= readData_RF_2;
      rd_0                   <= rd;
      instruction_fetched_R0 <= instruction_fetched;
      if (OPCODE == STORE) begin
        I_imm <= {instruction_fetched[31:25],instruction_fetched[11:7]}; //Memory Offset
      end
      else begin
        I_imm <= instruction_fetched[31:20]; //Memory Offset
      end
    end
  end
endmodule

