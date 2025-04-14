module write_back (
  input  logic                                   clk_100MHz            ,
  input  logic                                   reset                 ,
  input  logic [                     31:0]       data_out_exe_R2       ,
  input  logic [                     31:0]       instruction_fetched_R2,
  input  logic [                      4:0]       rd_2                  ,
  output logic [($clog2(RF_DEPTH<<2))-1:0]       writeAddr_RF_WB       ,
  output logic [                     31:0]       writeData_RF_WB       ,
  output logic                                   writeEn_RF_WB
);

  logic [6:0] OPCODE;

  assign OPCODE = instruction_fetched_R2[6:0];

  always_ff @(posedge clk_100MHz) begin
    writeAddr_RF_WB <= 0;
    writeData_RF_WB <= 0;
    writeEn_RF_WB   <= 0;
    if ((OPCODE == R_TYPE) || (OPCODE == I_TYPE) || (OPCODE == LOAD)) begin
      writeAddr_RF_WB <= (rd_2<<2) ;
      writeData_RF_WB <= data_out_exe_R2;
      writeEn_RF_WB   <= 1;
    end
    else begin
      writeAddr_RF_WB <= 0;
      writeData_RF_WB <= 0;
      writeEn_RF_WB   <= 0;
    end
  end

endmodule : write_back