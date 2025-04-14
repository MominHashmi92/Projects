module memory (
  input  logic                             clk_100MHz            ,
  input  logic                             reset                 ,
  input  logic [                     31:0] data_out_exe          ,
  input  logic [                      4:0] rd_1                  ,
  input  logic [                     31:0] data_rs2_R1           ,
  input  logic [                     31:0] instruction_fetched_R1,
  input  logic                             Memory_Initialization ,
  input  logic [($clog2(SM_DEPTH<<2))-1:0] writeAddr_SM_TB       ,
  input  logic [                     31:0] writeData_SM_TB       ,
  input  logic                             writeEn_SM_TB         ,
  output logic [                     31:0] instruction_fetched_R2,
  output logic [                      4:0] rd_2                  ,
  output logic [                     31:0] data_out_exe_R2
);

  logic [             SM_DEPTH-1:0][32-1:0] system_mem  ;
  logic [($clog2(SM_DEPTH<<2))-1:0]         writeAddr_SM;
  logic[31:0] writeData_SM ;
  logic       writeEn_SM;
  logic [6:0] OPCODE    ;

  assign OPCODE = instruction_fetched_R1 [ 6:0];

  always_ff @(posedge clk_100MHz ) begin
    if(reset) begin
      instruction_fetched_R2 <= 0;
      rd_2                   <= 0;
    end else begin
      instruction_fetched_R2 <= instruction_fetched_R1;
      rd_2                   <= rd_1;
      case (OPCODE)
        R_TYPE : begin
          data_out_exe_R2 <= data_out_exe;
        end
        I_TYPE : begin
          data_out_exe_R2 <= data_out_exe;
        end
        LOAD : begin
          data_out_exe_R2 <= system_mem[data_out_exe];
        end
        STORE : begin
        end
        default : begin
          data_out_exe_R2 <= 0;
        end
      endcase
    end
  end



  assign writeAddr_SM = data_out_exe;
  assign writeData_SM = data_rs2_R1;
  assign writeEn_SM   = (OPCODE==STORE) ? 1 : 0;


  system_memory #(.NumEntries(SM_DEPTH)) System_memory (
    .clk_100MHz(clk_100MHz  ),
    .reset     (reset       ),
    .writeAddr (writeAddr_SM),
    .writeData (writeData_SM),
    .writeEn   (writeEn_SM  ),
    .readAddr  (7'd0        ),
    .readData  (            ),
    .readEn    (1'b0        ),
    .mem       (system_mem  )
  );

endmodule