80 INV=0
90 ES$=CHR$(27)
100 WIDTH 255
110 PRINT CHR$(27)+"[2J"+CHR$(27)+"[0;0f";
120 PRINT CHR$(27)+"[0m";
130 PRINT CHR$(27)+"[1;1H";
140 PRINT"There are 64 color combinations";
150 PRINT CHR$(27)+"[2;1H";
160 PRINT"8x8 matrix of foreground/background colors, bright *off*";
200 FOR A=9 TO 65 STEP 8
210 A$=MID$(STR$(A),2)
215 READ C$
220 PRINT CHR$(27)+"[3;"+A$+"H"+C$
230 NEXT A
240 RESTORE
250 FOR A=4 TO 11
260 A$=MID$(STR$(A),2)
270 READ C$
280 PRINT CHR$(27)+"["+A$+";1H"+C$;
290 NEXT A
292 IF INV=1 THEN PRINT CHR$(27)+"[7m";
295 F=30:BR=40
300 FOR A=4 TO 11
310 FOR B=9 TO 65 STEP 8
320 A$=MID$(STR$(A),2)
330 B$=MID$(STR$(B),2)
340 F$=MID$(STR$(F),2)
350 BR$=MID$(STR$(BR),2)
360 P$=ES$+"["+A$+";"+B$+"H"+ES$+"["+F$+";"+BR$+"mAltair"
365 PRINT P$
370 F=F+1
380 NEXT B
390 F=30:BR=BR+1
400 NEXT A
410 RESTORE
430 PRINT CHR$(27)+"[0m";
450 PRINT CHR$(27)+"[13;1H";
460 PRINT"8x8 matrix of foreground/background colors, bright *on*";
500 FOR A=9 TO 65 STEP 8
510 A$=MID$(STR$(A),2)
515 READ C$
520 PRINT CHR$(27)+"[14;"+A$+"H"+C$
530 NEXT A
540 RESTORE
550 FOR A=15 TO 22
560 A$=MID$(STR$(A),2)
570 READ C$
580 PRINT CHR$(27)+"["+A$+";1H"+C$;
590 NEXT A
592 PRINT CHR$(27)+"[1m";
594 IF INV=1 THEN PRINT CHR$(27)+"[7m";
595 F=30:BR=40
600 FOR A=15 TO 22
610 FOR B=9 TO 65 STEP 8
620 A$=MID$(STR$(A),2)
630 B$=MID$(STR$(B),2)
640 F$=MID$(STR$(F),2)
650 BR$=MID$(STR$(BR),2)
660 P$=ES$+"["+A$+";"+B$+"H"+ES$+"["+F$+";"+BR$+"mAltair"
665 PRINT P$
670 F=F+1
680 NEXT B
690 F=30:BR=BR+1
700 NEXT A
710 PRINT CHR$(27)+"[0m"
1000 DATA "black","red","green","yellow","blue","magenta","cyan","white"
1010 run

