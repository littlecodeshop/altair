100 REM  NAME--NIM
110 REM
120 REM  DESCRIPTION--PLAYS THE ANCIENT GAME OF NIM.
130 REM
140 REM  SOURCE--UNKNOWN
150 REM
160 REM  INSTRUCTIONS--TYPE "RUN" AND FOLLOW INSTRUCTIONS.
170 REM
180 REM
190 REM  *  *  *  *  *  *   MAIN PROGRAM   *  *  *  *  *  *  *  *  *
200 REM
210 PRINT " THIS IS THE ANCIENT GAME OF NIM."
220 PRINT
230 PRINT "IT IS PLAYED WITH THREE PILES OF STICKS."
240 PRINT "YOU MAY REMOVE AS MANY STICKS AS YOU WISH, ";
250 PRINT "BUT FROM ONE PILE ONLY."
260 PRINT "THEN IT IS MY TURN TO DO THE SAME."
270 PRINT "THE OBJECT OF THE GAME IS TO TAKE THE LAST STICK."
280 PRINT "WHEN IT IS YOUR MOVE, I'LL ASK 'WHICH PILE, HOW MANY'."
290 PRINT "TO REMOVE, FROM PILE 2,  5 STICKS, SIMPLY TYPE: 2,5"
300 PRINT "THEN PUSH 'RETURN' --- THIS IS VERY IMPORTANT."
310 PRINT
320 PRINT "THIS IS THE ORIGINAL ARRANGEMENT:"
330 PRINT
225 DIM B(12):DIM N(3)
340 FOR I=1 TO 3:READ N(I):NEXT I
350 FOR I=1 TO 12:READ B(I):NEXT I
360 DATA 15,14,13, 1,1,1,1, 1,1,1,0, 1,1,0,1
370 PRINT "PILE 1 :" N(1)
380 PRINT "PILE 2 :" N(2)
390 PRINT "PILE 3 :" N(3)
400 PRINT
410 PRINT
420 PRINT
430 PRINT "WHICH PILE, HOW MANY";
440 INPUT P,X
450 PRINT
460 IF P < 1 THEN 520
470 IF P > 3 THEN 520
480 IF X < 1 THEN 520
490 IF N(P) < X THEN 520
500 LET N(P) = N(P) - X
510 GOTO 550
520 PRINT "ILLEGAL MOVE"
530 PRINT
540 GOTO 430
550 IF N(1)+N(2)+N(3) > 0 THEN 580
560 PRINT "CONGRATULATIONS! YOU WIN! *****"
570 GOTO 950
580 GOSUB 600
590 GOTO 670
600 LET Y = N(P)
610 FOR I = 1 TO 4
620 LET Z = INT(Y/2)
630 LET B((P-1)*4+5-I) = Y-2*Z
640 LET Y = Z
650 NEXT I
660 RETURN
670 LET J9 = 0
680 FOR J = 4 TO 1 STEP -1
690 LET S = B(J)+B(4+J)+B(8+J)
700 IF S < 2 THEN 720
710 LET S = S-2
720 IF S = 0 THEN 740
730 LET J9 = J
740 LET S(J) = S
750 NEXT J
760 IF J9 = 0 THEN 860
770 FOR P = 1 TO 3
780 IF B((P-1)*4+J9) = 1 THEN 800
790 NEXT P
800 LET X = 0
810 FOR J = J9 TO 4
820 LET Y = S(J)*(2*B((P-1)*4+J)-1)
830 LET X = 2*X+Y
840 NEXT J
850 GOTO 890
860 LET P = INT(3*RND(1)+1)
870 IF N(P) = 0 THEN 860
880 LET X = 1
890 LET N(P) = N(P) - X
900 GOSUB 600
910 PRINT "MY MOVE:  ";P;",";X
920 PRINT
930 IF N(1)+N(2)+N(3) > 0 THEN 370
940 PRINT "I WIN."
950 PRINT
960 PRINT "WOULD YOU LIKE TO PLAY AGAIN (1=YES 0=NO)";
970 INPUT A0
980 IF A0=1 THEN 1020
990 IF A0=0 THEN 1050
1000 PRINT "PLEASE TYPE '1' OR '0':  ";
1010 GOTO 970
1020 PRINT
1030 RESTORE
1040 GOTO 340
1050 PRINT "THANKS FOR THE GAME *****"
1060 END