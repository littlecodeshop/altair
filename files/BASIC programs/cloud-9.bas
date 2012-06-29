10 REM--A.C.CAGGIANO+E.A.GALLETTA, PATCHOGUE H.S., 11-20-68 
11 REM--REVISED BY CHARLES LOSIK AND TONY PEREZ 7/18/69 
12 REM RE-REVISED BY C.LOSIK 8-26-70
20 REM--THIS PROGRAM IS ASSOCIATED WITH CLOUD FORMATION 
25 REM PHASE I OF PROGRAM BEGINS HERE. STUDENTS WILL BE GIVEN
26 REM INTRODUCTORY INFORMATION AND BE ALLOWED TO ASK AND ANSWER 
27 REM ANY NUMBER OF PROBLEMS. WHEN THEY INPUT NO. 2 (LINES 554-556) 
28 REM PROGRAM SENDS THEM TO PHASE II (LINE 561 AND FOLLOWING). 
30 PRINT" ","CLOUD NINE" 
40 PRINT" ","===== ====" 
45 DIM B(2), T(4), Q(3), A(3), C(3) 
50 PRINT 
60 PRINT" STRONG CONVECTION CURRENTS ARE CAUSING ADIABATIC" 
70 PRINT"COOLING OF AIR WHERE YOU ARE AND ARE RESPONSIBLE FOR THE"
80 PRINT"FORMATION OF A CLOUD. BOTH THE DRY AND THE MOIST ADIABATIC" 
90 PRINT"(AS WELL AS THE NORMAL LAPSE RATES) ARE CONSIDERED IN THIS" 
91 PRINT"PROGRAM."
100 PRINT 
105 PRINT 
110 PRINT" ","LEGEND" 
120 PRINT" ","======" 
140 PRINT"1="; 
150 GOSUB1000 
160 PRINT"2="; 
170 GOSUB1010 
180 PRINT"3="; 
190 GOSUB1020 
200 PRINT"4="; 
210 GOSUB1030 
220 PRINT 
225 PRINT 
230 PRINT"CHOOSE ANY TWO OF THE ABOVE VARIABLES AND SELECT VALUES FOR" 
231 PRINT"THEM. TYPE THEM IN AS:" 
232 PRINT"VARIABLE CODE ,VALUE, VARIABLE CODE ,VALUE...(E.G. 1,50,2,30)" 
233 PRINT 
240 X=0
242 Y=0
245 A=0
246 B=0
247 B(1)=0 
248 B(2)=0 
250 INPUTB(1),A,B(2),B 
290 PRINT 
300 FORI=1TO4 
310 IFB(1)=ITHEN330
320 NEXTI 
330 T(I)=A 
340 FORJ=1TO4 
350 IFB(2)=JTHEN370
360 NEXTJ 
370 T(J)=B 
380 IFI<>JTHEN405 
390 PRINT"YOU CAN'T USE THE SAME VALUES TWICE."
395 GOTO250
405 PRINT"OKAY, TYPE IN YOUR CALCULATED VALUE FOR";
406 PRINT 
410 IFJ*I<>2THEN425
411 T=(T(1)-T(2))/4.5 
412 T(4)=1000*T 
413 T(3)=T(2)-T 
414 GOSUB1020 
415 GOSUB1050 
416 GOSUB1030 
417 INPUTX,Y 
418 IFABS(X-T(3))>=.6THEN500 
419 IFABS(Y-T(4))>=.6THEN500 
420 GOTO550
425 IFJ*I<>3THEN440
426 T=(T(1)-T(3))/5.5 
427 T(4)=1000*T 
428 T(2)=T+T(3) 
429 GOSUB1010 
430 GOSUB1050 
431 GOSUB1030 
432 INPUTX,Y 
433 IFABS(X-T(2))>=.6THEN500 
434 IFABS(Y-T(4))>=.6THEN500 
435 GOTO550
440 IFJ*I<>4THEN455
441 T=T(4)/1000 
442 T(2)=T(1)-4.5*T 
443 T(3)=T(2)-T 
444 GOSUB1010 
445 GOSUB1050 
446 GOSUB1020 
447 INPUTX,Y 
448 IFABS(X-T(2))>=.6THEN500 
449 IFABS(Y-T(3))>=.6THEN500 
450 PRINT"OKAY, TYPE IN YOUR CALCULATED VALUE FOR" 
455 IFJ*I<>6THEN470
456 T=T(2)-T(3) 
457 T(4)=1000*T 
458 T(1)=T(3)+5.5*T 
459 GOSUB1000 
460 GOSUB1050 
461 GOSUB1030 
462 INPUTX,Y 
463 IFABS(X-T(1))>=.6THEN500 
464 IFABS(Y-T(4))>=.6THEN500 
465 GOTO550
470 IFJ*I<>8THEN485
471 T=T(4)/1000 
472 T(3)=T(2)+T 
473 T(1)=T(2)+6.5*T 
474 GOSUB1010 
475 GOSUB1050 
476 GOSUB1020 
477 INPUTX,Y 
478 IFABS(X-T(1))>=.6THEN500 
479 IFABS(Y-T(3))>=.6THEN500 
480 GOTO550
481 IFABS(X-T(3))>=.6THEN500 
485 IFJ*I<>12THEN390 
486 T=T(4)/1000 
487 T(1)=T(3)+5.5*T 
488 T(2)=T(3)+T 
489 GOSUB1000 
490 GOSUB1050 
491 GOSUB1010 
492 INPUTX,Y 
493 IFABS(X-T(1))>=.6THEN500 
494 IFABS(Y-T(2))>=.6THEN500 
495 GOTO550
500 PRINT 
502 PRINT"IT LOOKS LIKE WE GOOFED SOME PLACE." 
505 PRINT"LET'S SEE WHAT THE CORRECT VALUES ARE." 
507 PRINT 
510 PRINT T(1);"DEGREES - "; 
512 GO SUB 1000
515 PRINT T(2);"DEGREES - "; 
517 GO SUB 1010
520 PRINT T(3);"DEGREES - "; 
522 GO SUB 1020
525 PRINT T(4);"FEET - "; 
527 GO SUB 1030
530 PRINT 
535 GOTO554
550 PRINT 
552 PRINT"VERY GOOD. VERY, VERY GOOD."
553 PRINT 
554 PRINT"DO YOU HAVE ANY OTHER PROBLEMS YOU WOULD LIKE TO TRY?" 
555 PRINT "(1=YES, 0=NO) : "; 
556 INPUT P
557 IFP<1THEN561 
558 PRINT 
559 PRINT"USING THE SAME LEGEND AS BEFORE..." 
560 GOTO230
561 H=(T(1)-T(3))*2000-7*T(4) 
562 REM LINE 561 CALCULATES ALTITUDE FOR TOP OF CLOUD AND BEGINS 
563 REM PHASE II OF PROGRAM. PROBLEM NO.2 IN THIS PART (CALCULATION 
564 REM OF TEMP. ABOVE CLOUD TOP) INVOLVES USE OF THE NORMAL LAPSE RATE. 
565 PRINT 
567 PRINT"WELL, BEFORE YOU LEAVE, I HAVE A FEW I'D LIKE YOU TO TRY..." 
570 PRINT"BASED ON YOUR VALUES, THE HEIGHT OF THE CLOUD" 
580 PRINT"(MEASURED FROM THE CLOUD BASE) IS ";H;"FT. CAN YOU TELL ME:"
600 Q(1)=.7*T(4)
601 Q(2)=T(4)+1.5*H 
602 Q(3)=T(4)+.5*H 
610 A(1)=T(1)-T(4)*3.85E-03 
611 A(2)=T(1)-(T(4)+1.5*H)*3.5E-03 
612 A(3)=T(3)-1.5E-03*H 
614 PRINT 
615 PRINT"WHAT IS THE TEMPERATURE AT EACH OF THESE ALTITUDES:" 
620 FORN=1TO3 
625 PRINT" ",N;INT(Q(N)+.5);"FT" 
627 NEXT N 
628 PRINT 
629 FORN=1TO3 
630 PRINT"THE TEMPERATURE AT ";INT(Q(N)+.5);" FT. IS ";
631 INPUTC(N) 
635 IFABS(C(N)-A(N))>1.1THEN750
640 NEXTN 
699 PRINT 
700 PRINT"WOW, YOU MUST BE A BRAIN. AND YOU PROBALLY KNOW"
710 PRINT"A LOT ABOUT CLOUDS AND THINGS LIKE THAT. IT WAS VERY" 
720 PRINT"NICE TO WORK WITH SOMEONE WHO UNDERSTANDS ME." 
730 PRINT" ","THANK YOU AND . . . . PEACE AND LONG LIFE" 
740 STOP 
750 PRINT 
755 PRINT"SORRY. YOU WERE DOING GREAT THERE FOR A WHILE." 
760 PRINT"WELL, BACK TO THE BOOKS. THE VALUES YOU SHOULD HAVE ARE:" 
765 PRINT 
770 FORN=1TO3 
774 PRINTN;
780 PRINT"THE TEMPERATURE AT";INT(Q(N)+.5);"FEET IS ";A(N);"DEGREES" 
790 NEXTN 
830 STOP 
1000 PRINT"THE TEMPERATURE ON THE GROUND" 
1005 RETURN 
1010 PRINT"THE DEW POINT TEMPERATURE ON THE GROUND" 
1015 RETURN 
1020 PRINT"THE TEMPERATURE AT THE BASE OF THE CLOUD"
1025 RETURN 
1030 PRINT"THE ELEVATION, IN FEET, OF THE CLOUD BASE" 
1035 RETURN 
1050 PRINT"FOLLOWED BY A COMMA, AND THEN TYPE IN YOUR VALUE FOR " 
1055 RETURN 
2000 END
