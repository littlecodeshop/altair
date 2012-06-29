; Cromemco Dazzler demonstration program
; Copied from the Dazzler General Technical Information manual
;
; Sets display memory window to 512b starting at 0 
; Raise A12 to enable color mode

DCTRL	= $0e	; 16
DDATA	= $0f	; 17
SENSESW	= $ff

*=$0

Start
	mvi	a,$80
	out	DCTRL		; enable board with 512b window at 0h
	in	SENSESW		; get data from sense switches
	out	DDATA		; send it to the board
	jmp 	Start		; loop

.end
