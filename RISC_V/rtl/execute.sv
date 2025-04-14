module execute (
  input  logic        clk_100MHz            ,
  input  logic        reset                 ,
  input  logic [31:0] instruction_fetched   ,
  input  logic [31:0] data_rs1              ,
  input  logic [31:0] data_rs2              ,
  input  logic [ 4:0] rd_0                  ,
  input  logic [11:0] I_imm                 ,
  input        [ 2:0] funct3                ,
  input        [ 6:0] funct7                ,
  input        [ 4:0] shamt                 ,
  output logic [31:0] data_out_exe          ,
  output logic [31:0] instruction_fetched_R1,
  output logic [ 4:0] rd_1                  ,
  output logic [31:0] data_rs2_R1
);

  parameter OutputWidth = 32; // Sign extension output data width
  parameter InputWidth  = 12; // Sign extension input data width
  logic [31:0] SLTU,SLT,ADD,XOR,OR,AND,SRL,SLL,SUB,SRA;
  logic [31:0] I_imm_Sign_extended;
  logic [31:0] Second_Operand;
  logic [ 3:0] MUX_SELECT         ;
  logic [ 4:0] Second_Operand_2;
  logic [ 6:0] OPCODE             ;

  assign OPCODE = instruction_fetched[6:0];

  always_comb begin
    if (OPCODE == R_TYPE) begin
      MUX_SELECT = {funct7[5],funct3};
    end
    else if (OPCODE == I_TYPE) begin
      if (funct3 == 3'b001 || funct3 == 3'b101) begin
        MUX_SELECT = {funct7[5],funct3};
      end
      else begin
        MUX_SELECT = {1'b0,funct3};
      end
    end
    else if ( (OPCODE == LOAD) || (OPCODE == STORE)) begin
      MUX_SELECT = 0;
    end
    else begin
      MUX_SELECT = 15;
    end
  end

  always_ff @(posedge clk_100MHz) begin
    if (reset) begin
      instruction_fetched_R1 <= 0;
      rd_1                   <= 0;
      data_rs2_R1            <= 0;
      data_out_exe           <= 0;
    end
    else
      begin
        instruction_fetched_R1 <= instruction_fetched;
        rd_1                   <= rd_0;
        data_rs2_R1            <= data_rs2;
        case (MUX_SELECT) // 4bit
          4'd0 : begin  // ADD
            data_out_exe <= ADD;
          end
          4'd1 : begin  //SLL
            data_out_exe <= SLL;
          end
          4'd2 : begin   //SLT
            data_out_exe <= SLT;
          end
          4'd3 : begin   //SLTU
            data_out_exe <= SLTU;
          end
          4'd4 : begin   //XOR
            data_out_exe <= XOR;
          end
          4'd5 : begin   //SRL
            data_out_exe <= SRL;
          end
          4'd6 : begin   //OR
            data_out_exe <= OR;
          end
          4'd7 : begin   //AND
            data_out_exe <= AND;
          end
          4'd8 : begin   //SUB
            data_out_exe <= SUB;
          end
          4'd13 : begin   //SRA 1101
            data_out_exe <= SRA;
          end
          4'd15 : begin   //SRA 1101
            data_out_exe <= 0;
          end
          default : begin
            data_out_exe <= 32'd0;
          end
        endcase
      end
  end

  assign I_imm_Sign_extended = { {OutputWidth-InputWidth{I_imm[InputWidth-1]}}, I_imm }; // SIGN EXTENSION
  assign Second_Operand      = (OPCODE == R_TYPE) ? data_rs2 : I_imm_Sign_extended;
  assign Second_Operand_2    = (OPCODE == R_TYPE) ? data_rs2[4:0] : shamt;
  assign ADD                 = data_rs1 + Second_Operand ; //Addition
  assign SLL                 = (data_rs1 << Second_Operand_2)  ; // Logic shift left on the value in register rs1 by the shift amount held in the lower 5 bits of register rs2.
  assign SLT                 = {31'd0 , ($signed(data_rs1) < $signed(Second_Operand))} ; // $signed(data_rs1) < $signed(data_rs2)
  assign SLTU                = {31'd0 , (data_rs1 < Second_Operand )}; //Unsigned comparator
  assign XOR                 = data_rs1 ^ Second_Operand ; //bitwise XOR
  assign SRL                 = (data_rs1 >> Second_Operand_2) ; // Logic shift right on the value in register rs1 by the shift amount held in the lower 5 bits of register rs2.
  assign OR                  = data_rs1 | Second_Operand ; //bitwise OR
  assign AND                 = data_rs1 & Second_Operand ; //bitwise AND
  assign SUB                 = data_rs1 - data_rs2 ; //Subtraction
  assign SRA                 = ($signed(data_rs1) >>> Second_Operand_2)  ; // arithmetic shift right on the value in register rs1 by the shift amount held in the lower 5 bits of register rs2.

  //Ref : page 13,14,15 RISCV-spec-v2.2.pdf
  // Sign extension ref :  https://circuitcove.com/design-examples-sign-extension/

endmodule