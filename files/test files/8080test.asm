;***********************************************************************
; MICROCOSM ASSOCIATES  8080/8085 CPU DIAGNOSTIC VERSION 1.0  (C) 1980
;***********************************************************************
;
;DONATED TO THE "SIG/M" CP/M USER'S GROUP BY:
;KELLY SMITH, MICROCOSM ASSOCIATES
;3055 WACO AVENUE
;SIMI VALLEY, CALIFORNIA, 93065
;(805) 527-9321 (MODEM, CP/M-NET (TM))
;(805) 527-0518 (VERBAL)
;
;***********************************************************************
; Modified 2001/02/28 by Richard Cini for use in the Altair32 Emulator
;	Project
;
; Need to somehow connect this code to Windows so that failure messages
;	can be posted to Windows. Maybe just store error code in
;	Mem[0xffff]. Maybe trap NOP in the emulator code?
;
;***********************************************************************

	.ORG $0	; start at bottom of RAM

;************************************************************
;                8080/8085 CPU TEST/DIAGNOSTIC
;************************************************************
;
;NOTE: (1) PROGRAM ASSUMES "CALL",AND "LXI SP" INSTRUCTIONS WORK!
;
;      (2) INSTRUCTIONS NOT TESTED ARE "HLT","DI","EI",
;          AND "RST 0" THRU "RST 7"
;
;
;
;TEST JUMP INSTRUCTIONS AND FLAGS
;
CPU:	LXI	SP,STACK	;SET THE STACK POINTER
	ANI	0	;INITIALIZE A REG. AND CLEAR ALL FLAGS
	JZ	J010	;TEST "JZ"
	CALL	CPUER
J010:	JNC	J020	;TEST "JNC"
	CALL	CPUER
J020:	JPE	J030	;TEST "JPE"
	CALL	CPUER
J030:	JP	J040	;TEST "JP"
	CALL	CPUER
J040:	JNZ	J050	;TEST "JNZ"
	JC	J050	;TEST "JC"
	JPO	J050	;TEST "JPO"
	JM	J050	;TEST "JM"
	JMP	J060	;TEST "JMP" (IT'S A LITTLE LATE,BUT WHAT THE HELL!
J050:	CALL	CPUER
J060:	ADI	6	;A=6,C=0,P=1,S=0,Z=0
	JNZ	J070	;TEST "JNZ"
	CALL	CPUER
J070:	JC	J080	;TEST "JC"
	JPO	J080	;TEST "JPO"
	JP	J090	;TEST "JP"
J080:	CALL	CPUER
J090:	ADI	$070	;A=76H,C=0,P=0,S=0,Z=0
	JPO	J100	;TEST "JPO"
	CALL	CPUER
J100:	JM	J110	;TEST "JM"
	JZ	J110	;TEST "JZ"
	JNC	J120	;TEST "JNC"
J110:	CALL	CPUER
J120:	ADI	$081	;A=F7H,C=0,P=0,S=1,Z=0
	JM	J130	;TEST "JM"
	CALL	CPUER
J130:	JZ	J140	;TEST "JZ"
	JC	J140	;TEST "JC"
	JPO	J150	;TEST "JPO"
J140:	CALL	CPUER
J150:	ADI	$0FE	;A=F5H,C=1,P=1,S=1,Z=0
	JC	J160	;TEST "JC"
	CALL	CPUER
J160:	JZ	J170	;TEST "JZ"
	JPO	J170	;TEST "JPO"
	JM	AIMM	;TEST "JM"
J170:	CALL	CPUER
;
;
;
;TEST ACCUMULATOR IMMEDIATE INSTRUCTIONS
;
AIMM:	CPI	0	;A=F5H,C=0,Z=0
	JC	CPIE	;TEST "CPI" FOR RE-SET CARRY
	JZ	CPIE	;TEST "CPI" FOR RE-SET ZERO
	CPI	$0F5	;A=F5H,C=0,Z=1
	JC	CPIE	;TEST "CPI" FOR RE-SET CARRY ("ADI")
	JNZ	CPIE	;TEST "CPI" FOR RE-SET ZERO
	CPI	$0FF	;A=F5H,C=1,Z=0
	JZ	CPIE	;TEST "CPI" FOR RE-SET ZERO
	JC	ACII	;TEST "CPI" FOR SET CARRY
CPIE:	CALL	CPUER
ACII:	ACI	$00A	;A=F5H+0AH+CARRY(1)=0,C=1
	ACI	$00A	;A=0+0AH+CARRY(0)=0BH,C=0
	CPI	$00B
	JZ	SUII	;TEST "ACI"
	CALL	CPUER
SUII:	SUI	$00C	;A=FFH,C=0
	SUI	$00F	;A=F0H,C=1
	CPI	$0F0
	JZ	SBII	;TEST "SUI"
	CALL	CPUER
SBII:	SBI	$0F1	;A=F0H-0F1H-CARRY(0)=FFH,C=1
	SBI	$00E	;A=FFH-OEH-CARRY(1)=F0H,C=0
	CPI	$0F0
	JZ	ANII	;TEST "SBI"
	CALL	CPUER
ANII:	ANI	$055	;A=F0H<AND>55H=50H,C=0,P=1,S=0,Z=0
	CPI	$050
	JZ	ORII	;TEST "ANI"
	CALL	CPUER
ORII:	ORI	$03A	;A=50H<OR>3AH=7AH,C=0,P=0,S=0,Z=0
	CPI	$07A
	JZ	XRII	;TEST "ORI"
	CALL	CPUER
XRII:	XRI	$00F	;A=7AH<XOR>0FH=75H,C=0,P=0,S=0,Z=0
	CPI	$075
	JZ	C010	;TEST "XRI"
	CALL	CPUER
;
;
;
;TEST CALLS AND RETURNS
;
C010:	ANI	$0	;A=0,C=0,P=1,S=0,Z=1
	CC	CPUER	;TEST "CC"
	CPO	CPUER	;TEST "CPO"
	CM	CPUER	;TEST "CM"
	CNZ	CPUER	;TEST "CNZ"
	CPI	$0
	JZ	C020	;A=0,C=0,P=0,S=0,Z=1
	CALL	CPUER
C020:	SUI	$077	;A=89H,C=1,P=0,S=1,Z=0
	CNC	CPUER	;TEST "CNC"
	CPE	CPUER	;TEST "CPE"
	CP	CPUER	;TEST "CP"
	CZ	CPUER	;TEST "CZ"
	CPI	$089
	JZ	C030	;TEST FOR "CALLS" TAKING BRANCH
	CALL	CPUER
C030:	ANI	$0FF	;SET FLAGS BACK!
	CPO	CPOI	;TEST "CPO"
	CPI	$0D9
	JZ	MOVI	;TEST "CALL" SEQUENCE SUCCESS
	CALL	CPUER
CPOI:	RPE		;TEST "RPE"
	ADI	$010	;A=99H,C=0,P=0,S=1,Z=0
	CPE	CPEI	;TEST "CPE"
	ADI	$002	;A=D9H,C=0,P=0,S=1,Z=0
	RPO		;TEST "RPO"
	CALL	CPUER
CPEI:	RPO		;TEST "RPO"
	ADI	$020	;A=B9H,C=0,P=0,S=1,Z=0
	CM	CMI	;TEST "CM"
	ADI	$004	;A=D7H,C=0,P=1,S=1,Z=0
	RPE		;TEST "RPE"
	CALL	CPUER
CMI:	RP		;TEST "RP"
	ADI	$080	;A=39H,C=1,P=1,S=0,Z=0
	CP	TCPI	;TEST "CP"
	ADI	$080	;A=D3H,C=0,P=0,S=1,Z=0
	RM		;TEST "RM"
	CALL	CPUER
TCPI:	RM		;TEST "RM"
	ADI	$040	;A=79H,C=0,P=0,S=0,Z=0
	CNC	CNCI	;TEST "CNC"
	ADI	$040	;A=53H,C=0,P=1,S=0,Z=0
	RP		;TEST "RP"
	CALL	CPUER
CNCI:	RC		;TEST "RC"
	ADI	$08F	;A=08H,C=1,P=0,S=0,Z=0
	CC	CCI	;TEST "CC"
	SUI	$002	;A=13H,C=0,P=0,S=0,Z=0
	RNC		;TEST "RNC"
	CALL	CPUER
CCI:	RNC		;TEST "RNC"
	ADI	$0F7	;A=FFH,C=0,P=1,S=1,Z=0
	CNZ	CNZI	;TEST "CNZ"
	ADI	$0FE	;A=15H,C=1,P=0,S=0,Z=0
	RC		;TEST "RC"
	CALL	CPUER
CNZI:	RZ		;TEST "RZ"
	ADI	$001	;A=00H,C=1,P=1,S=0,Z=1
	CZ	CZI	;TEST "CZ"
	ADI	$0D0	;A=17H,C=1,P=1,S=0,Z=0
	RNZ		;TEST "RNZ"
	CALL	CPUER
CZI:	RNZ		;TEST "RNZ"
	ADI	$047	;A=47H,C=0,P=1,S=0,Z=0
	CPI	$047	;A=47H,C=0,P=1,S=0,Z=1
	RZ		;TEST "RZ"
	CALL	CPUER
;
;
;
;TEST "MOV","INR",AND "DCR" INSTRUCTIONS
;
MOVI:	MVI	A,$077
	INR	A
	MOV	B,A
	INR	B
	MOV	C,B
	DCR	C
	MOV	D,C
	MOV	E,D
	MOV	H,E
	MOV	L,H
	MOV	A,L	;TEST "MOV" A,L,H,E,D,C,B,A
	DCR	A
	MOV	C,A
	MOV	E,C
	MOV	L,E
	MOV	B,L
	MOV	D,B
	MOV	H,D
	MOV	A,H	;TEST "MOV" A,H,D,B,L,E,C,A
	MOV	D,A
	INR	D
	MOV	L,D
	MOV	C,L
	INR	C
	MOV	H,C
	MOV	B,H
	DCR	B
	MOV	E,B
	MOV	A,E	;TEST "MOV" A,E,B,H,C,L,D,A
	MOV	E,A
	INR	E
	MOV	B,E
	MOV	H,B
	INR	H
	MOV	C,H
	MOV	L,C
	MOV	D,L
	DCR	D
	MOV	A,D	;TEST "MOV" A,D,L,C,H,B,E,A
	MOV	H,A
	DCR	H
	MOV	D,H
	MOV	B,D
	MOV	L,B
	INR	L
	MOV	E,L
	DCR	E
	MOV	C,E
	MOV	A,C	;TEST "MOV" A,C,E,L,B,D,H,A
	MOV	L,A
	DCR	L
	MOV	H,L
	MOV	E,H
	MOV	D,E
	MOV	C,D
	MOV	B,C
	MOV	A,B
	CPI	$077
	CNZ	CPUER	;TEST "MOV" A,B,C,D,E,H,L,A
;
;
;
;TEST ARITHMETIC AND LOGIC INSTRUCTIONS
;
	XRA	A
	MVI	B,$001
	MVI	C,$003
	MVI	D,$007
	MVI	E,$00F
	MVI	H,$01F
	MVI	L,$03F
	ADD	B
	ADD	C
	ADD	D
	ADD	E
	ADD	H
	ADD	L
	ADD	A
	CPI	$0F0
	CNZ	CPUER	;TEST "ADD" B,C,D,E,H,L,A
	SUB	B
	SUB	C
	SUB	D
	SUB	E
	SUB	H
	SUB	L
	CPI	$078
	CNZ	CPUER	;TEST "SUB" B,C,D,E,H,L
	SUB	A
	CNZ	CPUER	;TEST "SUB" A
	MVI	A,$080
	ADD	A
	MVI	B,$001
	MVI	C,$002
	MVI	D,$003
	MVI	E,$004
	MVI	H,$005
	MVI	L,$006
	ADC	B
	MVI	B,$080
	ADD	B
	ADD	B
	ADC	C
	ADD	B
	ADD	B
	ADC	D
	ADD	B
	ADD	B
	ADC	E
	ADD	B
	ADD	B
	ADC	H
	ADD	B
	ADD	B
	ADC	L
	ADD	B
	ADD	B
	ADC	A
	CPI	$037
	CNZ	CPUER	;TEST "ADC" B,C,D,E,H,L,A
	MVI	A,$080
	ADD	A
	MVI	B,$001
	SBB	B
	MVI	B,$0FF
	ADD	B
	SBB	C
	ADD	B
	SBB	D
	ADD	B
	SBB	E
	ADD	B
	SBB	H
	ADD	B
	SBB	L
	CPI	$0E0
	CNZ	CPUER	;TEST "SBB" B,C,D,E,H,L
	MVI	A,$080
	ADD	A
	SBB	A
	CPI	$0FF
	CNZ	CPUER	;TEST "SBB" A
	MVI	A,$0FF
	MVI	B,$0FE
	MVI	C,$0FC
	MVI	D,$0EF
	MVI	E,$07F
	MVI	H,$0F4
	MVI	L,$0BF
	ANA	A
	ANA	C
	ANA	D
	ANA	E
	ANA	H
	ANA	L
	ANA	A
	CPI	$024
	CNZ	CPUER	;TEST "ANA" B,C,D,E,H,L,A
	XRA	A
	MVI	B,$001
	MVI	C,$002
	MVI	D,$004
	MVI	E,$008
	MVI	H,$010
	MVI	L,$020
	ORA	B
	ORA	C
	ORA	D
	ORA	E
	ORA	H
	ORA	L
	ORA	A
	CPI	$03F
	CNZ	CPUER	;TEST "ORA" B,C,D,E,H,L,A
	MVI	A,$0
	MVI	H,$08F
	MVI	L,$04F
	XRA	B
	XRA	C
	XRA	D
	XRA	E
	XRA	H
	XRA	L
	CPI	$0CF
	CNZ	CPUER	;TEST "XRA" B,C,D,E,H,L
	XRA	A
	CNZ	CPUER	;TEST "XRA" A
	MVI	B,$044
	MVI	C,$045
	MVI	D,$046
	MVI	E,$047
	MVI	H,(TEMP0 / $0FF)	;HIGH BYTE OF TEST MEMORY LOCATION
	MVI	L,(TEMP0 & $0FF)	;LOW BYTE OF TEST MEMORY LOCATION
	MOV	M,B
	MVI	B,$0
	MOV	B,M
	MVI	A,$044
	CMP	B
	CNZ	CPUER	;TEST "MOV" M,B AND B,M
	MOV	M,D
	MVI	D,$0
	MOV	D,M
	MVI	A,$046
	CMP	D
	CNZ	CPUER	;TEST "MOV" M,D AND D,M
	MOV	M,E
	MVI	E,$0
	MOV	E,M
	MVI	A,$047
	CMP	E
	CNZ	CPUER	;TEST "MOV" M,E AND E,M
	MOV	M,H
	MVI	H,(TEMP0 / $0FF)
	MVI	L,(TEMP0 & $0FF)
	MOV	H,M
	MVI	A,(TEMP0 / $0FF)
	CMP	H
	CNZ	CPUER	;TEST "MOV" M,H AND H,M
	MOV	M,L
	MVI	H,(TEMP0 / $0FF)
	MVI	L,(TEMP0 & $0FF)
	MOV	L,M
	MVI	A,(TEMP0 & $0FF)
	CMP	L
	CNZ	CPUER	;TEST "MOV" M,L AND L,M
	MVI	H,(TEMP0 / $0FF)
	MVI	L,(TEMP0 & $0FF)
	MVI	A,$032
	MOV	M,A
	CMP	M
	CNZ	CPUER	;TEST "MOV" M,A
	ADD	M
	CPI	$064
	CNZ	CPUER	;TEST "ADD" M
	XRA	A
	MOV	A,M
	CPI	$032
	CNZ	CPUER	;TEST "MOV" A,M
	MVI	H,(TEMP0 / $0FF)
	MVI	L,(TEMP0 & $0FF)
	MOV	A,M
	SUB	M
	CNZ	CPUER	;TEST "SUB" M
	MVI	A,$080
	ADD	A
	ADC	M
	CPI	$033
	CNZ	CPUER	;TEST "ADC" M
	MVI	A,$080
	ADD	A
	SBB	M
	CPI	$0CD
	CNZ	CPUER	;TEST "SBB" M
	ANA	M
	CNZ	CPUER	;TEST "ANA" M
	MVI	A,$025
	ORA	M
	CPI	$037
	CNZ	CPUER	;TEST "ORA" M
	XRA	M
	CPI	$005
	CNZ	CPUER	;TEST "XRA" M
	MVI	M,$055
	INR	M
	DCR	M
	ADD	M
	CPI	$05A
	CNZ	CPUER	;TEST "INR","DCR",AND "MVI" M
	LXI	B,$12FF
	LXI	D,$12FF
	LXI	H,$12FF
	INX	B
	INX	D
	INX	H
	MVI	A,$013
	CMP	B
	CNZ	CPUER	;TEST "LXI" AND "INX" B
	CMP	D
	CNZ	CPUER	;TEST "LXI" AND "INX" D
	CMP	H
	CNZ	CPUER	;TEST "LXI" AND "INX" H
	MVI	A,$0
	CMP	C
	CNZ	CPUER	;TEST "LXI" AND "INX" B
	CMP	E
	CNZ	CPUER	;TEST "LXI" AND "INX" D
	CMP	L
	CNZ	CPUER	;TEST "LXI" AND "INX" H
	DCX	B
	DCX	D
	DCX	H
	MVI	A,$012
	CMP	B
	CNZ	CPUER	;TEST "DCX" B
	CMP	D
	CNZ	CPUER	;TEST "DCX" D
	CMP	H
	CNZ	CPUER	;TEST "DCX" H
	MVI	A,$0FF
	CMP	C
	CNZ	CPUER	;TEST "DCX" B
	CMP	E
	CNZ	CPUER	;TEST "DCX" D
	CMP	L
	CNZ	CPUER	;TEST "DCX" H
	STA	TEMP0
	XRA	A
	LDA	TEMP0
	CPI	$0FF
	CNZ	CPUER	;TEST "LDA" AND "STA"
	LHLD	TEMPP
	SHLD	TEMP0
	LDA	TEMPP
	MOV	B,A
	LDA	TEMP0
	CMP	B
	CNZ	CPUER	;TEST "LHLD" AND "SHLD"
	LDA	TEMPP+1
	MOV	B,A
	LDA	TEMP0+1
	CMP	B
	CNZ	CPUER	;TEST "LHLD" AND "SHLD"
	MVI	A,$0AA
	STA	TEMP0
	MOV	B,H
	MOV	C,L
	XRA	A
	LDAX	B
	CPI	$0AA
	CNZ	CPUER	;TEST "LDAX" B
	INR	A
	STAX	B
	LDA	TEMP0
	CPI	$0AB
	CNZ	CPUER	;TEST "STAX" B
	MVI	A,$077
	STA	TEMP0
	LHLD	TEMPP
	LXI	D,$00000
	XCHG
	XRA	A
	LDAX	D
	CPI	$077
	CNZ	CPUER	;TEST "LDAX" D AND "XCHG"
	XRA	A
	ADD	H
	ADD	L
	CNZ	CPUER	;TEST "XCHG"
	MVI	A,$0CC
	STAX	D
	LDA	TEMP0
	CPI	$0CC
	STAX	D
	LDA	TEMP0
	CPI	$0CC
	CNZ	CPUER	;TEST "STAX" D
	LXI	H,$07777
	DAD	H
	MVI	A,$0EE
	CMP	H
	CNZ	CPUER	;TEST "DAD" H
	CMP	L
	CNZ	CPUER	;TEST "DAD" H
	LXI	H,$05555
	LXI	B,$0FFFF
	DAD	B
	MVI	A,$055
	CNC	CPUER	;TEST "DAD" B
	CMP	H
	CNZ	CPUER	;TEST "DAD" B
	MVI	A,$054
	CMP	L
	CNZ	CPUER	;TEST "DAD" B
	LXI	H,$0AAAA
	LXI	D,$03333
	DAD	D
	MVI	A,$0DD
	CMP	H
	CNZ	CPUER	;TEST "DAD" D
	CMP	L
	CNZ	CPUER	;TEST "DAD" B
	STC
	CNC	CPUER	;TEST "STC"
	CMC
	CC	CPUER	;TEST "CMC
	MVI	A,$0AA
	CMA	
	CPI	$055
	CNZ	CPUER	;TEST "CMA"
	ORA	A	;RE-SET AUXILIARY CARRY
	DAA
	CPI	$055
	CNZ	CPUER	;TEST "DAA"
	MVI	A,$088
	ADD	A
	DAA
	CPI	$076
	CNZ	CPUER	;TEST "DAA"
	XRA	A
	MVI	A,$0AA
	DAA
	CNC	CPUER	;TEST "DAA"
	CPI	$010
	CNZ	CPUER	;TEST "DAA"
	XRA	A
	MVI	A,$09A
	DAA
	CNC	CPUER	;TEST "DAA"
	CNZ	CPUER	;TEST "DAA"
	STC
	MVI	A,$042
	RLC
	CC	CPUER	;TEST "RLC" FOR RE-SET CARRY
	RLC
	CNC	CPUER	;TEST "RLC" FOR SET CARRY
	CPI	$009
	CNZ	CPUER	;TEST "RLC" FOR ROTATION
	RRC
	CNC	CPUER	;TEST "RRC" FOR SET CARRY
	RRC
	CPI	$042
	CNZ	CPUER	;TEST "RRC" FOR ROTATION
	RAL
	RAL
	CNC	CPUER	;TEST "RAL" FOR SET CARRY
	CPI	$008
	CNZ	CPUER	;TEST "RAL" FOR ROTATION
	RAR
	RAR
	CC	CPUER	;TEST "RAR" FOR RE-SET CARRY
	CPI	$002
	CNZ	CPUER	;TEST "RAR" FOR ROTATION
	LXI	B,$01234
	LXI	D,$0AAAA
	LXI	H,$05555
	XRA	A
	PUSH	B
	PUSH	D
	PUSH	H
	PUSH	PSW
	LXI	B,$00000
	LXI	D,$00000
	LXI	H,$00000
	MVI	A,$0C0
	ADI	$0F0
	POP	PSW
	POP	H
	POP	D
	POP	B
	CC	CPUER	;TEST "PUSH PSW" AND "POP PSW"
	CNZ	CPUER	;TEST "PUSH PSW" AND "POP PSW"
	CPO	CPUER	;TEST "PUSH PSW" AND "POP PSW"
	CM	CPUER	;TEST "PUSH PSW" AND "POP PSW"
	MVI	A,$012
	CMP	B
	CNZ	CPUER	;TEST "PUSH B" AND "POP B"
	MVI	A,$034
	CMP	C
	CNZ	CPUER	;TEST "PUSH B" AND "POP B"
	MVI	A,$0AA
	CMP	D
	CNZ	CPUER	;TEST "PUSH D" AND "POP D"
	CMP	E
	CNZ	CPUER	;TEST "PUSH D" AND "POP D"
	MVI	A,$055
	CMP	H
	CNZ	CPUER	;TEST "PUSH H" AND "POP H"
	CMP	L
	CNZ	CPUER	;TEST "PUSH H" AND "POP H"
	LXI	H,$00000
	DAD	SP
	SHLD	SAVSTK	;SAVE THE "OLD" STACK-POINTER!
	LXI	SP,TEMP4
	DCX	SP
	DCX	SP
	INX	SP
	DCX	SP
	MVI	A,$055
	STA	TEMP2
	CMA
	STA	TEMP3
	POP	B
	CMP	B
	CNZ	CPUER	;TEST "LXI","DAD","INX",AND "DCX" SP
	CMA
	CMP	C
	CNZ	CPUER	;TEST "LXI","DAD","INX", AND "DCX" SP
	LXI	H,TEMP4
	SPHL
	LXI	H,$07733
	DCX	SP
	DCX	SP
	XTHL
	LDA	TEMP3
	CPI	$077
	CNZ	CPUER	;TEST "SPHL" AND "XTHL"
	LDA	TEMP2
	CPI	$033
	CNZ	CPUER	;TEST "SPHL" AND "XTHL"
	MVI	A,$055
	CMP	L
	CNZ	CPUER	;TEST "SPHL" AND "XTHL"
	CMA
	CMP	H
	CNZ	CPUER	;TEST "SPHL" AND "XTHL"
	LHLD	SAVSTK	;RESTORE THE "OLD" STACK-POINTER
	SPHL
	LXI	H,CPUOK
	PCHL		;TEST "PCHL"

CPUER:	mvi	a, $aa	; set exit code (failure)
	hlt		; STOP HERE

CPUOK:	mvi	a, $55	;
	hlt		; STOP HERE - no trap


; Data area
TEMPP:	.dw	TEMP0	;POINTER USED TO TEST "LHLD","SHLD",
			; AND "LDAX" INSTRUCTIONS
TEMP0:	.db	1	;TEMPORARY STORAGE FOR CPU TEST MEMORY LOCATIONS
TEMP1:	.db	1	;TEMPORARY STORAGE FOR CPU TEST MEMORY LOCATIONS
TEMP2:	.db	1	;TEMPORARY STORAGE FOR CPU TEST MEMORY LOCATIONS
TEMP3:	.db	1	;TEMPORARY STORAGE FOR CPU TEST MEMORY LOCATIONS
TEMP4:	.db	1	;TEMPORARY STORAGE FOR CPU TEST MEMORY LOCATIONS
SAVSTK:	.db	2	;TEMPORARY STACK-POINTER STORAGE LOCATION

STACK:	.dw	TEMPP + 256	;DE-BUG STACK POINTER STORAGE AREA
.end
