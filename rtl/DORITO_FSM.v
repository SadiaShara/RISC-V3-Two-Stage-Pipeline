  1 timeunit 1ns;                                                                                                             2 timeprecision 1ps;
  3
  4 import DORITO_PKG::*;
  5
  6 module DORITO_FSM
  7 (
  8     input logic SYS_CLOCK,
  9     input logic FSM_ARESET,
 10
 11     input logic [BUS_SIZE-1:0] IR_OUT,
 12
 13     input logic CARRYOUT,
 14     input logic U_OVF,
 15     input logic S_OVF,
 16     input logic ALU_OUT_ZERO,
 17     input logic ALU_OUT_POS,
 18     input logic ALU_OUT_NEG,
 19
 20     output logic SCLR_PC,
 21     output logic INC_PC,
 22     output logic LOAD_PC,
 23
 24     output logic LOAD_IR1,
 25     output logic LOAD_IR2,
 26     output logic FLUSH_IR1,
 27
 28     output logic [REG_ADDR_SIZE-1:0] SEL_SOURCE_REG1,
 29     output logic [REG_ADDR_SIZE-1:0] SEL_SOURCE_REG2,
 30     output logic [REG_ADDR_SIZE-1:0] SEL_DEST_REG,
 32     output logic REG_FILE_ARESET,
 33     output logic LOAD_DEST_REG,
 34     output logic LOAD_ACCUM_REG,
 35
 36     output logic IMM_OFFSET_SELECTOR,
 37     output logic BRANCH_BASE_ADJUST,
 38
 39     output logic SEL_SOURCE1,
 40     output logic SEL_SOURCE2,
 41
 42     output logic [MNEMONIC_SIZE-1:0] ALU_CONTROL,
 43
 44     output logic SEL_DATA,
 45     output logic SEL_ADDR,
 46     output logic LOAD_ADDR_REG,
 47
 48     output logic MEM_ARESET,
 49     output logic MEM_WRITE,
 50     output logic EN
 51 );
 52
 53
 54 // Instruction fields from the execution-stage instruction register
 55 logic [3:0] INSTR_TYPE;
 56 logic [4:0] MNEMONIC;
 57 logic [2:0] RD_RS_MRI;
 58 logic [2:0] RS1_RB_MRI;
 59 logic [2:0] RS2_RI_MRI_RC_BRN;
 60 logic [1:0] CC_BRN;
 62 assign INSTR_TYPE        = IR_OUT[31:28];
 63 assign MNEMONIC          = IR_OUT[27:23];
 64 assign RD_RS_MRI         = IR_OUT[22:20];
 65 assign RS1_RB_MRI        = IR_OUT[19:17];
 66 assign RS2_RI_MRI_RC_BRN = IR_OUT[16:14];
 67 assign CC_BRN            = IR_OUT[13:12];
 68
 69
 70 // Two-stage pipeline controller states
 71 localparam logic [2:0] ST_INIT   = 3'd0;
 72 localparam logic [2:0] ST_FILL1  = 3'd1;
 73 localparam logic [2:0] ST_FILL2  = 3'd2;
 74 localparam logic [2:0] ST_EXEC   = 3'd3;
 75 localparam logic [2:0] ST_LOAD   = 3'd4;
 76 localparam logic [2:0] ST_STORE  = 3'd5;
 77 localparam logic [2:0] ST_BRANCH = 3'd6;
 78 localparam logic [2:0] ST_REFILL = 3'd7;
 79
 80 logic [2:0] P_STATE;
 81 logic [2:0] N_STATE;
 82
 83 logic BRANCH_TAKEN;
 84
 85 assign BRANCH_TAKEN =
 86        ((CC_BRN == 2'b00) && ALU_OUT_ZERO)
 87     || ((CC_BRN == 2'b01) && ALU_OUT_POS)
 88     || ((CC_BRN == 2'b10) && ALU_OUT_NEG)
 89     ||  (CC_BRN == 2'b11);
 92 always_comb
 93 begin : PIPELINE_CONTROL
 94
 95     N_STATE = P_STATE;
 96
 97     // Default control values
 98     SCLR_PC = 1'b0;
 99     INC_PC  = 1'b0;
100     LOAD_PC = 1'b0;
101
102     LOAD_IR1  = 1'b0;
103     LOAD_IR2  = 1'b0;
104     FLUSH_IR1 = 1'b0;
105
106     SEL_SOURCE_REG1 = '0;
107     SEL_SOURCE_REG2 = '0;
108     SEL_DEST_REG    = '0;
109
110     REG_FILE_ARESET = 1'b0;
111     LOAD_DEST_REG   = 1'b0;
112     LOAD_ACCUM_REG  = 1'b0;
113
114     IMM_OFFSET_SELECTOR = 1'b0;
115     BRANCH_BASE_ADJUST  = 1'b0;
116
117     SEL_SOURCE1 = 1'b1;
118     SEL_SOURCE2 = 1'b0;
119
120     ALU_CONTROL = '0;
122     SEL_DATA      = 1'b0;
123     SEL_ADDR      = 1'b0;
124     LOAD_ADDR_REG = 1'b0;
125
126     MEM_ARESET = 1'b0;
127     MEM_WRITE  = 1'b0;
128     EN         = 1'b0;
129
130
131     case (P_STATE)
132
133         ST_INIT:
134         begin
135             SCLR_PC         = 1'b1;
136             REG_FILE_ARESET = 1'b1;
137             MEM_ARESET      = 1'b1;
138             FLUSH_IR1       = 1'b1;
139
140             N_STATE = ST_FILL1;
141         end
142
143
144         // Fetch first instruction into IR1
145         ST_FILL1:
146         begin
147             LOAD_IR1 = 1'b1;
148             INC_PC   = 1'b1;
149
150             N_STATE = ST_FILL2;
151         end     
154         // Move first instruction into IR2 and fetch the second
155         ST_FILL2:
156         begin
157             LOAD_IR2 = 1'b1;
158             LOAD_IR1 = 1'b1;
159             INC_PC   = 1'b1;
160
161             N_STATE = ST_EXEC;
162         end
163
164
165         ST_EXEC:
166         begin
167             case (INSTR_TYPE)
168
169                 REG_REG:
170                 begin
171                     SEL_SOURCE_REG1 = RS1_RB_MRI;
172                     SEL_SOURCE_REG2 = RS2_RI_MRI_RC_BRN;
173
174                     ALU_CONTROL = MNEMONIC;
175
176                     SEL_DATA      = 1'b1;
177                     SEL_DEST_REG  = RD_RS_MRI;
178                     LOAD_DEST_REG = 1'b1;
179
180                     LOAD_ACCUM_REG = 1'b1;
181
182                     // Execute IR2 while advancing the instruction pipeline
183                     LOAD_IR2 = 1'b1;     
184                     LOAD_IR1 = 1'b1;
185                     INC_PC   = 1'b1;
186
187                     N_STATE = ST_EXEC;
188                 end
189
190
191                 REG_IMM:
192                 begin
193                     SEL_SOURCE_REG1 = RS1_RB_MRI;
194
195                     IMM_OFFSET_SELECTOR = 1'b1;
196                     SEL_SOURCE2         = 1'b1;
197
198                     ALU_CONTROL = MNEMONIC;
199
200                     SEL_DATA      = 1'b1;
201                     SEL_DEST_REG  = RD_RS_MRI;
202                     LOAD_DEST_REG = 1'b1;
203
204                     LOAD_ACCUM_REG = 1'b1;
205
206                     LOAD_IR2 = 1'b1;
207                     LOAD_IR1 = 1'b1;
208                     INC_PC   = 1'b1;
209
210                     N_STATE = ST_EXEC;
211                 end
214                 MRI_LOAD:
215                 begin
216                     SEL_SOURCE_REG1 = RS1_RB_MRI;
217                     SEL_SOURCE_REG2 = RS2_RI_MRI_RC_BRN;
218
219                     ALU_CONTROL   = ADD;
220                     LOAD_ADDR_REG = 1'b1;
221
222                     // Stall fetching while the data memory is used
223                     N_STATE = ST_LOAD;
224                 end
225
226
227                 MRI_STORE:
228                 begin
229                     SEL_SOURCE_REG1 = RS1_RB_MRI;
230                     SEL_SOURCE_REG2 = RS2_RI_MRI_RC_BRN;
231
232                     ALU_CONTROL   = ADD;
233                     LOAD_ADDR_REG = 1'b1;
234
235                     // Stall fetching while the data memory is used
236                     N_STATE = ST_STORE;
237                 end
238
239
240                 BRANCH:
241                 begin
242                     SEL_SOURCE_REG2 = RS2_RI_MRI_RC_BRN;
243                     ALU_CONTROL     = PASS_IN2;    
245                     if (BRANCH_TAKEN)
246                     begin
247                         N_STATE = ST_BRANCH;
248                     end
249                     else
250                     begin
251                         LOAD_IR2 = 1'b1;
252                         LOAD_IR1 = 1'b1;
253                         INC_PC   = 1'b1;
254
255                         N_STATE = ST_EXEC;
256                     end
257                 end
258
259
260                 default:
261                 begin
262                     // Unsupported instructions behave as pipeline NOPs
263                     LOAD_IR2 = 1'b1;
264                     LOAD_IR1 = 1'b1;
265                     INC_PC   = 1'b1;
266
267                     N_STATE = ST_EXEC;
268                 end
269
270             endcase
271         end
272
273
274         // Complete load operation  
275         ST_LOAD:
276         begin
277             SEL_ADDR = 1'b1;
278             EN       = 1'b1;
279
280             SEL_DATA      = 1'b0;
281             SEL_DEST_REG  = RD_RS_MRI;
282             LOAD_DEST_REG = 1'b1;
283
284             LOAD_ACCUM_REG = 1'b1;
285
286             N_STATE = ST_REFILL;
287         end
288
289
290         // Complete store operation
291         ST_STORE:
292         begin
293             SEL_SOURCE_REG2 = RD_RS_MRI;
294             ALU_CONTROL     = PASS_IN2;
295
296             SEL_ADDR  = 1'b1;
297             EN        = 1'b1;
298             MEM_WRITE = 1'b1;
299
300             N_STATE = ST_REFILL;
301         end
304         // Taken branch: update PC and remove sequential instruction
305         ST_BRANCH:
306         begin
307             SEL_SOURCE1 = 1'b0;
308
309             BRANCH_BASE_ADJUST  = 1'b1;
310             IMM_OFFSET_SELECTOR = 1'b1;
311             SEL_SOURCE2         = 1'b1;
312
313             ALU_CONTROL = ADD;
314             SEL_DATA    = 1'b1;
315             LOAD_PC     = 1'b1;
316
317             FLUSH_IR1 = 1'b1;
318
319             N_STATE = ST_FILL1;
320         end
321
322
323         // Resume normal execution after load or store
324         ST_REFILL:
325         begin
326             LOAD_IR2 = 1'b1;
327             LOAD_IR1 = 1'b1;
328             INC_PC   = 1'b1;
329
330             N_STATE = ST_EXEC;
331         end
334         default:
335         begin
336             N_STATE = ST_INIT;
337         end
338
339     endcase
340 end
341
342
343 always_ff @(posedge SYS_CLOCK or posedge FSM_ARESET)
344 begin : FSM_PRESENT_STATE_REGISTER
345
346     if (FSM_ARESET)
347         P_STATE <= ST_INIT;
348     else
349         P_STATE <= N_STATE;
350
351 end : FSM_PRESENT_STATE_REGISTER
352
353 endmodule : DORITO_FSM         
