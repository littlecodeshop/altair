; 
;	8 0 8 0	M I L	M O N I T O R
; 
	ORG	0
; 
L0:	MVI	A,1	;IDLE TTY
	OUT	24Q
	JMP	LA0	;CONTINUE ELSEWHERE
	NOP
	PUSH	H	;SAVE H,L	RST 010-BRK PT EXEC
	LXI	H,LA023	;SET TO PRINT BUFFER(PB)
	MOV	M,A	;ACC TO PB
	JMP	L3160	;CONT ELSEWHERE
	CALL	L357	;SAVE	RST 020
	LHLD	LA100	;INDIRECT JUMP TO LOC POINTER
	PCHL	;BY CONTENT OF LA100,LA101
	NOP
	CALL	L357	;	RST 030
	LHLD	LA102	;IND. JMP POINTED BY
	PCHL	;LA102,LA103
	NOP
	CALL	L357	;	RST 040
	LHLD	LA104
	PCHL
	NOP
	CALL	L357	;	RST 050
	LHLD	LA106
	PCHL
	NOP
	CALL	L357	;	RST 060
	LHLD	LA110
	PCHL	
	NOP
	CALL	L357	;	RST 070
	LHLD	LA112
	PCHL
	NOP
LA0:	OUT	26Q	;DISABLE R.C., STOP PROGRAMMER
	LXI	H,LA100	;SET SP
	SPHL
	MVI	A,0	;CLEAR TTY I/O PRG.
	STA	LA010	;EXCEPTION FLAGS
	STA	LA011
	STA	LA016
	MVI	A,'-'	;O/P ------
	MVI	B,6
	CALL	L3260
	CALL	L1355	;CR/LF
L133:	CALL	L3277	;I/P NONBLANK, FIRST LETTER
	JZ	L133
	ANI	77Q	;MASK
	MOV	C,A	;STORE IN C
	CALL	L3277	;I/P ALPHABETIC, SECOND LETTER
	JNC	L6070
	ANI	77Q	;MASK
	MOV	D,A	;STORE IN D
	CALL	L3277	;I/P ALHPABETIC, THIRD LETTER
	JNC	L250
	ANI	77Q
	MOV	E,A	;STORE IN E
	CALL	L3277	;I/P ALPHABETIC, FOURTH LETTER
	JNC	L221
	CALL	L3277	;I/P NON-ALPHABETIC
	JC	L6070
	LXI	H,L3321	;SET H,L TO 4 LET. TABLE	4 LETTER
	MVI	B,13Q	;INSTR COUNT	DEC
L207:	CALL	L5166	;SWEEP 4 LETTER TABLE	CONTROLLER
	INX	H	;NO MATCH, GO TO NEXT
	JNZ	L207	;SET OF BYTES
	JMP	L6070	;END OF 4 LET TABLE, ERROR
L221:	LXI	H,L4111	;SET H,L TO BEG OF COMMAND TABLE
	MVI	B,16Q	;SET UP COUNT
L226:	CALL	L270	;CALL 3 LET MATCH
	INX	H	;IF NO MATCH GO TO NEXT BYTE
	JNZ	L226	;NOT END OF TABLE, TRY AGAIN
	MVI	B,65Q	;NOT COMMAND, SET COUNT TO 3 LET INST
L237:	CALL	L300	;CALL 3 LET INST MATCH
	JNZ	L237	;NOT END, TRY AGAIN
	JMP	L6070	;END OF TABLE, ERROR
L250:	LXI	H,L4010	;SET H,L TO 2 LET TABLE
	MVI	B,17Q	;SET UP COUNT
	MOV	E,D	;SHIFT
	MOV	D,C
L257:	CALL	L306	;CALL 2 LET MATCH
	JNZ	L257	;NO MATCH, TRY AGAIN
	JMP	L6070	;END OF TABLE, ERROR
L270:	CALL	L314	;CALL 3 LET MATCH	EXECUTE
	MOV	E,M	;MATCH FOUND, LOAD	GIVEN
	INX	H	;JUMP ADDR TO D,E	COMMAND
	MOV	D,M
	XCHG	;INDIRECT JUMP
	PCHL
L300:	CALL	L314	;CALL 3 LET MATCH
	JMP	L5143	;MATCH FOUND, CONT ELSEWHERE
L306:	CALL	L323	;2 LET MATCH
	JMP	L5175	;MATCH FOUND, CONT ELSEWHERE
L314:	CALL	L352	;MASK, INCREMENT H,L
	CMP	C	;THIRD LETTER EQUAL TO TAB?
	JNZ	L343	;NO, JUMP
L323:	CALL	L352	;YES, GO TO SECOND LETTER
	CMP	D	;SECOND LETTER EQUAL?
	JNZ	L344	;NO
	CALL	L352	;YES, GO TO FIRST LETTER
	CMP	E	;LAST LETTER EQUAL?
	JNZ	L345	;NO
	MOV	E,M	;YES, MOVE CODE TO E
	RET
L343:	INX	H
L344:	INX	H
L345:	INX	H
	INX	SP	;SET SP
	INX	SP
	DCR	B	;COUNT INSTR
	RET
L352:	MVI	A,77Q	;	MASK
	ANA	M	;	SUBROUTINE
	INX	H
	RET
L357:	SHLD	LA014	;SAVE H,L TEMPORARILY
	XTHL	;EXCH H,L AND TOP OF STACK
	PUSH	PSW	;SAVE REGISTERS
	PUSH	B
	PUSH	D
	PUSH	H
	LHLD	LA014	;RESTORE H,L
	RET
L373:	POP	H	;	RESTORE 
	POP	D	;	SUBROUTINE
	POP	B
	POP	PSW
	XTHL
	RET
LA01:	CALL	L357	;SAVE REG	I/P TTY
	LDA	LA010	;TTY I/P?	SUBR
	CPI	0
	JNZ	L0
	MVI	C,-9	;BIT COUNT
	INR	A	;ENABLE R.C.
	OUT	26Q
LA21:	IN	0	;WAIT FOR START PULSE
	RRC
	JNC	LA21
	MVI	A,0	;DISABLE R.C.
	OUT	26Q
	LXI	H,1040Q	;SET TIME CONSTANT (T.C.)
	CALL	L1117	;TIMEOUT 4.05 MSEC
	DAD	H	;DOUBLE T.C.
LA42:	IN	0	;I/P BIT
	CMA	
	OUT	24Q	;ECHO
	RAR	;ROTATE INTO POSITION
	MOV	A,B
	RAR
	MOV	B,A
	CALL	L1117	;TIMEOUT 9.1 MSEC
	INR	C	;COUNT BIT
	JNZ	LA42	;NOT LAST, LOOP
	MVI	A,1	;IDLE TTY
	OUT	24Q
	DAD	H	;DOUBLE TC
	CALL	L1117	;TIMEOUT 18.2 MSEC
	MOV	A,B	;MASK PARITY
	ANI	177Q
	STA	LA013	;PUT INTO TEMP STORE
	CALL	L373	;RESTORE REG
	LDA	LA013	;TEST FOR TAPE LEADER
	CPI	0
	JZ	LA01
	CPI	1	;TEST FOR CTRL A
	RNZ
	RST	0	;IF CTRL A, GO TO BEG OF MONITOR
L1117:	PUSH	H	;	TIMING
	INR	H	;	LOOP
L1121:	DCR	L
	JNZ	L1121
	DCR	H
	JNZ	L1121
	POP	H
	RET
L1133:	CALL	L357	;SAVE REG	TTY O/P
	MVI	C,-8	;COUNTER
	STA	LA013	;MOVE TO I/O BUFFER
	LDA	LA010	;TTY I/P TEST
	CPI	0
	JNZ	L0
	OUT	24Q	;START TTY
	LXI	H,1040Q	;SET TC
	DAD	H	;DOUBLE TC
	LDA	LA013	;RESTORE ACC
L1164:	CALL	L1117	;TIMEOUT 9.1 MSEC
	OUT	24Q	;O/P BIT
	RAR	;ROTATE
	INR	C	;COUNT
	JNZ	L1164	;CONTINUE OUTPUTTING
	CALL	L1117	;TIMEOUT 9.1 MSEC
	MVI	A,1	;IDLE TTY
	OUT	24Q	
	DAD	H	;TIMEOUT 18.2 MSEC
	CALL	L1117	
	CALL	L373	;RESTORE REG
	RET
L1215:	CALL	LA01	;	I/P WITH
L1220:	MOV	B,A	;	OCTAL TEST
	ANI	370Q	;	INTO B
	CPI	'0'
	RET
L1226:	CALL	LA01	;	I/P WITH
	CPI	177Q	;	RUBOUT
	RNZ	;	TEST
	MVI	A,'_'	;PRINT _
	JMP	L1133
L1241:	CALL	L357	;SAVE REG	I/P BYTE
L1244:	CALL	L1215	;I/P OCTAL	TO MEMORY
L1247:	JNZ	L1244
L1252:	MOV	A,B	;ROTATE, SAVE IN B
	RRC
	RRC
	ANI	300Q
	MOV	B,A
L1260:	CALL	L1226	;I/P ASCII WITH RUBOUT TEST
	JZ	L1244
	ANI	7	;MASK, ROTATE, SAVE IN C
	RLC
	RLC
	RLC
	MOV	C,A	
	CALL	L1226	;I/P ASCII WITH RUBOUT TEST
	JZ	L1260
	ANI	7	;MASK, COMBINE
	ORA	B
	ORA	C
	MOV	M,A	;MOVE TO MEMORY
	CALL	L373	;RESTORE REG
	RET
L1313:	PUSH	PSW	;	O/P BLANK
	MVI	A,' '
	CALL	L1133
	POP	PSW
	RET
L1323:	CALL	L1313	;O/P BLANK	O/P MEMORY
L1326:	MOV	A,M	;O/P FIRST DIGIT	BYTE
	RLC
	RLC
	ANI	3
	CALL	L1350
	MOV	A,M	;O/P SECOND DIGIT
	RRC
	RRC
	RRC
	CALL	L1346
	MOV	A,M	;O/P LAST DIGIT
L1346:	ANI	7
L1350:	ORI	'0'
	JMP	L1133
L1355:	PUSH	PSW	;	O/P CRLF
	MVI	A,15Q	;CR
	CALL	L1133
	MVI	A,12Q	;LF
	CALL	L1133
	POP	PSW
	RET
L1372:	PUSH	PSW	;	O/P /(SLASH)
	MVI	A,'/'
	CALL	L1133
	POP	PSW
	RET
LB02:	LHLD	LA000	;SET TO CLP	SET H,L TO CLP
	LDA	LA016	;TEST FOR PRG.
	CPI	1
	RNZ
	MOV	A,L	;YES, PRG SET TO PRG BUFFER
	LXI	H,LA007
	OUT	20Q	;O/P ADDRESS
	IN	2	;I/P BYTE
	MOV	M,A	;MOVE TO BUFFER
	RET
LB25:	CALL	LB02	;SET H,L TO CLP	O/P CLP
	LXI	H,LA001	;SET TO MS BYTE OF CLP
	JNZ	LB46	;NOT PRG, JUMP
	MVI	A,120Q	;O/P P (PROGRAMMER)
	CALL	L1133
	JMP	LB51
LB46:	CALL	L1323	;PRINT MS BYTE OF ADDRESS
LB51:	DCX	H
	JMP	L1326	;PRINT LS BYTE OF ADDRESS
LB55:	CALL	L1355	;	O/P CLP/
	CALL	LB25
	JMP	L1372
LB66:	CALL	LB02	;	O/P MEMORY AT CLP
	JMP	L1323
LB74:	LHLD	LA000	;	INCREMENT CLP
	INX	H
	SHLD	LA000
	JMP	LB02
LC06:	LHLD	LA000	;	DECREMENT CLP
	DCX	H
	SHLD	LA000
	JMP	LB02
LC20:	LHLD	LA000	;	COMPARE CLP
	XCHG	;	AND UPPER LIMIT
	LHLD	LA002
	MOV	A,D
	CMP	H
	RNZ
	MOV	A,E
	CMP	L
	RET
LC35:	CALL	LC20	;COMPARE CLP AND UL	RANGE CONTROL
	JNZ	LB74	;NOT ZERO, INCR CLP
	RST	0	;END OF PROGRAM, GO TO BEG
LC44:	CALL	L1355	;	O/P CLP*
	MVI	A,'*'
	CALL	L1133
LC54:	CALL	L1313	;O/P BLANK	I/P ADDR
	CALL	LA01	;I/P ASCII	TO MEMORY
	CPI	'P'	;=P?
	JZ	L2210	;YES, SET PRG FLAG
	LXI	B,L2204	;NO, SET UP NEXT ADDR-I/P MS BYTE
	PUSH	B
	CALL	L357	;SAVE REG
	CALL	L1220	;I/P OCTAL
	JMP	L1247
L2204:	DCX	H	;I/P BYTE TO MEM-I/P LS BYTE
	JMP	L1241
L2210:	MVI	A,1	;SET PROGRAMMER FLAG
	STA	LA016
	MOV	M,A	;STORE P
	JMP	L2204	;I/P WORD
L2221:	LXI	H,LA007	;I/P LOC WHERE PROG	I/P LIMITS
	CALL	LC44	;IS NOW
L2227:	LXI	H,LA005	;I/P NEW LOC
	CALL	LC44
L2235:	CALL	L2251	;O/P CRLF*, I/P NEW CLP
	LXI	H,LA003	;O/P BL, I/P UPPER L.
	CALL	LC54
	JMP	L1355	;O/P CRLF, RET
L2251:	LXI	H,LA001	;SET H,L TO CLP
	JMP	LC44	;O/P CRLF*,I/P CLP
DPO:	CALL	L2235	;I/P UPPER L., O/P CRLF
L2262:	MVI	C,8	;SET UP COUNT
	CALL	LB55	;O/P CLP/
	CALL	LB02	;SET H,L TO CLP
L2272:	CALL	L1323	;O/P MEMORY BYTE
	CALL	LC35	;INCR CLP
	DCR	C	;COUNT
	JNZ	L2272	;LOOP
	JMP	L2262	;NEW LINE
LDO:	CALL	L2235	;I/P CLP, UPPER L., O/P CRLF
L2312:	CALL	LA01	;I/P ASCII, TEST
	CPI	'/'	;WAIT FOR /
	JNZ	L2312	
	CALL	LB02	;SET H,L TO CLP
L2325:	CALL	LA01	;I/P ASCII, TEST
	CPI	15Q	;FOR CRLF
	JZ	L2312
	CALL	L1241	;I/P BYTE TO MEM
	CALL	LC35	;RANGE CONTROL (END?)
	JMP	L2325	;LOOP
EDT:	CALL	L2251	;I/P CLP	 OCTAL
L2351:	CALL	LB55	;O/P CLP	EDITOR
	CALL	LB02	;SET H,L TO CLP
	CALL	L2365	;PROCESS LINE
	JMP	L2351	;LOOP
L2365:	CALL	LA01	;I/P ASCII	EDITING
L2370:	CPI	'R'	;R?	ROUTINES
	JZ	L0	;YES, GO TO BEG
	CPI	'*'
	JZ	L2251	;YES, GO TO I/P CLP ROUTINE
	CPI	'@'
	JZ	L3073	;YES, GO TO XQT
	CPI	'^'	
	JZ	LC06	;YES, GO TO DECR CLP
	CPI	' '
	JZ	L3042	;YES, PRINT OCTAL BYTE
	CALL	L1220	;TEST FOR OCTAL
	RNZ	;NOT OCTAL
	LXI	D,L3037	;I/P BYTE TO MEM
	PUSH	D
	CALL	L357
	JMP	L1252
L3037:	JMP	L3045
L3042:	CALL	LB66	;O/P MEM AT CLP
L3045:	CALL	LA01	;I/P ASCII
	CPI	'_'	;BACK ARROW?
	JNZ	L3063	;NO, JUMP
	CALL	L1241	;YES, I/P ANOTHER BYTE
	JMP	L3045	;LOOP
L3063:	CPI	' '
	JZ	LB74	;YES, INCR CLP AND RET
	JMP	L2370	;NO, LOOP
XQT:
L3073:	CALL	L1355	;CRLF	XQT
	CALL	L2251	;I/P ADDRESS TO H,L
	LHLD	LA000
	PCHL	;INDIRECT JUMP
SBP:	CALL	L3135	;CLEAR BKPT	SET BREAKPOINT
	LXI	H,LA020	;SET H,L TO BKPT ADDR BUFFER
	CALL	LC44	;I/P BKPT ADDR TO MEMORY
	LHLD	LA017	;SAVE PROG BYTE
	MOV	A,M
	STA	LA021
	MVI	M,317Q	;INSERT RST 010 INTO PROG
	MVI	A,1	;SET BKPT FLAG
	STA	LA022
	RST	0
L3135:	LDA	LA022	;TEST FOR BKPT	CLEAR BKPT
	CPI	1
	RNZ
	LHLD	LA017	;LOAD H,L WITH BKPT ADDR
	LDA	LA021	;MOV PROG BYTE TO ACC
	MOV	M,A	;MOV BACK INTO PROG
	MVI	A,0	;CLEAR BKPT FLAG
	STA	LA022
	RET
L3160:	PUSH	PSW	;SAVE ACC, FLAGS	EXECUTE BKPT
	CALL	L1323	;O/P ACC
	MOV	M,B
	CALL	L1323	;O/P B
	MOV	M,C	
	CALL	L1323	;O/P C
	MOV	M,D	
	CALL	L1323	;O/P D
	MOV	M,E
	CALL	L1323	;O/P E
	POP	B	;RESTORE FLAGS, ACC	TO B,C
	POP	D	;RESTORE H,L TO D,E
	MOV	M,D
	CALL	L1323	;O/P H
	MOV	M,E
	CALL	L1323	;O/P L
	XCHG
	CALL	L1323	;O/P MEM
	MOV	A,C	;FLAGS TO ACC
	CALL	L3250	;O/P CARRY
	CALL	L3244	;O/P PARITY
	CALL	L3244	;O/P CY1 (CARRY BETWEEN D3,D4)
	CALL	L3244	;O/P ZERO
	MOV	A,C
	CALL	L3246	;O/P SIGN
	RST	0
L3244:	MOV	A,C	;	SHIFT AROUND
	RRC	;	FLAG BYTE
L3246:	RRC
	MOV	C,A
L3250:	ANI	1
	CALL	L1313
	JMP	L1346
L3260:	CALL	L1355	;CRLF	O/P WITH
L3263:	CALL	L1133	;O/P ASCII	COUNT LOOP
	DCR	B	;COUNT
	RZ
	JMP	L3263	;LOOP
CBP:	CALL	L3135	;CLEAR BKPT
	RST	0
L3277:	CALL	LA01	;I/P ASCII	I/P NUMERIC
	CPI	' '	;BLANK?	ALPHABETIC,BLANK
	PUSH	B	;SAVE B,C	TEST
	MOV	B,A
	RLC	;ROTATE MS BIT INTO CARRY
	RLC
	MOV	A,B
	POP	B	;RESTORE B,C
	RET
L3313:	MVI	A,77Q	;	ERROR,O/P ?
	CALL	L1133	;	AND RESTART
	RST	0
; 
L5143:	MOV	A,M	;RST?	 RST TEST FOR
	CPI	377Q	;	LOAD SYMBOLIC
	JNZ	L5174	;NO, GO TO ARG I/P
	LXI	H,LA024	;YES, SET H,L TO RST BUFFER
	CALL	L1241	;I/P
	MOV	A,M	;MASK INTO 377
	ORI	307Q
	MOV	E,A
	JMP	L5354	;CONTINUE IN ARG I/P
L5166:	CALL	L314	;CALL 3 LETTER MATCH	LOAD SYMB.
	INX	H	;LOAD MASKED INSTR	ROUTINES (CONT)
	MOV	E,M	;CODE INTO E
	DCX	H	;GO TO FIRST BYTE
L5174:	DCX	H
L5175:	DCX	H
	DCX	H
	MOV	A,M	;MASK, ROTATE, TO GET ARG BITS
	ANI	300Q
	RLC
	RLC
	INX	H	;GO TO SECOND BYTE
	JZ	L5302	;NO ARG, GO TO INP DATA
	DCR	A	;1 ARG DEST, GO TO I/P
	JZ	L5271	
	DCR	A	;2 ARG, GO TO I/P
	JZ	L5255
L5220:	CALL	L5371	;ASSUME 1 ARG SOURCE
	ANA	E	;MASK ARG INTO INSTR BYTE
	MOV	E,A
	JMP	L5274	;GO TO DATA I/P
L5230:	INX	H	;	DEST. SUBSTITUTE
	CALL	L5371	;I/P ARG
	MOV	B,A	;EXCEPTION TEST
	MOV	A,M
	ANI	100Q
	MOV	A,B
	JZ	L5246
	ORI	1
L5246:	RLC	;ROTATE MASK INTO BYTE
	RLC
	RLC
	ANA	E
	MOV	E,A
	DCX	H	;SET H,L TO BYTE WITH DATA CODE
	RET
L5255:	CALL	L5230	;I/P DEST ARG	I/P DEST,
L5260:	CALL	L3277	;WAIT FOR NON-ALPHABETIC	SOURCE ARG
	JC	L5260
	JMP	L5220	;I/P SOURCE
L5271:	CALL	L5230	;I/P DEST	I/P DEST ARG
L5274:	CALL	L3277	;WAIT FOR NON-ALPHABETIC
	JC	L5274
L5302:	MOV	A,M	;I/P BYTE WITH DATA CODE	I/P DATA
	LXI	H,LA023	;SET H,L TO DATA I/P BUFFER
	ANI	300Q	;MASK
	JZ	L5354	;NO DATA JUMP
	RLC	;1 DATA JUMP
	JNC	L5362
	CALL	L5335	;ASSUME 2 DATA BYTES
	MOV	M,D	;I/P MS BYTE
	CALL	LB74
L5326:	MOV	M,C	;I/P LS BYTE
	CALL	LB74
	JMP	L6041	;GO TO NEXT LINE
L5335:	CALL	L1241	;I/P BYTE TO BUFFER	2 DATA I/P
	MOV	C,M	;MOVE TO	C	SUBR
L5341:	CALL	L1241	;I/P BYTE TO D
	MOV	D,M
L5345:	CALL	LB02	;SET H,L TO CLP
	MOV	M,E	;MOVE INSTR BYTE TO MEM
	JMP	LB74	;INCR CLP, RET
L5354:	CALL	L5345	;NO DATA, MOVE INSTR
	JMP	L6041	;BYTE TO MEM, GO TO NEXT LINE
L5362:	CALL	L5341	;1 DATA BYTE
	MOV	C,D
	JMP	L5326
L5371:	CALL	L3277	;WAIT FOR	MATCH ARG
	JNC	L5371	;ALPHABETIC	LETTER
	PUSH	B	;SAVE B,C
	LXI	B,L4065	;SET TO ARG TABLE
	CALL	L6012	;SWEEP TABLE TO FIND CODE
	INX	B	;GO TO ARG CODE BYTE
	LDAX	B	;MOVE TO ACC
	POP	B	;RESTORE B,C
	RET
L6012:	PUSH	D	;SAVE D,E	SWEEP ARG
	MVI	E,10	;SET COUNT	TABLE SUBR
	MOV	D,A	;SAVE ACC IN D
L6016:	LDAX	B	;COMPARE BYTES
	CMP	D
	JNZ	L6025	;NO GOOD, JUMP
	POP	D	;FOUND, RESTORE D,E
	RET
L6025:	DCR	E
	JZ	L6067	;END OF TABLE, ERROR
	INX	B	;GO TO NEXT ARG
	INX	B
	JMP	L6016	;LOOP
LOC:	CALL	L2251	;LOC	PRINT CLP/
L6041:	CALL	L1355	;CRLF
	LXI	H,LA000	;O/P LS BYTE OF CLP AND /
	CALL	L1323
	CALL	L1372
	POP	PSW	;RESET STACK
	JMP	L133	;GO TO BEG OF LOAD SYMBOLIC
DLP:	CALL	LB25	;O/P CLP
	JMP	L6041
L6067:	POP	PSW	;RESET STACK	ERROR ROUTINE
L6070:	MVI	A,77Q	;O/P
	CALL	L1133
	JMP	L133	;GO TO BEG OF LOAD SYMBOLIC
DPS:	CALL	L2235	;I/P RANGE	DPS ROUTINE
L6103:	SUB	A	;CLEAR EXCEPTION FLAG	MAIN PROG
	STA	LA011
	CALL	LB55	;O/P CLP/
	CALL	LB66	;O/P MEM AT CLP
	CALL	L7062	;MATCH TEST PLUS RST TEST
	CALL	L7310	;EXCEPTION TEST
	CALL	L1313	;O/P BLANK
	MVI	B,6	;SET MNEMONIC FIELD
	CALL	L7010	;O/P MNEMONIC
	MVI	A,' '	;FINISH MNEM. FIELD
	CALL	L3263	;WITH BLANK
	MVI	B,3	;SET ARG FIELD
	CALL	L7107	;O/P ARG
	CALL	LC35	;PRINTING FINISHED? IF NO, INCR CLP
	LDA	LA026	;DATA BYTE TEST
	ANA	A
	JZ	L6103
	PUSH	PSW	;SAVE ACC	DATA O/P
	MVI	A,' '	;FINISH ARG FIELD
	CALL	L3263	;WITH BLANK
	POP	PSW	;RESTORE ACC
	DCR	A	;1,2 DATA BYTE TEST
	JZ	L6217
	CALL	LB74	;INCR CLP
	CALL	L1323	;O/P MEM AT CLP
	CALL	LC06	;DCR CLP
	CALL	L1326	;O/P MEM AT CLP
	CALL	LB74	;INCR CLP
L6211:	CALL	LC35	;FINISHED? INCR CLP
	JMP	L6103	;NEW LINE
L6217:	CALL	L1313	;O/P BLANK
	CALL	L1326	;O/P MEM AT CLP
	JMP	L6211	;NEW LINE
L6230:	LXI	D,L4010	;SET D,E TO BET FOR 2 BYTE TABLE	MATCH
	MVI	A,2	;SET TABLE FLAG (T.F.)	TEST
L6235:	STA	LA030
	MOV	B,A	;SAVE ACC
	CALL	L6333	;ARG TEST
	MOV	A,B	;RESTORE ACC
	ADD	E	;INCR D,E
	MOV	E,A
	JNC	L6253
	INR	D
L6253:	LDAX	D	;LOAD CODE INTO ACC
	CMP	C	;COMPARE WITH MEM
	RZ
	CALL	L6265	;END OF TABLE?
	MOV	A,B	;LOAD ACC WITH T.F.
	JMP	L6235	;LOOP
L6265:	CPI	363Q	;2 LETTER END	END OF TABLE TEST
	JZ	L6325
	CPI	351Q	;4 LETTER END
	JZ	L6320
	CPI	377Q	;3 LETTER END
	JZ	L6313
	CPI	343Q	;4 LETTER SECOND HALF
	JZ	L3313	;ERROR, CODE NOT FOUND
	INX	D
	RET
L6313:	INR	B	;SET T.F. TO 4
	LXI	D,L3321	;D,E TO BEGINNING OF 4 LET TABLE
	RET
L6320:	DCR	B	;SET T.F. TO 3
	LXI	D,L4217	;SET D,E TO BEG OF 3 LET TABLE
	RET
L6325:	INR	B	;SET T.F. TO 4
	INR	B
	LXI	D,L3376	;SET D,E TO SEC HALF OF 4 LET TABLE
	RET
L6333:	LDAX	D	;1 LET TO ACC	ARG TEST
	RLC	;ARG FLAG
	RLC	;INTO LA027
	ANI	3
	STA	LA027
	JNZ	L6350
	MOV	C,M	;NO ARG, C HOLDS INSTR
	RET
L6350:	DCR	A	;1 OR 2 ARG
	JNZ	L6361
	MOV	A,M	;1 ARG DEST
	ORI	70Q	;MODIFY INSTR
	MOV	C,A
	RET
L6361:	DCR	A	;2 ARG OR 1 ARG SOURCE
	JNZ	L6372
	MOV	A,M	;2 ARG; MODIFY INSTR
	ORI	77Q
	MOV	C,A
	RET
L6372:	MOV	A,M	;1 ARG SOURCE
	ORI	7
	MOV	C,A
	RET
L6377:	LDA	LA030	;T.F. TO ACC	GO TO 1 LET SUBR
L7002:	DCX	D	;LOOP UNTIL D,E
	DCR	A	;POINT TO 1 LETTER
	JNZ	L7002
	RET
L7010:	CALL	L6377	;GO TO FIRST LETTER	PRINT
	LDA	LA030	;T.F. TO C	MNEM. FIELD
	MOV	C,A
	CALL	L7050	;PRINT FIRST LETTER
	INX	D	;SET CONDITION FOR SECOND LETTER
	DCR	C
	LDAX	D	;GENERATE DATA FLAG
	ANI	300Q	;AND STORE AT LA026
	RLC
	RLC
	STA	LA026
	CALL	L7050	;PRINT SECOND LETTER
L7037:	DCR	C	;END?
	RZ
	INX	D	;NO, PRINT THE REST
	CALL	L7050
	JMP	L7037
L7050:	LDAX	D	;LOAD LET TO ACC	PRINT ROUT
	ANI	77Q	;CONVERT TO ASCII
	ORI	100Q
L7055:	CALL	L1133	;O/P
	DCR	B	;FIELD COUNT
	RET
L7062:	MOV	A,M	;CHECK	RST TEST
	ANI	307Q	;FOR RST
	CPI	307Q
	JNZ	L6230	;NO
	LXI	D,L5142	;YES, SET D,E AND TF
	MVI	A,3
	STA	LA030
	RAR	;SET ARG FLAG
	STA	LA027
	RET
L7107:	LDA	LA027	;TEST FOR ARG	PRINT ARG
	ANA	A
	RZ	;NO
	DCR	A	;1 ARG DEST
	JZ	L7144
	DCR	A	;2 ARG
	JZ	L7243
L7124:	MOV	A,M	;ASSUME 1 ARG SOURCE
	ORI	370Q
L7127:	PUSH	B	;SAVE B,C
	LXI	B,L4066	;B,C POINT TO BEG OF ARG TABLE
	CALL	L6012	;SWEEP ARG TABLE
	DCX	B	;LOAD ACC WITH LETTER IN ARG TABLE
	LDAX	B
	POP	B	;RESTORE B,C
	JMP	L7055	;PRINT CONTENTS OF ACC
L7144:	MOV	A,M	;1 ARG DEST
	ANI	307Q	;RST?
	CPI	307Q
	JNZ	L7176	;NO
	MVI	A,' '	;YES, FINISH ARG FIELD
	MVI	B,4	;WITH BLANK
	CALL	L3263
	MOV	A,M	;INSTR INTO ACC
	ANI	70Q	;CONVERT TO OCTAL AND
	LXI	H,LA027	;SEND TO MEM
	MOV	M,A
	CALL	L1326	;PRINT OCTAL BYTE
	RET
L7176:	MOV	A,M	;SP TEST
	ANI	365Q
	CPI	61Q
	JZ	L7255	;PRINT SP
	ANI	361Q	;PSW TEST
	CPI	361Q	
	JZ	L7270	;PRINT PSW
	MOV	C,M	;EXCEPTION TEST
	LDA	LA011
	CPI	367Q
	JNZ	L7230	;NO EXCEPTION
	ANA	C	;YES, EXCEPT DECR ARG CODE BY 1
	MOV	C,A
L7230:	MVI	A,70Q	;GENERATE ARG CODE
	ANA	C
	RRC
	RRC
	RRC
	ORI	370Q
	JMP	L7127	;GO TO PRINT
L7243:	CALL	L7176	;DEST	2 ARG PRINT
	CALL	L1313	;PRINT BLANK
	DCR	B	;FIELD COUNT
	JMP	L7124	;SOURCE
L7255:	MVI	A,'S'	;	PRINT "SP"
	CALL	L1133
	MVI	A,'P'
	CALL	L1133
	RET
L7270:	MVI	A,'P'	;	PRINT "PSW"
	CALL	L1133
	MVI	A,'S'
	CALL	L1133
	MVI	A,'W'
	CALL	L1133
	RET
L7310:	ADI	305Q	;EXCEPT	EXCEPTION TEST
	JZ	L7325	;SUSPECT
	INR	A
	JZ	L7325
	INR	A
	JNZ	L7350	;NO EXCEPT. HALT TEST
L7325:	MOV	A,M	;NO EXCEPT
	CPI	72Q
	RZ
	ANI	10Q	;NO EXCEPT
	RZ
	MVI	A,367Q	;YES,EXCEPT.
	STA	LA011	;SET EXECPT. FLAG
L7341:	LDA	LA030	;INCR D,E TO
	ADD	E	;NEXT INSTR IN TABLE
	MOV	E,A
	INX	D
	RET
L7350:	MOV	A,M	;HLT TEST
	CPI	166Q
	RNZ
	SUB	A	;HLT, SET ARG FLAG
	STA	LA027	;AND INCR D,E TO NEXT INSTR
	JMP	L7341
; 
LB000:	CALL	L2227	;FORMAT	CPY ROUT
	LDA	LA016	;PROGRAMMER?
	CPI	1
	JNZ	LB051	;NO
	LDA	LA000	;YES, LOWER LIMIT TO ACC
	MOV	D,A	;L.L TO D
	LDA	LA002	;UPPER LIMIT TO ACC
	SUB	D	;UL-LL TO ACC
	MOV	C,A	;(UL-LL) TO C
	LHLD	LA004	;NEW RANGE TO H,L
LB027:	MOV	A,D	;LL TO ACC
	OUT	20Q	;DATA TO ACC
	IN	2
	MOV	M,A	;DATA TO MEM
	INX	H	;INCR H,L
	INR	D	;LL=LL+1
	DCR	C	;COUNT
	MVI	A,377Q	;TEST
	CMP	C
	JZ	L0	;FINISHED
	JMP	LB027	;REPEAT
LB051:	LHLD	LA004	;NO PRG, NEW RANGE TO H,L
	LDA	LA000	;(LL-NR) TO B,C
	SUB	L
	MOV	C,A
	LDA	LA001
	SBB	H
	MOV	B,A
	RET
LB067:	JNC	LB104	;(LL-NR) > 0?
	MOV	A,C	;MOVES UP; TWO'S COMPL OF (LL-NR)
	CMA
	MOV	C,A
	MOV	A,B
	CMA
	MOV	B,A
	INX	B
	JMP	LB146
LB104:	LXI	H,LA000	;MOVES DOWN
	MOV	A,M	;SUBTRACT (LL-NR) FROM LL
	SUB	C
	MOV	E,A
	INR	L
	MOV	A,M
	SBB	B
	MOV	D,A
	LHLD	LA000	;COPY DATA
LB121:	MOV	A,M	;TO NEW LOCATION
	STAX	D
	INX	H
	INX	D
	LDA	LA002
	CMP	L
	JNZ	LB121
	MOV	A,M
	STAX	D
	LDA	LA003
	CMP	H
	JNZ	LB121
	RET
LB146:	LXI	H,LA002	;MOVES UP; (LL-NR) PLUS
	MOV	A,M	;UL INTO D,E
	ADD	C
	MOV	E,A
	INR	L
	MOV	A,M
	ADC	B
	MOV	D,A
	LHLD	LA002	;COPY DATA TO NEW LOC
LB163:	MOV	A,M
	STAX	D
	DCX	H
	DCX	D
	LDA	LA000
	CMP	L
	JNZ	LB163
	MOV	A,M
	STAX	D
	LDA	LA001
	CMP	H
	JNZ	LB163
	RET
CPY:	CALL	LB000	;CPY ROUTINE STARTS HERE
	CALL	LB067
	RST	0
; 
;	TABLE CONTAINING CODES FOR
;	SHLD LHLD STA LDA LXI
; 
LB217:	DB	042Q,052Q,062Q,072Q,071Q
; 
LB224:	LHLD	LA000	;LL INTO H,L
	CALL	LB246	;CALCULATION
	RM
	LHLD	LA002	;UL INTO H,L
	CALL	LB246	;CALCULATION
	RP
	POP	H	;MOVE UP STACK
	JMP	LC024	;CHANGE THE ADDRESS
LB246:	XCHG	;CALCULATE; SUBTRACT LL, UL
	LHLD	LA023	;FROM JMP ADDRESS
	INX	H
	MOV	A,M
	SUB	E
	INX	H
	MOV	A,M
	SBB	D
	RET
LB261:	LHLD	LA012	;MMM PLUS (UL-LL)	END
	XCHG	;INTO D,E	OF PROG?
	LHLD	LA023	;POINTER INTO H,L
	MOV	A,L	;POINTER-[MMM-(UL-LL)]>0?
	SUB	E
	MOV	A,H
	SBB	D
	RET
TRN:	CALL	L2221	;TRN ROUTINE STARTS HERE	TRN ROUT
	CALL	LB051	;UP OR DOWN?
	JNC	LB324	;MOVES UP
	MOV	A,C	;TWO'S COMPL OF LL-NR
	CMA
	MOV	C,A
	MOV	A,B
	CMA
	MOV	B,A
	INX	B
	SUB	A	;MOVES UP FLAG
	STA	LA014
	JMP	LB331
LB324:	MVI	A,1	;MOVES DOWN
	STA	LA014
LB331:	CALL	LC103	;CALCULATE MMM + (UL-LL)
LB334:	SHLD	LA023	;POINTER INTO H,L
	PUSH	B	;SAVE B
	CALL	L6230	;MATCH ROUT
	CALL	L7310	;EXCEPTION ROUT
	POP	B
	LDAX	D	;CODE TO LA016
	STA	LA016
	CALL	L6377	;FIRST LETTER SUBR
	INR	E	;SECOND LETTER
	LDAX	D	;DATA BYTE TEST
	MVI	E,300Q
	ANA	E
	CPI	0	;NO DATA BYTE
	JZ	LC100
	CPI	100Q	;1 DATA BYTE
	JZ	LC077
	LDA	LA016	;ASSUME 2 DATA BYTES
	LXI	H,LB217	;IS IT SHLD,LHLD,STA,LDA,LXI?
	MVI	E,5
LC005:	CMP	M
	JZ	LC073	;YES, NO CHANGE
	INR	L
	DCR	E
	JNZ	LC005
	CALL	LB224	;OUT OF RANGE?
	JMP	LC073	;YES, NO CHANGE
LC024:	LHLD	LA023	;CHANGE
	INX	H
	LDA	LA014	;MOVES DOWN?
	ANA	A
	JNZ	LC061
	MOV	A,M	;MOVES UP; ADD(LL-NR)
	ADD	C	;TO ADDR OF JUMP
	MOV	M,A
	INX	H
	MOV	A,M
	ADC	B
	MOV	M,A
LC046:	INX	H
	SHLD	LA023	;INCREMENTED POINTER TO LA023
	CALL	LB261	;END OF PROG?
	JM	LB334	;NO, NEW LINE
	RST	0
LC061:	MOV	A,M	;MOVES DOWN; SUBTRACT
	SUB	C	;(LL-NR) FROM ADDR
	MOV	M,A
	INX	H
	MOV	A,M
	SBB	B
	MOV	M,A
	JMP	LC046	;NEW LINE
LC073:	LHLD	LA023	;NO CHANGE
	INX	H
LC077:	INX	H
LC100:	JMP	LC046
LC103:	PUSH	B	;SAVE B,C
	LHLD	LA002	;UL-LL
	XCHG
	LHLD	LA000
	MOV	A,E
	SUB	L
	MOV	E,A
	MOV	A,D
	SBB	H
	MOV	D,A
	LHLD	LA006	;MMM PLUS (UL-LL)
	MOV	A,E
	ADD	L
	MOV	L,A
	MOV	A,D
	ADC	H
	MOV	H,A
	SHLD	LA012
	LHLD	LA006
	POP	B	;RESTORE B,C
	RET
PRG:	CALL	L2235	;I/P LL, UL	PRG ROUTINE
	CALL	L1355	;CRLF
	MVI	A,'%'	;O/P %
	CALL	L1133
	CALL	LA01	;I/P LETTER
	RLC
	RLC
	MOV	E,A
	LHLD	LA000	;LL INTO H,L
LC166:	MOV	A,L	;COMPARE ROM WITH MEM
	OUT	20Q
	IN	2
	CMP	M
	CNZ	LC225	;PROGR IF NOT EQUAL
	LDA	LA002	;END OF PROGRAM?
	CMP	L
	JNZ	LC221
	LDA	LA003
	CMP	H
	JNZ	LC221
	CALL	LC225	;YES, PROGR LAST
	RST	0
LC221:	INX	H	;NEW BYTE
	JMP	LC166
LC225:	MVI	B,1	;PROGR 4 TIMES LONGER
	CALL	LC252
	MOV	A,B
	RLC
	RLC
	MOV	B,A
LC236:	CALL	LC252
	DCR	B
	JNZ	LC236
	MOV	A,B	;OUTPUT NULL CHAR
	CALL	L1133
	RET
LC252:	MOV	A,M	;PROGRAM UNTIL ROM
	CMA	;BYTE HOLDS DESIRED
	OUT	22Q	;DATA; MAX 255 PULSES
	MVI	A,4
	OUT	26Q
	XRA	A
	OUT	26Q
	MOV	C,E
LC266:	MVI	D,350Q
LC270:	DCR	D
	JNZ	LC270
	DCR	C
	JNZ	LC266
	IN	2
	CMP	M
	RZ
	INR	B
	JNZ	LC252
	CALL	LB25
	MVI	A,77Q
	CALL	L1133
	RST	0
; 
L3321:	DB	003Q,201Q,214Q,014Q,315Q,120Q,025Q,223Q
	DB	010Q,375Q,030Q,003Q,210Q,007Q,353Q,023Q
	DB	210Q,214Q,004Q,042Q,014Q,210Q,214Q,004Q
	DB	052Q,123Q,024Q,201Q,030Q,072Q,114Q,004Q
	DB	301Q,030Q,072Q,030Q,003Q,210Q,007Q,353Q
	DB	030Q,024Q,210Q,014Q,343Q
L3376:	DB	023Q,020Q,210Q
	DB	014Q,371Q,020Q,003Q,210Q,014Q,351Q
L4010:	DB	012Q
	DB	203Q,332Q,012Q,232Q,312Q,012Q,220Q,362Q
	DB	012Q,215Q,372Q,003Q,203Q,334Q,003Q,232Q
	DB	314Q,003Q,220Q,364Q,003Q,215Q,374Q,022Q
	DB	003Q,330Q,022Q,032Q,310Q,022Q,020Q,360Q
	DB	022Q,015Q,370Q,011Q,116Q,333Q,005Q,011Q
	DB	373Q,004Q,011Q,363Q
L4065:	DB	102Q
L4066:	DB	370Q,103Q,371Q
	DB	104Q,372Q,105Q,373Q,110Q,374Q,114Q,375Q
	DB	115Q,376Q,123Q,376Q,120Q,376Q,101Q,377Q
L4111:
	DB	'XQT'
	DW	XQT
	DB	'LOC'
	DW	LOC
	DB	'DPO'
	DW	DPO
	DB	'LDO'
	DW	LDO
	DB	'DLP'
	DW	DLP
	DB	'EDT'
	DW	EDT
	DB	'SBP'
	DW	SBP
	DB	'CBP'
	DW	CBP
	DB	'DPS'
	DW	DPS
	DB	'CPY'
	DW	CPY
	DB	'TRN'
	DW	TRN
	DB	'PRG'
	DW	PRG
	DB	0,0,0
	DW	0
	DB	0,0,0
	DW	0
L4217:	DB	003Q,015Q
	DB	003Q,077Q,215Q,017Q,026Q,177Q,010Q,014Q
	DB	024Q,166Q,115Q,126Q,011Q,076Q,111Q,016Q
	DB	022Q,074Q,104Q,003Q,022Q,075Q,301Q,004Q
	DB	004Q,207Q,301Q,004Q,003Q,217Q,323Q,025Q
	DB	002Q,227Q,323Q,002Q,002Q,237Q,301Q,016Q
	DB	001Q,247Q,330Q,022Q,001Q,257Q,317Q,022Q
	DB	001Q,267Q,303Q,015Q,020Q,277Q,001Q,104Q
	DB	011Q,306Q,001Q,103Q,011Q,316Q,023Q,125Q
	DB	011Q,326Q,023Q,102Q,011Q,336Q,001Q,116Q
	DB	011Q,346Q,030Q,122Q,011Q,356Q,017Q,122Q
	DB	011Q,366Q,003Q,120Q,011Q,376Q,022Q,014Q
	DB	003Q,007Q,022Q,022Q,003Q,017Q,022Q,001Q
	DB	014Q,027Q,022Q,001Q,022Q,037Q,012Q,215Q
	DB	020Q,303Q,012Q,216Q,003Q,322Q,012Q,216Q
	DB	032Q,302Q,012Q,220Q,005Q,352Q,012Q,220Q
	DB	017Q,342Q,003Q,216Q,003Q,324Q,003Q,216Q
	DB	032Q,304Q,003Q,220Q,005Q,354Q,003Q,220Q
	DB	017Q,344Q,022Q,005Q,024Q,311Q,022Q,016Q
	DB	003Q,320Q,022Q,016Q,032Q,300Q,022Q,020Q
	DB	005Q,350Q,022Q,020Q,017Q,340Q,017Q,125Q
	DB	024Q,323Q,014Q,204Q,001Q,072Q,120Q,017Q
	DB	020Q,371Q,023Q,224Q,001Q,062Q,114Q,230Q
	DB	011Q,071Q,104Q,001Q,104Q,071Q,111Q,016Q
	DB	030Q,073Q,104Q,003Q,130Q,073Q,003Q,015Q
	DB	001Q,057Q,023Q,024Q,003Q,067Q,004Q,001Q
	DB	001Q,047Q,016Q,017Q,020Q,000Q,122Q,023Q
	DB	024Q
L5142:	DB	377Q
; 
; 
LA000:	DS	1
LA001:	DS	1
LA002:	DS	1
LA003:	DS	1
LA004:	DS	1
LA005:	DS	1
LA006:	DS	1
LA007:	DS	1
LA010:	DS	1
LA011:	DS	1
LA012:	DS	1
LA013:	DS	1
LA014:	DS	2
LA016:	DS	1
LA017:	DS	1
LA020:	DS	1
LA021:	DS	1
LA022:	DS	1
LA023:	DS	1
LA024:	DS	2
LA026:	DS	1
LA027:	DS	1
LA030:	DS	50Q
LA100:	DS	2
LA102:	DS	2
LA104:	DS	2
LA106:	DS	2
LA110:	DS	2
LA112:	DS	2
	END
