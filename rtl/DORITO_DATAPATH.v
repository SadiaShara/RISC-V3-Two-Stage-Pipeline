 20 timeunit 1ns;
 21 timeprecision 1ps;
 22                                                                                                                          23 import DORITO_PKG::*;
 24
 25 module DORITO_DATAPATH
 26 (
 27     input logic SYS_CLOCK,
 28     input logic FSM_ARESET,
 29
 30     input logic [BUS_SIZE-1:0] MEM_DATA_OUT,
 31
 32     input logic SCLR_PC,
 33     input logic INC_PC,
 34     input logic LOAD_PC,
 35
 36     input logic LOAD_IR1,
 37     input logic LOAD_IR2,
 38     input logic FLUSH_IR1,
 39
 40     input logic [REG_ADDR_SIZE-1:0] SEL_SOURCE_REG1,
 41     input logic [REG_ADDR_SIZE-1:0] SEL_SOURCE_REG2,
 42     input logic [REG_ADDR_SIZE-1:0] SEL_DEST_REG,
 43
 44     input logic REG_FILE_ARESET,
 45     input logic LOAD_DEST_REG,
 46     input logic LOAD_ACCUM_REG,
 47
 48     input logic IMM_OFFSET_SELECTOR,
 49     input logic BRANCH_BASE_ADJUST,
    51     input logic [MNEMONIC_SIZE-1:0] ALU_CONTROL,
 52
 53     input logic SEL_SOURCE1,
 54     input logic SEL_SOURCE2,
 55     input logic SEL_DATA,
 56     input logic SEL_ADDR,
 57
 58     input logic LOAD_ADDR_REG,
 59     input logic EN,
 60
 61     output logic [BUS_SIZE-1:0] IR1_OUT,
 62     output logic [BUS_SIZE-1:0] IR_OUT,
 63     output logic [BUS_SIZE-1:0] ACCUM_REG,
 64
 65     output logic CARRYOUT,
 66     output logic U_OVF,
 67     output logic S_OVF,
 68     output logic ALU_OUT_ZERO,
 69     output logic ALU_OUT_POS,
 70     output logic ALU_OUT_NEG,
 71
 72     output logic signed [ADDR_SIZE-1:0] MEM_ADDRESS,
 73     output logic signed [ADDR_SIZE-1:0] PC_OUT,
 74
 75     output logic [BUS_SIZE-1:0] MEM_DATA_IN
 76 );
 77
 78
 79  logic [BUS_SIZE-1 : 0] INT_DATA_BUS, SOURCE_REG1, SOURCE_REG2, IMM_OFFSET_DATA,
 80 /*PC_OUT, ADDR_REG_OUT,*/ ALU_IN1, ALU_IN2, ALU_OUT;      
 81 //var logic signed [ADDR_SIZE-1 : 0] PC_OUT, ADDR_REG_OUT;
 82  logic signed [ADDR_SIZE-1 : 0] ADDR_REG_OUT; //CHANGE
 83 //MAKE PC_OUT & ADDR_REG_OUT 5 BIT (CAN POINT TO 32 LOCATIONS) FOR EASIER VERIFICATION.
 84 //var logic signed [BUS_SIZE-1 : 0] PC_OUT, ADDR_REG_OUT;
 85  logic [BUS_SIZE : 0] ALU_OUT_W_CARRY;
 86  logic [BUS_SIZE-1 : 0] R_FILE [REGISTER_NO-1 : 0];
 87  logic [REG_ADDR_SIZE-1:0] ACCUM_DEST_REG;
 88 logic ACCUM_VALID;
 89
 90 logic signed [ADDR_SIZE-1:0] BRANCH_PC_BASE;
 91
 92 assign BRANCH_PC_BASE = PC_OUT - 1'b1;
 93 always_ff @ (posedge SYS_CLOCK)
 94 begin : PC
 95 if (LOAD_PC)
 96 PC_OUT <= $signed(INT_DATA_BUS[4:0]);/*INT_DATA_BUS[4:0];*/
 97 //MAKE PC_OUT 5 BIT (CAN POINT TO 32 LOCATIONS) FOR EASIER VERIFICATION.
 98 else if (SCLR_PC)
 99 PC_OUT <= '0;
100 else if (INC_PC)
101 PC_OUT <= PC_OUT + 1'b1;
102 end : PC
103
104 // Stage 1 instruction register
105 always_ff @(posedge SYS_CLOCK or posedge FSM_ARESET)
106 begin : IR1_REGISTER
107     if (FSM_ARESET)
108         IR1_OUT <= '0;
109     else if (FLUSH_IR1)
110         IR1_OUT <= '0; 
111     else if (LOAD_IR1)
112         IR1_OUT <= MEM_DATA_OUT;
113 end : IR1_REGISTER
114
115
116 // Stage 2 instruction register
117 always_ff @(posedge SYS_CLOCK or posedge FSM_ARESET)
118 begin : IR2_REGISTER
119     if (FSM_ARESET)
120         IR_OUT <= '0;
121     else if (LOAD_IR2)
122         IR_OUT <= IR1_OUT;
123 end : IR2_REGISTER
124
125 always_ff @ (posedge SYS_CLOCK)
126 begin : REG_FILE
127 if (REG_FILE_ARESET)
128 begin
129 R_FILE <= '{default : '0};
130 end
131 else if (LOAD_DEST_REG)
132 R_FILE [SEL_DEST_REG] <= INT_DATA_BUS;
133 end : REG_FILE
134
135 // Forward the previous result when the next instruction needs it
136 assign SOURCE_REG1 =
137     (ACCUM_VALID &&
138      (SEL_SOURCE_REG1 == ACCUM_DEST_REG))
139     ? ACCUM_REG
140     : R_FILE[SEL_SOURCE_REG1];  
142 assign SOURCE_REG2 =
143     (ACCUM_VALID &&
144      (SEL_SOURCE_REG2 == ACCUM_DEST_REG))
145     ? ACCUM_REG
146     : R_FILE[SEL_SOURCE_REG2];
147
148 always_ff @(posedge SYS_CLOCK or posedge FSM_ARESET)
149 begin : ACC_REG
150     if (FSM_ARESET)
151     begin
152         ACCUM_REG      <= '0;
153         ACCUM_DEST_REG <= '0;
154         ACCUM_VALID    <= 1'b0;
155     end
156     else if (LOAD_ACCUM_REG)
157     begin
158         ACCUM_REG      <= INT_DATA_BUS;
159         ACCUM_DEST_REG <= SEL_DEST_REG;
160         ACCUM_VALID    <= 1'b1;
161     end
162 end : ACC_REG
163
164 always_comb
165 begin : IMMEDIATE_DATA_OFFSET_CONTROLLER
166 if (IMM_OFFSET_SELECTOR)
167 IMM_OFFSET_DATA = {'0,IR_OUT[11:0]};
168 else
169 //IMM_OFFSET_DATA = {{20{IR_OUT[11]}},IR_OUT[11:0]};
170 //IMM_OFFSET_DATA = {{27{IR_OUT[14]}},IR_OUT[4:0]};
171 IMM_OFFSET_DATA = {{27{IR_OUT[4]}},IR_OUT[4:0]};//CHANGE  
172 //TAKE LSB 5 BIT OF IMMEDIATE DATA (AS ADDRESS BUSSES HAS BEEN MADE 5BITS)
173 //RATHER THAN FULL 12 BITS AND THEN AND SIGN-EXTEND THEM TO 32 BITS
174
175 end : IMMEDIATE_DATA_OFFSET_CONTROLLER
176
177 always_ff @ (posedge SYS_CLOCK)
178 begin : ADDRESS_REG
179 if (REG_FILE_ARESET)
180 ADDR_REG_OUT <= '0;
181 else
182 if (LOAD_ADDR_REG)
183 ADDR_REG_OUT <= ALU_OUT[ADDR_SIZE-1:0]; /*ALU_OUT;*/
184 end : ADDRESS_REG
185
186 always_comb
187 begin : ALU
188 CARRYOUT = '0; U_OVF = '0; S_OVF = '0;
189 ALU_OUT_W_CARRY = '0;
190 case (ALU_CONTROL)
191
192 ADD                     : begin
193 ALU_OUT_W_CARRY = $signed(ALU_IN1) + $signed(ALU_IN2);
194 ALU_OUT = ALU_OUT_W_CARRY[BUS_SIZE-1 : 0];
195 CARRYOUT = ALU_OUT_W_CARRY[BUS_SIZE];
196 U_OVF = ALU_OUT_W_CARRY[BUS_SIZE];
197 S_OVF = ( ~(ALU_IN1[BUS_SIZE-1] ^ ALU_IN2[BUS_SIZE-1])
198 && (ALU_OUT[BUS_SIZE-1] ^ ALU_IN1[BUS_SIZE-1]) );
199 end
200 SUB                     : begin
201 ALU_OUT_W_CARRY = ALU_IN1 - ALU_IN2; 
202 ALU_OUT = ALU_OUT_W_CARRY[BUS_SIZE-1 : 0];
203 CARRYOUT = ALU_OUT_W_CARRY[BUS_SIZE];
204 U_OVF = ~ALU_OUT_W_CARRY[BUS_SIZE];
205 S_OVF = ( (ALU_IN1[BUS_SIZE-1] ^ ALU_IN2[BUS_SIZE-1])
206 && ~(ALU_OUT[BUS_SIZE-1] ^ ALU_IN2[BUS_SIZE-1]) );
207 end
208 INC_IN1                 : begin
209 ALU_OUT_W_CARRY = ALU_IN1 + 1'b1;
210 ALU_OUT = ALU_OUT_W_CARRY[BUS_SIZE-1 : 0];
211 CARRYOUT = ALU_OUT_W_CARRY[BUS_SIZE];
212 U_OVF = ALU_OUT_W_CARRY[BUS_SIZE];
213 end
214
215 INC_IN2                 : begin
216 ALU_OUT_W_CARRY = ALU_IN2 + 1'b1;
217 ALU_OUT = ALU_OUT_W_CARRY[BUS_SIZE-1 : 0];
218 CARRYOUT = ALU_OUT_W_CARRY[BUS_SIZE];
219 U_OVF = ALU_OUT_W_CARRY[BUS_SIZE];
220
221 end
222 PASS_0          : ALU_OUT = '0;
223 PASS_IN2        : ALU_OUT = ALU_IN2;
224 PASS_LOW16_IN2 : ALU_OUT = ALU_IN2[(BUS_SIZE/2)-1 :0];
225 PASS_HIGH16_IN2 : ALU_OUT = ALU_IN2[BUS_SIZE-1 : (BUS_SIZE/2)];
226 AND : ALU_OUT = ALU_IN1 & ALU_IN2;
227 OR  : ALU_OUT = ALU_IN1 | ALU_IN2;
228 XOR : ALU_OUT = ALU_IN1 ^ ALU_IN2;
229 NAND  : ALU_OUT = ~(ALU_IN1 & ALU_IN2);
230 NOR  : ALU_OUT = ~(ALU_IN1 | ALU_IN2);
231 XNOR : ALU_OUT = ~(ALU_IN1 ^ ALU_IN2);   
232 NOT_IN2 : ALU_OUT = ~ ALU_IN2;
233 L_SHIFT_IN2 : ALU_OUT = ALU_IN2 << 1;
234 R_SHIFT_IN2 : ALU_OUT = ALU_IN2 >> 1;
235 S_L_SHIFT_IN2 : ALU_OUT = ALU_IN2 <<< 1;
236 S_R_SHIFT_IN2  : ALU_OUT = ALU_IN2 >>> 1;
237 L_ROTATE_IN2 : ALU_OUT = {ALU_IN2[BUS_SIZE-2 : 0], ALU_IN2[BUS_SIZE-1]};
238 R_ROTATE_IN2    : ALU_OUT = {ALU_IN2[0],ALU_IN2[BUS_SIZE-1 : 1]};
239
240 default : ALU_OUT = 'x;
241
242 endcase
243
244 end : ALU
245
246 assign MEM_DATA_IN = ALU_OUT;
247 //assign MEM_DATA_IN = EN ? ALU_OUT : 'z;
248
249 assign ALU_OUT_ZERO = ALU_OUT == '0 ? '1 : '0;
250 //IF ALU_OUT IS '0, ALU_OUT_ZERO = '1;
251 assign ALU_OUT_POS = !ALU_OUT[BUS_SIZE-1] ? '1 : '0;
252 //IF MSB OF ALU_OUT IS '0, ALU_OUT_POS = '1;
253 assign ALU_OUT_NEG = ALU_OUT[BUS_SIZE-1] ? '1 : '0;
254 //IF MSB OF ALU_OUT IS '1, ALU_OUT_NEG = '1;
255
256 always_comb
257 begin : MUX_DATA
258
259 case (SEL_DATA)
260 1'b0 : INT_DATA_BUS = MEM_DATA_OUT;
261 1'b1 : INT_DATA_BUS = ALU_OUT;    
262 default : INT_DATA_BUS = 'x;
263 endcase
264
265 end     : MUX_DATA
266
267 always_comb
268 begin : MUX_SOURCE1
269 case (SEL_SOURCE1)
270 1'b0 : ALU_IN1 =
271     BRANCH_BASE_ADJUST
272     ? {{(BUS_SIZE-ADDR_SIZE){BRANCH_PC_BASE[ADDR_SIZE-1]}},
273        BRANCH_PC_BASE}
274     : {{(BUS_SIZE-ADDR_SIZE){PC_OUT[ADDR_SIZE-1]}},
275        PC_OUT};
276
277 1'b1 : ALU_IN1 = SOURCE_REG1;
278 default : ALU_IN1 = 'x;
279 endcase
280 end     : MUX_SOURCE1
281
282 always_comb
283 begin : MUX_SOURCE2
284
285 case (SEL_SOURCE2)
286 1'b0 : ALU_IN2 = SOURCE_REG2;
287 1'b1 : ALU_IN2 = IMM_OFFSET_DATA;
288 default : ALU_IN2 = 'x;
289 endcase
290
291 end     : MUX_SOURCE2  
293 always_comb
294 begin : MUX_ADDR
295
296 case (SEL_ADDR)
297 1'b0 : MEM_ADDRESS = PC_OUT;
298 1'b1 : MEM_ADDRESS = ADDR_REG_OUT;
299 default : MEM_ADDRESS = 'x;
300 endcase
301
302 end     : MUX_ADDR
303
304 //assign MEM_ADDRESS = ADDR_REG_OUT;
305
306 endmodule : DORITO_DATAPATH
