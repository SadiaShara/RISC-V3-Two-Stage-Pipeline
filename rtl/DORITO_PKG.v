 20 package DORITO_PKG;
 21 //module DORITO_PKG;
 22
 23 parameter BUS_SIZE = 32;
 24
 25 parameter MNEMONIC_NO = 32;
 26 localparam MNEMONIC_SIZE = $clog2(MNEMONIC_NO);
 27
 28 parameter REGISTER_NO = 8;
 29 localparam REG_ADDR_SIZE = $clog2(REGISTER_NO);
 30
 31 parameter ADDRESS_HEIGHT = 32;
 32 localparam ADDR_SIZE = $clog2(ADDRESS_HEIGHT);
 33
 34 parameter NO_OF_STATE = 6;
 35 localparam STATE_REG_WIDTH = $clog2(NO_OF_STATE);
 36
 37
 38 //FSM STATES
 39 parameter INIT = 3'b000;
 40 parameter FETCH = 3'b001;
 41 parameter EXEC_RG_IM_ADDR = 3'b010;
 42 parameter EXEC_MRI_LOAD = 3'b011;
 43 parameter EXEC_MRI_STORE = 3'b100;
 44 parameter EXEC_BRANCH = 3'b101;
 45
 46
 47 //BRANCH ALTERNATIVES
 48 parameter BRN_RC_ZERO = 0;
 49 parameter BRN_RC_POS = 1; 
50 parameter BRN_RC_NEG = 2;
 51 parameter BRN_ALW = 3;
 52
 53
 54 //INSTRUCTION TYPES
 55 const logic [3:0] REG_REG = '0;
 56 const logic [3:0] REG_IMM = 4'b0001;
 57 const logic [3:0] MRI_LOAD = 4'b0010;
 58 const logic [3:0] MRI_STORE = 4'b0011;
 59 const logic [3:0] BRANCH = 4'b0100;
 60
 61 //MNEMONIC/OPCODE
 62 const logic [4:0] ADD = '0;
 63 const logic [4:0] SUB = 5'b00001;
 64 const logic [4:0] INC_IN1 = 5'b00010;
 65 const logic [4:0] INC_IN2 = 5'b00011;
 66 const logic [4:0] PASS_0 = 5'b00100;
 67 const logic [4:0] PASS_IN2 = 5'b00101;
 68 const logic [4:0] PASS_LOW16_IN2 = 5'b00110;
 69 const logic [4:0] PASS_HIGH16_IN2 = 5'b00111;
 70 const logic [4:0] AND =                 5'b10011;//19
 71 const logic [4:0] OR =                  5'b10100;
 72 const logic [4:0] XOR =                 5'b10101;
 73 const logic [4:0] NAND =                5'b10110;
 74 const logic [4:0] NOR =                 5'b10111;
 75 const logic [4:0] XNOR =                5'b11000;
 76 const logic [4:0] NOT_IN2 =     5'b11001;
 77 const logic [4:0] L_SHIFT_IN2 =         5'b11010;
 78 const logic [4:0] R_SHIFT_IN2 =         5'b11011;
 79 const logic [4:0] S_L_SHIFT_IN2 =       5'b11100; 
 80 const logic [4:0] S_R_SHIFT_IN2 =       5'b11101;
 81 const logic [4:0] L_ROTATE_IN2 =        5'b11110;
 82 const logic [4:0] R_ROTATE_IN2 =        5'b11111;
 83
 84 endpackage : DORITO_PKG
 85 //endmodule : DORITO_PKG      
