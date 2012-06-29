; Altair 8800 BASIC 3.2 [8k Version]
; Cassette Boot Loader
; Written by Bill Gates and Paul Allen and Monte Davidoff
; 041 256 037       ; octal boot
; 061 022 000
; 333 006
; 017
; 330
; 333 007
; 275
; 310
; 055
; 167
; 300
; 351
; 003
; 000
;==========================================================
;Notes:
;The 8K cassette tape took 4.5 minutes to load and displayed the
;octal pattern 17647 for a good load and 17637 when it failed,
;which happened a lot.
;
;It would be fun to load the data in 4.5 minutes (slow mode) to
;emulate the actual frustration of the old machines. I could
;supply a wav file or mpg of the data for something to listen too
;as the coffee was being made.
;
;The loader was single stepped to IN, 7 (ACR data port), and the next click
;turned on the INP status LED and the data LEDs displayed noise until the pattern
;256 ($C2) showed steady, meaning the leader was being read and then RUN was
;toggled.  The address 17647 displayed after the 2nd loader was running. Then it
;was time to get a coffee.
;
;Port 255Q Sense Switch was set up for eventual terminal baud rates and such as
;you already have documented.
;==========================================================
; MITSlodr.asm
; THE BASIC TAPES HAVE A LEADER
; FOLLOWED BY A LOADER
; FOLLOWED BY RECORDS
; THIS "PRELOADER" READS IN THE TAPE LOADER
;
; Modifications (c) 2003 by Richard Cini
;    Assemble with "TASM -85 lodr_ex4.asm"

.ORG 0
; H=HIGH BYTE OF LOAD ADDRESS
; L=VALUE OF LEADER BYTE  !
; AND LENGTH OF LOADER    !!
; AND LOW BYTE OF ADDRESS !!!
;		LXI  H,00FAEH   ;4KBAS32.tap
;		LXI  H,01FC2H   ;8KBAS40.tap
		LXI  H,03FC2H   ;EXBAS40.tap
;		LXI  H,07EC2H   ;EDBAS50.tap
LOOP    LXI  SP,STACK   ;(RE)INIT STACK POINTER
;		IN   00H        ;SIO GET STATUS
		IN   06H        ;ACR GET STATUS
		RRC             ;?BYTE READY
		RC              ;    NO  RETURN TO LOOP
;		IN   01H        ;SIO YES GET BYTE
		IN   07H        ;ACR YES GET BYTE
		CMP  L          ;?LEADER BYTE
		RZ              ; YES RETURN TO LOOP
		DCR  L          ; NO  DECREMENT ADDRESS
		MOV  M,A        ;  MOVE DATA TO MEMORY
		RNZ             ;?NOT DONE RETURN TO LOOP
		PCHL            ; YES JUMP TO TAPE LOADER
STACK:  .DW  LOOP
.END
