package definition_pkg;
  parameter IM_DEPTH = 64;
  parameter RF_DEPTH = 32;
  parameter SM_DEPTH = 32;
  parameter R_TYPE = 7'b0110011;
  parameter I_TYPE = 7'b0010011;
  parameter LOAD   = 7'b0000011;
  parameter STORE  = 7'b0100011;
  parameter STALL_CYCELS = 4; // number of stall cycles to manage data hazards
endpackage