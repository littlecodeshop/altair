100 PRINT "Interface Age Prime-Number Benchmark Program"
110 FOR N=1 TO 1000
120 FOR K=2 TO 500
130 M=N/K
140 L=INT(M)
150 IF L=0 THEN 200
160 IF L=1 THEN 190
170 IF M>L THEN 190
180 IF M=L THEN 210
190 NEXT  K
200 PRINT N
210 NEXT  N
220 PRINT
230 PRINT
240 PRINT "Done"
250 END