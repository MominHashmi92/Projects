
module r_file_memory #(parameter  NumEntries = 32) (
  input  logic                                       clk_100MHz,
  input  logic                                       writeEn   ,
  input  logic                                       readEn    ,
  input  logic                                       reset     ,
  input  logic [($clog2(NumEntries<<2))-1:0]         writeAddr ,
  input  logic [                     32-1:0]         writeData ,
  input  logic [($clog2(NumEntries<<2))-1:0]         readAddr  ,
  input  logic                                       readEn_2  ,
  input  logic [($clog2(NumEntries<<2))-1:0]         readAddr_2,
  output logic [                     32-1:0]         readData_2,
  output logic [                     32-1:0]         readData  
);

  logic [NumEntries][32-1:0] mem;
  always_ff @(posedge clk_100MHz) begin
    if (reset) begin
      mem <= '{default:32'd0}; // initialize memory with 0
    end
    else begin
      if (writeAddr==0) begin
        mem[0] <= 0; // from byte addressable to words addressable
      end
      else if(writeEn) begin
        mem[writeAddr>>2] <= writeData; // from byte addressable to words addressable
      end
    end
  end
  assign readData   = readEn ? mem[readAddr] : 0;// from byte addressable to words addressable
  assign readData_2 = readEn_2 ? mem[readAddr_2] : 0;// from byte addressable to words addressable

endmodule