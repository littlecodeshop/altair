10 REM ---DESIGNED TO RUN ON HEATH H19/H89---
900 WIDTH 80
1000 LET E$=CHR$(27):PRINT E$;"F";E$;"E";E$;"x5";E$;"Y#'";
1010 PRINT TAB(18);E$;"F";"faaqaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaac"
1020 PRINT TAB(18);"`";SPC(43);"`"
1030 PRINT TAB(18);"`             'S T A R W A R S'             `"
1040 PRINT TAB(18);"`";SPC(43);"`"
1050 PRINT TAB(18);"`";E$;"G";"     This program presented courtesy of    ";
1060 PRINT E$;"F";"`"
1070 PRINT TAB(18);"`";SPC(43);"`"
1080 PRINT TAB(18);"`";E$;"p";" C U S T O M   S O F T W A R E   G R O U P ";
1090 PRINT E$;"q";"`"
1100 PRINT TAB(18);"`";SPC(43);"`"
1110 PRINT TAB(18);"`";E$;"G";"   Specializing in custom programming for  ";
1120 PRINT E$"F";"`"
1130 PRINT TAB(18);"`         HEATH/ZENITH DATA SYSTEMS         `"
1140 PRINT TAB(18);"`";SPC(43);"`"
1150 PRINT TAB(18);"`           CUSTOM SOFTWARE GROUP           `"
1160 PRINT TAB(18);"`              POST OFFICE BOX              `"
1170 PRINT TAB(18);"`            BELLEVUE, NE  68005            `"
1180 PRINT TAB(18);"`              PHONE 291-4622               `"
1190 PRINT TAB(18);"`                    291-5819               `"
1200 PRINT TAB(18);"`";SPC(43);"`"
1210 PRINT TAB(18);"eaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaad";E$;"G"
1220 PRINT TAB(28);"PRESS RETURN TO CONTINUE"
1230 A$=INPUT$(1)
1240 PRINT CHR$(27);"G";CHR$(27);"w"
1250 CLEAR 1000
1260 PRINT CHR$(27);"E";CHR$(27);"Y! ";CHR$(27);"x5"
1270 PRINT ,"   ********   **********    ******    *********"
1280 PRINT ,"  **      **      **       **    **   **      **"
1290 PRINT ,"  **              **      **      **  **      **"
1300 PRINT ,"   ********       **      **********  *********"
1310 PRINT ,"          **      **      **      **  **    **"
1320 PRINT ,"  **      **      **      **      **  **     **"
1330 PRINT ,"   ********       **      **      **  **      **"
1340 PRINT:PRINT
1350 PRINT ,"  **      **    ******    *********    ********"
1360 PRINT ,"  **      **   **    **   **      **  **      **"
1370 PRINT ,"  **      **  **      **  **      **  **"
1380 PRINT ,"  **  **  **  **********  *********    ********"
1390 PRINT ,"  **  **  **  **      **  **    **            **"
1400 PRINT ,"   ********   **      **  **     **   **      **"
1410 PRINT ,"    **  **    **      **  **      **   ********"
1420 FOR I=1 TO 1000:NEXT I
1430 PRINT CHR$(27);"Y7 "
1440 PRINT ,"A LONG TIME AGO IN A GALAXY FAR, FAR AWAY, A GREAT"
1450 FOR I=1 TO 1000:NEXT I:PRINT
1460 PRINT ,"ADVENTURE TOOK PLACE. IT IS A PERIOD OF CIVIL WAR."
1470 FOR I=1 TO 1000:NEXT I:PRINT
1480 PRINT ,"REBEL SPACE SHIPS STRIKING FROM A HIDDEN BASE HAVE"
1490 FOR I=1 TO 1000:NEXT I:PRINT
1500 PRINT ,"WON THEIR FIRST VICTORY AGAINST THE EVIL  GALACTIC"
1510 FOR I=1 TO 1000:NEXT I:PRINT
1520 PRINT ,"EMPIRE.  DURING THE BATTLE, REBEL SPYS  MANAGED TO"
1530 FOR I=1 TO 1000:NEXT I:PRINT
1540 PRINT ,"STEAL SECRET PLANS TO THE EMPIRE'S ULITMATE WEAPON"
1550 FOR I=1 TO 1000:NEXT I:PRINT
1560 PRINT ,"THE DEATH STAR, AN ARMOURED SPACE STATION WITH THE"
1570 FOR I=1 TO 1000:NEXT I:PRINT
1580 PRINT ,"FIRE POWER TO DESTROY AN ENTIRE PLANET. "
1590 FOR I=1 TO 1000:NEXT I:PRINT:PRINT
1600 PRINT ,"     YOUR MISSION AS ONE OF THE REBEL PILOTS IS TO"
1610 FOR I=1 TO 1000:NEXT I:PRINT
1620 PRINT ,"ATTACK AND DESTROY THE 'DEATH STAR'.  WHILE MAKING"
1630 FOR I=1 TO 1000:NEXT I:PRINT
1640 PRINT ,"YOUR ATTACK YOU HAVE ENCOUNTERED 'DARTH VADER' AND"
1650 FOR I=1 TO 1000:NEXT I:PRINT
1660 PRINT ,"HIS IMPERIAL STORM TROOPERS IN THEIR TIE FIGHTERS."
1670 FOR I=1 TO 1000:NEXT I:PRINT
1680 PRINT ,"YOU MUST DESTROY THEM BEFORE THEY CAN DESTROY YOU."
1690 FOR I=1 TO 1000:NEXT I:PRINT:PRINT
1700 PRINT ,"    GOOD LUCK AND MAY THE 'FORCE' BE WITH YOU     "
1710 FOR I=1 TO 2000:NEXT I
1720 REM
1730 REM .........................INSTRUCTIONS ROUTINE.......................
1740 REM
1750 PRINT CHR$(27);"E";CHR$(27);"Y*6";"DO YOU NEED:":PRINT
1760 PRINT TAB(30);"FULL INSTRUCTIONS <F>?"
1770 PRINT TAB(30);"BRIEF INSTRUCTIONS <B>?"
1780 PRINT TAB(30);"NO INSTRUCTIOnS <N>?"
1790 A$=INPUT$(1):IF A$="F" THEN 1870
1800 IF A$="B" THEN 2270
1810 IF A$="N" THEN 1820 ELSE 1790
1820 PRINT:PRINT TAB(29);"WHAT IS YOUR SKILL RATING?"
1830 A$=INPUT$(1):IF A$<"1" OR A$>"9" THEN 1850
1840 LET A$=A$+"0":LET A9=CVI(A$):LET A9=A9-12336:GOTO 2540
1850 PRINT:PRINT TAB(26);"EVIDENTLY YOU NEED INSTRUCTIONS!"
1860 FOR I=1 TO 500:NEXT I:PRINT
1870 PRINT CHR$(27);"E";CHR$(27);"Y! "
1880 PRINT "YOU HAVE BEEN EQUIPPED WITH AN X-WING   ";
1890 PRINT "   AS IN A REAL DOG-FIGHT YOU MUST  LEAD"
1900 PRINT "FIGHTER BY THE REBEL ALLIANCE.   YOUR   ";
1910 PRINT "   THE TARGET WHEN FIRING YOUR LASER. IF"
1920 PRINT "FIGHTER IS COMPUTER CONTROLLED BY THE   ";
1930 PRINT "   YOU WAIT UNTIL HE IS EXACTLY CENTERED"
1940 PRINT "NUMERIC KEYPAD ON YOUR KEY BOARD. THE   ";
1950 PRINT "   TO FIRE, THEN YOU WILL MISS HIM.  YOU"
1960 PRINT "DISPLAY YOU WILL SEE IS YOUR  ONBOARD   ";
1970 PRINT "   MAY CONTINUE TO FIRE AT HIM, BUT WHEN"
1980 PRINT "SCANNER.  IN ORDER TO KILL  AN  ENEMY   ";
1990 PRINT "   YOU ARE FIRING YOUR WEAPON, YOUR CON-"
2000 PRINT "FIGHTER HE MUST RECEIVE A DIRECT  HIT   ";
2010 PRINT "   TROL OF DIRECTION IS NOT AS  GOOD  AS"
2020 PRINT "OR MULTIPLE DAMAGING HITS.   HE  WILL   ";
2030 PRINT "   WHEN YOU AREN'T FIRING AND THE TARGET"
2040 PRINT "RECEIVE DAMAGE IF HIT WHEN HE IS  +/-   ";
2050 PRINT "   MAY FLY OUT OF YOUR SIGHTS.          "
2060 PRINT "10 DEGREES IN ELEVATION AND HE IS +/-   ";
2070 PRINT " "
2080 PRINT "9 DEGREES IN BEARING.  IN ADDITION TO   ";
2090 PRINT "   IN ORDER TO CENTER YOUR TARGET ON THE"
2100 PRINT "THIS HE MUST BE WITHIN 6500 KMS.        ";
2110 PRINT "   SCANNER YOU MUST FLY TOWARDS HIM.  TO"
2120 PRINT "                                        ";
2130 PRINT "   TO DO THIS YOU PRESS THE KEY  ON  THE"
2140 PRINT "WARNING:  THE 'TIE' FIGHTER  HAS  THE   ";
2150 PRINT "   NUMERIC KEY PAD THAT IS IN HIS DIREC-"
2160 PRINT "CAPABILITY TO POP IN AND OUT OF  HYP-   ";
2170 PRINT "   TION. IE: IF HE IS IN THE UPPER-RIGHT"
2180 PRINT "ERSPACE.  THEREFORE HE MAY  DISAPPEAR   ";
2190 PRINT "   QUADRANT YOU WOULD PRESS KEY 9 TO FLY"
2200 PRINT "RIGHT FROM BEFORE YOUR SIGHTS.          ";
2210 PRINT "   TOWARDS HIM. IF HE IS BELOW, PRESS 2."
2220 PRINT "                                        ";
2230 PRINT " "
2240 PRINT "      MAY THE FORCE BE WITH YOU         ";
2250 PRINT "         PRESS RETURN TO CONT           ";
2260 LINE INPUT A$
2270 PRINT CHR$(27);"E"
2280 PRINT CHR$(27);"F";
2290 PRINT ,"     UP &              UP             UP &"
2300 PRINT ,"     LEFT   faaaaac faaaaac faaaaac   RIGHT"
2310 PRINT ,"            `  7  ` `  8  ` `  9  `"
2320 PRINT ,"            eaaaaad eaaaaad eaaaaad"
2330 PRINT ,"            faaaaac faaaaac faaaaac"
2340 PRINT ,"     LEFT   `  4  ` `  5  ` `  6  `   RIGHT"
2350 PRINT ,"            eaaaaad eaaaaad eaaaaad"
2360 PRINT ,"            faaaaac faaaaac faaaaac"
2370 PRINT ,"            `  1  ` `  2  ` `  3  `"
2380 PRINT ,"     DOWN   eaaaaad eaaaaad eaaaaad   RIGHT"
2390 PRINT ,"     LEFT   faaaaac   DOWN            DOWN"
2400 PRINT ,"            `  0  `"
2410 PRINT ,"            eaaaaad"
2420 PRINT ,"              FIRE"
2430 PRINT CHR$(27);"G"
2440 PRINT TAB(18);"<<PRESS '5' TO STOP ANY TURNS OR CLIMBS.>>":PRINT
2450 PRINT TAB(23);"ENTER A SKILL RATING FROM 1 TO 9"
2460 PRINT TAB(27);"NOVICE.................1"
2470 PRINT TAB(27);"EXPERT.................9":PRINT
2480 PRINT "AFTER SCANNER CONSTRUCTION IS COMPLETE, PRESS ANY CONTROL KEY TO"
2485 PRINT "START YOUR SCAN"
2490 A$=INPUT$(1):IF A$<"1" OR A$>"9" THEN 2490
2500 LET A$=A$+"0":LET A9=CVI(A$):LET A9=A9-12336
2510 REM
2520 REM ......................GRID CONSTRUCTION ROUTINE....................
2530 REM
2540 PRINT CHR$(27);"F";CHR$(27);"x1";CHR$(27);"x5":PRINT CHR$(27);"E";
2550 PRINT TAB(16);"RANGE:g9999 KM    ELEVATION:g90 DEG  BEARING:g90 DEG"
2560 PRINT:ED=0
2570 PRINT TAB(8);"-90  -75  -60  -45  -30  -15   0   +15  +30  +45  +60  +75  +90"
2580 PRINT TAB(5);"+90 bssssbssssbssssbssssbssssbssssbssssbssssbssssbssssbssssbssssb +90"
2590 PRINT TAB(9);"v";SPC(59);"t":PRINT TAB(9);"v";SPC(59);"t"
2600 PRINT TAB(5);"+60 b";SPC(59);"b +60"
2610 PRINT TAB(9);"v";SPC(59);"t":PRINT TAB(9);"v";SPC(59);"t"
2620 PRINT TAB(5);"+30 b";SPC(59);"b +30"
2630 PRINT TAB(9);"v";SPC(59);"t":PRINT TAB(9);"v";SPC(59);"t"
2640 PRINT TAB(6);"0  b";SPC(59);"b  0"
2650 PRINT TAB(9);"v";SPC(59);"t":PRINT TAB(9);"v";SPC(59);"t"
2660 PRINT TAB(5);"-30 b";SPC(59);"b -30"
2670 PRINT TAB(9);"v";SPC(59);"t":PRINT TAB(9);"v";SPC(59);"t"
2680 PRINT TAB(5);"-60 v";SPC(59);"t -60"
2690 PRINT TAB(9);"v";SPC(59);"t":PRINT TAB(9);"v";SPC(59);"t"
2700 PRINT "     -90 buuuubuuuubuuuubuuuubuuuubuuuubuuuubuuuubuuuubuuuubuuuubuuuub -90"
2710 PRINT "        -90  -75  -60  -45  -30  -15   0   +15  +30  +45  +60  +75  +90"
2720 REM
2730 REM ......................INPUT CONTROL SCAN ROUTINE...................
2740 REM
2750 CD=200+INT(200*RND(1)):FL$="5"
2760 IF CT=CD THEN 3910 ELSE CT=CT+1
2770 IF FL$="0" THEN 2950
2780 IF INP(17)=48 AND FL$<>"0" THEN FL$=INPUT$(1)
2790 IF INP(17)=49 AND FL$<>"1" THEN FL$=INPUT$(1)
2800 IF INP(17)=50 AND FL$<>"2" THEN FL$=INPUT$(1)
2810 IF INP(17)=51 AND FL$<>"3" THEN FL$=INPUT$(1)
2820 IF INP(17)=52 AND FL$<>"4" THEN FL$=INPUT$(1)
2830 IF INP(17)=53 AND FL$<>"5" THEN FL$=INPUT$(1)
2840 IF INP(17)=54 AND FL$<>"6" THEN FL$=INPUT$(1)
2850 IF INP(17)=55 AND FL$<>"7" THEN FL$=INPUT$(1)
2860 IF INP(17)=56 AND FL$<>"8" THEN FL$=INPUT$(1)
2870 IF INP(17)=57 AND FL$<>"9" THEN FL$=INPUT$(1)
2880 IF INP(17)<48 OR INP(17)>57 AND DM$<>CHR$(INP(17)) THEN DM$=INPUT$(1)
2890 GOSUB 3340:REM ..FIGHTER UPDATE
2900 PRINT CHR$(27);"Y&3+";CHR$(27);"Y23+";CHR$(27);"Y)=+";CHR$(27);"Y/=+";CHR$(27);"Y,G+";CHR$(27);"Y)Q+";CHR$(27);"Y/Q+";CHR$(27);"Y&[+";CHR$(27);"Y2[+"
2910 GOTO 2760
2920 REM
2930 REM .......................FIRE WEAPON ROUTINE........................
2940 REM
2950 FOR I=8 TO 1 STEP -1
2960 PRINT CHR$(27);"Y";CHR$(44+I);CHR$(71-I);"x"
2970 PRINT CHR$(27);"Y";CHR$(44+I);CHR$(71+I);"y"
2980 IF I > 6 THEN 3010
2990 PRINT CHR$(27);"Y";CHR$(46+I);CHR$(69-I);" "
3000 PRINT CHR$(27);"Y";CHR$(46+I);CHR$(73+I);" "
3010 NEXT I
3020 PRINT CHR$(27);"Y.E ";CHR$(27);"Y.I ";CHR$(27);"Y-F ";CHR$(27);"Y-H "
3030 IF FX<>44 OR FY<>70 THEN 3190
3040 IF KM>5000 THEN 2790
3050 PRINT CHR$(27);"p";CHR$(27);"Y8? ENEMY DESTROYED ":DG=0
3060 PRINT CHR$(27);"p":ED=ED+1
3070 PRINT CHR$(27);"Y";CHR$(FX-1);CHR$(FY);"ppp"
3080 PRINT CHR$(27);"Y";CHR$(FX);CHR$(FY-1);"     "
3090 PRINT CHR$(27);"q";CHR$(27);"Y";CHR$(FX+1);CHR$(FY);"ppp"
3100 FOR I=1 TO 25:PRINT CHR$(7);:NEXT I
3110 PRINT CHR$(27);"Y";CHR$(FX);CHR$(FY);"iii"
3120 FOR I=1 TO 25: NEXT I
3130 PRINT CHR$(27);"Y";CHR$(FX-1);CHR$(FY);"   "
3140 PRINT CHR$(27);"Y";CHR$(FX);CHR$(FY-1);" iii "
3150 PRINT CHR$(27);"Y";CHR$(FX+1);CHR$(FY);"   "
3160 FOR I=1 TO 25: NEXT I
3170 PRINT CHR$(27);"Y";CHR$(FX);CHR$(FY);"   "
3180 FQ=0:IF ED=5 THEN 3860 ELSE 2790
3190 IF FX<43 OR FX>45 THEN 3310
3200 IF FY<68 OR FY>72 THEN 3310
3210 LET DG=DG+1:IF DG=3 THEN 3050
3220 PRINT CHR$(27);"Y";CHR$(FX-1);CHR$(FY);"iii"
3230 PRINT CHR$(27);"Y";CHR$(FX);CHR$(FY-1);"i"
3240 PRINT CHR$(27);"Y";CHR$(FX);CHR$(FY+3);"i"
3250 PRINT CHR$(27);"Y";CHR$(FX+1);CHR$(FY);"iii"
3260 FOR I=1 TO 250: NEXT I
3270 PRINT CHR$(27);"Y";CHR$(FX-1);CHR$(FY);"   "
3280 PRINT CHR$(27);"Y";CHR$(FX);CHR$(FY-1);" "
3290 PRINT CHR$(27);"Y";CHR$(FX);CHR$(FY+3);" "
3300 PRINT CHR$(27);"Y";CHR$(FX+1);CHR$(FY);"   ":GOTO 2790
3310 PRINT CHR$(27);"Y8 ";CHR$(27);"l"
3320 GOTO 2790
3330 REM
3340 REM ...................FIGHTER POSITION UPDATE ROUTINE................
3350 REM
3360 IF FQ=1 THEN 3430 ELSE FQ=1
3370 LET FX=INT(100*RND(1))
3380 IF FX<36 OR FX>52 THEN 3370
3390 LET FY=INT(200*RND(1))
3400 IF FY<44 OR FY>97 THEN 3390
3410 LET KM=INT(10000*RND(1))
3420 FZ=INT(16*RND(1))
3430 IF INT(100*RND(1))>6 THEN 3450
3440 FZ=INT (16*RND(1))
3450 IF INT(10*RND(1))<A9 THEN 3460 ELSE X=FX:Y=FY:GOTO 3620
3460 IF FZ<>0 THEN 3470 ELSE X=FX-1:Y=FY+1
3470 IF FZ<>1 THEN 3480 ELSE S=FX:Y=FY+1
3480 IF FZ<>2 THEN 3490 ELSE X=FX+1:Y=FY+1
3490 IF FZ<>3 THEN 3500 ELSE X=FX+1:Y=FY
3500 IF FZ<>4 THEN 3510 ELSE X=FX+1:Y=FY-1
3510 IF FZ<>5 THEN 3520 ELSE X=FX:Y=FY-1
3520 IF FZ<>6 THEN 3530 ELSE X=FX-1:Y=FY-1
3530 IF FZ<>7 THEN 3540 ELSE X=FX-1:Y=FY
3540 IF FZ<>8 THEN 3550 ELSE X=FX-1:Y=FY+2
3550 IF FZ<>9 THEN 3560 ELSE X=FX-1:Y=FY+3
3560 IF FZ<>10 THEN 3570 ELSE X=FX+1:Y=FY+3
3570 IF FZ<>11 THEN 3580 ELSE X=FX+1:Y=FY+2
3580 IF FZ<>12 THEN 3590 ELSE X=FX+1:Y=FY-2
3590 IF FZ<>13 THEN 3600 ELSE X=FX+1:Y=FY-3
3600 IF FZ<>14 THEN 3610 ELSE X=FX-1:Y=FY-3
3610 IF FZ<>15 THEN 3620 ELSE X=FX-1:Y=FY-2
3620 IF FL$<>"1" THEN 3630 ELSE X=X-1:Y=Y+1
3630 IF FL$<>"2" THEN 3640 ELSE X=X-2:Y=Y
3640 IF FL$<>"3" THEN 3650 ELSE X=X-1:Y=Y-1
3650 IF FL$<>"4" THEN 3660 ELSE X=X:Y=Y+2
3660 IF FL$<>"6" THEN 3670 ELSE X=X:Y=Y-2
3670 IF FL$<>"7" THEN 3680 ELSE X=X+1:Y=Y+1
3680 IF FL$<>"8" THEN 3690 ELSE X=X+2:Y=Y
3690 IF FL$<>"9" THEN 3700 ELSE X=X+1:Y=Y-1
3700 IF X>39 AND X<50 AND Y>55 AND Y<87 THEN 3740
3710 IF SGN(KM)=+1 THEN KM=KM+INT(200*RND(1))
3720 IF SGN(KM)=-1 THEN KM=KM-INT(200*RND(1))
3730 IF KM<10000 THEN 3760 ELSE 3830
3740 IF SGN(KM)=+1 THEN KM=KM-INT(200*RND(1))
3750 IF SGN(KM)=-1 THEN KM=KM+INT(200*RND(1))
3760 IF X<36 OR X>52 OR Y<42 OR Y>98 THEN 3830
3770 IF X=FX AND Y=FY THEN RETURN
3780 PRINT CHR$(27);"Y";CHR$(FX);CHR$(FY);"   ":FX=X:FY=Y
3790 PRINT CHR$(27);"Y";CHR$(FX);CHR$(FY);"v^t"
3800 PRINT CHR$(27);"Y 5";KM
3810 EV=10*(44-FX):PRINT CHR$(27);"Y K";EV
3820 BR=3*(FY-70):PRINT CHR$(27);"Y \";BR:RETURN
3830 PRINT CHR$(27);"Y";CHR$(FX);CHR$(FY);"   "
3840 FQ=0:RETURN
3850 PRINT CHR$(27);"Y8 ";CHR$(27);"l":RETURN
3860 FOR I=1 TO 500:NEXT I:PRINT CHR$(27);"y1";CHR$(27);"Y  ";CHR$(27);"E"
3870 PRINT CHR$(27);"q";CHR$(27);"Y( ";CHR$(27);"G"
3880 PRINT ,"CONGRATULATIONS ON A JOB WELL DONE.  YOU HAVE"
3890 PRINT ,"DESTROYED DARTH VADER AND HIS STORM TROOPERS "
3900 PRINT ,"AND HAVE SAVED THE REBELLION.":GOTO 3950
3910 PRINT CHR$(27);"E";CHR$(27);"Y( "
3920 PRINT ,"YOU HAVE ONLY DESTROYED";ED;"TIE FIGHTERS AND";CHR$(27);"y1"
3930 PRINT ,"YOU LET DARTH VADER GET AWAY. OH WELL,I GUESS";CHR$(27);"G"
3940 PRINT ,"WE WANT HIM AROUND FOR THE SEQUEL ANYWAY!"
3950 PRINT:PRINT ,"DO YOU WANT TO PLAY AGAIN <Y or N>?"
3960 A$=INPUT$(1):IF A$="Y"THEN 1820ELSE IF A$<>"N"THEN 3960ELSE 1000
950 PRINT:PRINT ,"DO YOU WANT TO PLAY AGAIN <Y or N>?"
3960 A$=INPUT$(1):IF A$="Y"THEN 1820ELSE IF A$<>