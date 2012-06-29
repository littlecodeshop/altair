3 rem Date: Tue, 20 Sep 1994 15:56:19 GMT
4 rem Since this is a classic program and the listing was posted to
5 rem alt.folklore.computers I will take the liberty to repost it here. 
10 rem THIS IS ELIZA.
20 rem cls : rem RC = CMS('CLRSCRN')
30 rem  ----- INITIALIZATION -----
40 dim s1(36),r(36),n(36)
50 n1 = 36
60 n2 = 14
70 n3 = 112
80 for x = 1 to n1+n2+n3
90   read z$
100   next x
110 rem SAME AS RESTORE
120 for x = 1 to n1
130   read s1(x),l
140   r(x) = s1(x)
150   n(x) = s1(x)+l-1
160   next x
170 print "HI! I'M ELIZA. WHAT'S YOUR PROBLEM?"
180 rem
190 rem ----- USER INPUT SECTION -----
200 rem
210 input i$
211 if i$ = "" then print "SPEAK UP. I CAN'T HEAR YOU." : goto 210
220 i$ = " "+i$+" " : i$ = uprc$(" "+i$+" ")
221     rem for k=1 to len(l$) : if mid$(l$,k,1) >= "a" then mid$(l$,k,1) = chr$(asc(mid$(l$,k,1))-32)
222     rem next k
230 if idx(i$,"SHUT") > 0 then stop
232 rem IF instr(I$,'SHUT') > 0 THEN STOP
240 rem  GET RID OF APOSTROPHES
250 i$ = srep$(i$,"'","")
260 if i$ = p$ then print "I HEARD YOU THE FIRST TIME." : goto 180
300 rem
310 rem ----- FIND KEYWORD IN I$ -----
320 rem
330 restore
340 s = 0
350 for k = 1 to n1
360   read k$
370   if s > 0 then 430
380 for l = 1 to len(i$)-len(k$)+1
390   if mstr$(i$,l,len(k$)) = k$ then s = k
400   t = l
410   f$ = k$
420 next l
430 next k
440 if s > 0 then k = s
450 if s > 0 then l = t
460 if s > 0 then goto 510
470 k = 36
480 goto 840
490 rem WE DID'NT FIND ANY KEYWORDS
500 rem  **********************************************
510 rem  * TAKE RIGHT PART OF STRING AND CONJUGATE IT *
520 rem  * USING THE LIST OF STRINGS TO BE SWAPPED    *
530 rem  **********************************************
540 restore
550 for x = 1 to n1
560   read z$
570   next x
580 rem SKIP OVER KEYWORDS
590 x = len(i$)-len(f$)-l+1
600 c$ = " "+mstr$(i$,len(i$)-x+1,x)+" "
610 for x = 1 to n2/2
620   read s$,r$
630     for l = 1 to len(c$)
640     if l+len(s$) > len(c$) then 700
650     if mstr$(c$,l,len(s$)) <> s$ then 700
660     xx = len(c$)-l-len(s$)+1
670     c$ = mstr$(c$,1,l-1)+r$+mstr$(c$,len(c$)-xx+1,xx)
680     l = l+len(r$)
690     goto 750
700     if l+len(r$) > len(c$) then 750
710     if mstr$(c$,l,len(r$)) <> r$ then 750
720     xx = len(c$)-l-len(r$)+1
730     c$ = mstr$(c$,l,l-1)+s$+mstr$(c$,len(c$)-xx+1,xx)
740     l = l+len(s$)
750     next l
760   next x
770 if mstr$(c$,2,1) = " " then c$ = mstr$(c$,1,len(c$)-1)
780 rem ONLY 1 SPACE
790 for l = 1 to len(c$)
800 c$ = srep$(i$,"!","")
810 if mstr$(c$,l,1) = "!" then 800
820 next l
830 rem
840 rem NOW USING THE KEYWORD NUMBER(K) GET REPLY
850 rem
860 restore
870 for x = 1 to n1+n2
880  read z$
890  next x
900 for x = 1 to r(k)
910   read f$
920   next x
930 rem READ AND WRITE REPLY
940 r(k) = r(k)+1
950 if r(k) > n(k) then r(k) = s1(k)
960 if mstr$(f$,len(f$),1) <> "*" then print f$
970 if mstr$(f$,len(f$),1) <> "*" then p$ = i$
980 if mstr$(f$,len(f$),1) <> "*" then 180
990 print mstr$(f$,1,len(f$)-1);c$
1000 p$ = i$
1010 goto 180
1020 rem
1030 rem ----- PROGRAM DATA FOLLOWS -----
1040 rem
1050 rem KEYWORDS
1060 rem
1070 data "CAN YOU","CAN I","YOU ARE","YOURE","I DONT","I FEEL"
1080 data "WHY DONT YOU","WHY CANT I","ARE YOU","I CANT","I AM","IM "
1090 data "YOU ","I WANT","WHAT","HOW","WHO","WHERE","WHEN","WHY"
1100 data "NAME","CAUSE","SORRY","DREAM","HELLO","HI ","MAYBE"
1110 data " NO","YOUR","ALWAYS","THINK","ALIKE","YES","FRIEND"
1120 data "COMPUTER","NOKEYFOUND"
1130 rem
1140 rem STRING DATA FOR CONJUGATIONS
1150 rem
1160 data " ARE "," AM ","WERE","WAS "," YOU "," I ","YOUR","MY "
1170 data " IVE "," YOUVE "," IM "," YOURE "
1180 data " ME "," IYOU "
1190 rem
1200 rem REPLIES
1210 rem
1220 data "DON'T YOU BELIEVE THAT I CAN*"
1230 data "PERHAPS YOU WOULD LIKE TO BE ABLE TO*"
1240 data "YOU WANT ME TO BE ABLE TO*"
1250 data "PERHAPS YOU DON'T WANT TO*"
1260 data "DO YOU WANT TO BE ABLE TO*"
1270 data "WHAT MAKES YOU THINK I AM*"
1280 data "DOES IT PLEASE YOU TO BELIEVE I AM*"
1290 data "PERHAPS YOU WOULD LIKE TO BE*"
1300 data "DO YOU SOMETIMES WISH YOU WERE*"
1310 data "DON'T YOU REALLY*"
1320 data "WHY DON'T YOU*"
1330 data "DO YOU WISH TO BE ABLE TO*"
1340 data "DOES THAT TROUBLE YOU?"
1350 data "TELL ME MORE ABOUT SUCH FEELINGS."
1360 data "DO YOU OFTEN FEEL*"
1370 data "DO YOU ENJOY FEELING*"
1380 data "DO YOU REALLY BELIEVE I DON'T*"
1390 data "PERHAPS IN GOOD TIME I WILL*"
1400 data "DO YOU WANT ME TO"
1410 data "DO YOU THINK YOU SHOULD BE ABLE TO*"
1420 data "WHY CAN'T YOU*"
1430 data "WHY ARE YOU INTERESTED IN WHETHER OR NOT I AM*"
1440 data "WOULD YOU PREFER IF I WERE NOT*"
1450 data "PERHAPS IN YOUR FANTASIES I AM*"
1460 data "HOW DO YOU KNOW YOU CAN'T*"
1470 data "HAVE YOU TRIED?"
1480 data "PERHAPS YOU CAN NOW*"
1490 data "DID YOU COME TO ME BECAUSE YOU ARE*"
1500 data "HOW LONG HAVE YOU BEEN*"
1510 data "DO YOU BELIEVE IT IS NORMAL TO BE*"
1520 data "DO YOU ENJOY BEING*"
1530 data "WE WERE DISCUSSING YOU -- NOT ME."
1540 data "OH, I*"
1550 data "YOU'RE NOT REALLY TALKING ABOUT ME, ARE YOU?"
1560 data "WHAT WOULD IT MEAN TO YOU IF YOU GOT*"
1570 data "WHY DO YOU WANT*"
1580 data "SUPPOSE YOU SOON GOT*"
1590 data "WHAT IF YOU NEVER GOT*"
1600 data "I SOMETIMES ALSO WANT*"
1610 data "WHY DO YOU ASK?"
1620 data "DOES THAT QUESTION INTEREST YOU?"
1630 data "WHAT ANSWER WOULD PLEASE YOU THE MOST?"
1640 data "WHAT DO YOU THINK?"
1650 data "ARE SUCH QUESTIONS ON YOU MIND OFTEN?"
1660 data "WHAT IS IT THAT YOU REALLY WANT TO KNOW?"
1670 data "HAVE YOU ASKED ANYONE ELSE?"
1680 data "HAVE YOU ASKED SUCH QUESTIONS BEFORE?"
1690 data "WHAT ELSE COMES TO MIND WHEN YOU ASK THAT?"
1700 data "NAMES DON'T INTEREST ME."
1710 data "I DON'T CARE ABOUT NAMES -- PLEASE GO ON."
1720 data "IS THAT THE REAL REASON?"
1730 data "DON'T ANY OTHER REASONS COME TO MIND?"
1740 data "DOES THAT REASON EXPLAIN ANYTHING ELSE?"
1750 data "WHAT OTHER REASONS MIGHT THERE BE?"
1760 data "PLEASE DON'T APOLOGIZE!"
1770 data "APOLOGIES ARE NOT NECESSARY."
1780 data "WHAT FEELINGS DO YOU HAVE WHEN YOU APOLOGIZE?"
1790 data "DON'T BE SO DEFENSIVE!"
1800 data "WHAT DOES THAT DREAM SUGGEST TO YOU?"
1810 data "DO YOU DREAM OFTEN?"
1820 data "WHAT PERSON APPEARS IN YOUR DREAMS?"
1830 data "ARE YOU DISTURBED BY YOUR DREAMS?"
1840 data "HOW DO YOU DO ... PLEASE STATE YOUR PROBLEM."
1850 data "YOU DON'T SEEM QUITE CERTAIN."
1860 data "WHY THE UNCERTAIN TONE?"
1870 data "CAN'T YOU BE MORE POSITIVE?"
1880 data "YOU AREN'T SURE?"
1890 data "DON'T YOU KNOW?"
1900 data "ARE YOU SAYING NO JUST TO BE NEGATIVE?"
1910 data "YOU ARE BEING A BIT NEGATIVE."
1920 data "WHY NOT?"
1930 data "ARE YOU SURE?"
1940 data "WHY NO?"
1950 data "WHY ARE YOU CONCERNED ABOUT MY*"
1960 data "WHAT ABOUT YOUR OWN*"
1970 data "CAN YOU THINK OF A SPECIFIC EXAMPLE?"
1980 data "WHEN?"
1990 data "WHAT ARE YOU THINKING OF?"
2000 data "REALLY, ALWAYS?"
2010 data "DO YOU REALLY THINK SO?"
2020 data "BUT YOU ARE NOT SURE YOU*"
2030 data "DO YOU DOUBT YOU*"
2040 data "IN WHAT WAY?"
2050 data "WHAT RESEMBLENCE DO YOU SEE?"
2060 data "WHAT DOES THE SIMILARITY SUGGEST TO YOU?"
2070 data "WHAT OTHER CONNECTIONS DO YOU SEE?"
2080 data "COULD THERE REALLY BE SOME CONNECTION?"
2090 data "HOW?"
2100 data "YOU SEEM QUITE POSITIVE."
2110 data "ARE YOU SURE?"
2120 data "I SEE."
2130 data "I UNDERSTAND."
2140 data "WHY DO YOU BRING UP THE TOPIC OF FRIENDS?"
2150 data "DO YOU FRIENDS WORRY YOU?"
2160 data "DO YOUR FRIENDS PICK ON YOU?"
2170 data "ARE YOU SURE YOU HAVE ANY FRIENDS?"
2180 data "DO YOU IMPOSE ON YOUR FRIENDS?"
2190 data "PERHAPS YOUR LOVE FOR FRIENDS WORRIES YOU."
2200 data "DO COMPUTERS WORRY YOU?"
2210 data "ARE YOU TALKING ABOUT ME IN PARTICULAR?"
2220 data "ARE YOU FRIGHTENED BY MACHINES?"
2230 data "WHY DO YOU MENTION COMPUTERS?"
2240 data "WHAT DO YOU THINK MACHINES HAVE TO DO WITH YOUR PROBLEM?"
2250 data "DON'T YOU THINK COMPUTERS CAN HELP PEOPLE?"
2260 data "WHAT IS IT ABOUT MACHINES THAT WORRIES YOU?"
2270 data "SAY, DO YOU HAVE ANY PSYCHOLOGICAL PROBLEMS?"
2280 data "WHAT DOES THAT SUGGEST TO YOU?"
2290 data "I SEE."
2300 data "I'M NOT SURE I UNDERSTAND YOU FULLY."
2310 data "COME COME ELUCIDATE YOUR THOUGHTS."
2320 data "CAN YOU ELABORATE ON THAT?"
2330 data "THAT IS QUITE INTERESTING."
2340 rem
2350 rem   DATA FOR FINDING RIGHT REPLIES
2360 rem
2370 data 1,3,4,2,6,4,6,4,10,4,14,3,17,3,20,2,22,3,25,3
2380 data 28,4,28,4,32,3,35,5,40,9,40,9,40,9,40,9,40,9,40,9
2390 data 49,2,51,4,55,4,59,4,63,1,63,1,64,5,69,5,74,2,76,4
2400 data 80,3,83,7,90,3,93,6,99,7,106,6
8000 sub uprc$(a$,b$,i,c)
8010 b$ = ""
8020 for i = 1 to len(a$)
8030   c = asc(mid$(a$,i,1)) : if c > 96 then c = c-32
8040   b$ = b$+chr$(c)
8050 next i
8090 return(b$)
8100 sub idx(a$,b$,i)
8110 i = instr(a$,b$)
8190 return(i)
8200 sub srep$(a$,f$,t$,b$,i,c$)
8210 b$ = ""
8220 for i = 1 to len(a$)
8230   c$ = mid$(a$,i,1) : if c$ = f$ then c$ = t$
8240   b$ = b$+c$
8250 next i
8290 return(b$)
8300 sub mstr$(a$,b,n,r$)
8310 r$ = mid$(a$,b,n)
8390 return(r$)
9990 end
