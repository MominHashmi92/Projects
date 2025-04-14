module riscv_top (
    input  logic clk_100MHz,
    input  logic reset,
    input  logic Memory_Initialization,
    
    // Instruction Memory interface
    input  logic [($clog2(IM_DEPTH<<2))-1:0] writeAddr_IM,
    input  logic [31:0] writeData_IM,
    input  logic writeEn_IM,

    // Data Memory interface
    input  logic [($clog2(SM_DEPTH<<2))-1:0] writeAddr_SM_TB,
    input  logic [31:0] writeData_SM_TB,
    input  logic writeEn_SM_TB
);

    // Internal wires for pipeline
    logic [31:0] instruction_fetched;
    logic [31:0] readData_RF, readData_RF_2;
    logic [($clog2(RF_DEPTH<<2))-1:0] readAddr_RF, readAddr_RF_2;
    logic [31:0] data_rs1, data_rs2;
    logic [4:0] rd_0, rd_1, rd_2;
    logic [11:0] I_imm;
    logic [4:0] shamt;
    logic [2:0] funct3;
    logic [6:0] funct7;
    logic [31:0] instruction_fetched_R0, instruction_fetched_R1, instruction_fetched_R2;
    logic [31:0] data_out_exe, data_out_exe_R2, data_rs2_R1;
    logic [$clog2(RF_DEPTH<<2)-1:0] writeAddr_RF_WB;
    logic [31:0] writeData_RF_WB;
    logic writeEn_RF_WB;

    // FETCH
    fetch u_fetch (
        .clk_100MHz(clk_100MHz),
        .reset(reset),
        .writeAddr_IM(writeAddr_IM),
        .writeData_IM(writeData_IM),
        .writeEn_IM(writeEn_IM),
        .Memory_Initialization(Memory_Initialization),
        .instruction_fetched(instruction_fetched)
    );

    // DECODE
    decode u_decode (
        .clk_100MHz(clk_100MHz),
        .reset(reset),
        .instruction_fetched(instruction_fetched),
        .readData_RF(readData_RF),
        .readData_RF_2(readData_RF_2),
        .readAddr_RF(readAddr_RF),
        .readAddr_RF_2(readAddr_RF_2),
        .data_rs1(data_rs1),
        .data_rs2(data_rs2),
        .rd_0(rd_0),
        .I_imm(I_imm),
        .instruction_fetched_R0(instruction_fetched_R0),
        .funct3(funct3),
        .funct7(funct7),
        .shamt(shamt)
    );

    // EXECUTE
    execute u_execute (
        .clk_100MHz(clk_100MHz),
        .reset(reset),
        .instruction_fetched(instruction_fetched_R0),
        .data_rs1(data_rs1),
        .data_rs2(data_rs2),
        .rd_0(rd_0),
        .I_imm(I_imm),
        .funct3(funct3),
        .funct7(funct7),
        .shamt(shamt),
        .data_out_exe(data_out_exe),
        .instruction_fetched_R1(instruction_fetched_R1),
        .rd_1(rd_1),
        .data_rs2_R1(data_rs2_R1)
    );

    // MEMORY
    memory u_memory (
        .clk_100MHz(clk_100MHz),
        .reset(reset),
        .data_out_exe(data_out_exe),
        .rd_1(rd_1),
        .data_rs2_R1(data_rs2_R1),
        .instruction_fetched_R1(instruction_fetched_R1),
        .Memory_Initialization(Memory_Initialization),
        .writeAddr_SM_TB(writeAddr_SM_TB),
        .writeData_SM_TB(writeData_SM_TB),
        .writeEn_SM_TB(writeEn_SM_TB),
        .instruction_fetched_R2(instruction_fetched_R2),
        .rd_2(rd_2),
        .data_out_exe_R2(data_out_exe_R2)
    );

    // WRITE BACK
    write_back u_write_back (
        .clk_100MHz(clk_100MHz),
        .reset(reset),
        .data_out_exe_R2(data_out_exe_R2),
        .instruction_fetched_R2(instruction_fetched_R2),
        .rd_2(rd_2),
        .writeAddr_RF_WB(writeAddr_RF_WB),
        .writeData_RF_WB(writeData_RF_WB),
        .writeEn_RF_WB(writeEn_RF_WB)
    );

    // REGISTER FILE
    r_file_memory #(.NumEntries(RF_DEPTH)) u_r_file_memory (
        .clk_100MHz(clk_100MHz),
        .writeEn(writeEn_RF_WB),
        .readEn(1'b1),
        .reset(reset),
        .writeAddr(writeAddr_RF_WB),
        .writeData(writeData_RF_WB),
        .readAddr(readAddr_RF),
        .readEn_2(1'b1),
        .readAddr_2(readAddr_RF_2),
        .readData_2(readData_RF_2),
        .readData(readData_RF)
    );

endmodule
