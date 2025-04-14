`timescale 1ns/100ps
module fetch (
  input  logic                             clk_100MHz           ,
  input  logic                             reset                ,
  input  logic [($clog2(IM_DEPTH<<2))-1:0] writeAddr_IM         ,
  input  logic [                     31:0] writeData_IM         ,
  input  logic                             writeEn_IM           ,
  input                                    Memory_Initialization,
  output logic [                     31:0] instruction_fetched
);
  logic [($clog2(IM_DEPTH<<2))-1:0] Program_Counter,Program_Counter_Next,Next_INST_index;
  logic [                     31:0] readData_IM,readData_IM_2;
  logic                             PC_en          ;
  //Stalling variables
  logic [  31:0] Next_instruction,Current_Instruction;
  logic [   4:0] Next_instruction_RS1,Next_instruction_RS2,Current_Instruction_RD;
  logic [   6:0] OPCODE_NEXT         ;
  logic          stall               ;
  logic [10-1:0] counter, counter_next; // [($clog2(STALL_CYCELS<<2))-1:0]
  logic          count_en            ;
  
  always_ff @(posedge clk_100MHz) begin
    if (reset | Memory_Initialization) begin
      instruction_fetched <= 0;
      Program_Counter     <= 0;
      counter             <= 0;
    end
    else begin
      instruction_fetched <= readData_IM;
      counter             <= counter_next;
      if (Program_Counter_Next == (IM_DEPTH<<2)) begin // (IM_Depth<<2)-> IM_Depth*4
        Program_Counter <= 0;
      end
      else begin
        Program_Counter <= Program_Counter_Next;
      end
    end
  end

  always_comb begin
    if (reset| Memory_Initialization) begin
      Program_Counter_Next = 0;
    end
    else if(PC_en) begin
      Program_Counter_Next = Program_Counter + 4;
    end
    else begin
      Program_Counter_Next = Program_Counter;
    end
  end
  
  `ifdef exclude_Stalling

    assign Next_instruction       = 0;
    assign OPCODE_NEXT            = 0;
    assign Next_instruction_RS1   = 0;
    assign Next_instruction_RS2   = 0;
    assign Current_Instruction    = 0;
    assign Current_Instruction_RD = 0;
    assign PC_en                  = 1;
    assign count_en               = 0;
    assign stall                  = 0;
    assign Next_INST_index        = 0;
    assign counter_next           = 0;
  `else
    ////////////////////////////////////////////////////  STALLING LOGIC /////////////////////////////////////////////////////////////////////////
    //If next instruction has a source address same as of current instruction's destination address then pause PC for N number of cycles
    // If stall==1 then stops the PC for 5 cycles
    always_comb begin
      //Next instruction
      Next_instruction     = readData_IM_2;
      OPCODE_NEXT          = Next_instruction[6:0];
      Next_instruction_RS1 = Next_instruction [19:15] ;//RS1
      Next_instruction_RS2 = Next_instruction [24:20]; //RS2

      //Current instruction
      Current_Instruction    = readData_IM;
      Current_Instruction_RD = Current_Instruction [11:7];// rd
      PC_en                  = 1'b1;
      count_en               = 1'b0;

      case (OPCODE_NEXT)
        R_TYPE : begin
          stall = ((Next_instruction_RS1 == Current_Instruction_RD) | (Next_instruction_RS2 == Current_Instruction_RD));
        end
        I_TYPE : begin
          stall = (Next_instruction_RS1 == Current_Instruction_RD) ;
        end
        LOAD : begin
          stall = 0;
        end
        STORE : begin
          stall = (Next_instruction_RS2 == Current_Instruction_RD) ;
        end
        default : begin
          stall = 0;
        end
      endcase

      if (stall) begin
        // stop PC for N cycles
        if (counter < STALL_CYCELS) begin
          PC_en    = 1'b0;
          count_en = 1'b1;
        end
        else begin
          PC_en    = 1'b1;
          count_en = 1'b0;
        end
      end

      if ((Program_Counter+4)==(IM_DEPTH<<2)) begin
        Next_INST_index = 0 ;
      end
      else begin
        Next_INST_index = (Program_Counter)+4 ;
      end
    end

    assign counter_next = count_en ? (counter+1) : 0;

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////
  `endif

  instruction_memory #(.NumEntries(IM_DEPTH)) Instruction_Memory (
    .clk_100MHz(clk_100MHz     ),
    .writeEn   (writeEn_IM     ),
    .readEn    (1'b1           ),
    .reset     (reset          ),
    .writeAddr (writeAddr_IM   ),
    .writeData (writeData_IM   ),
    .readAddr  (Program_Counter),
    .readData  (readData_IM    ),
    .readEn_2  (1'b1           ),
    .readAddr_2(Next_INST_index),
    .readData_2(readData_IM_2  )
  );

endmodule