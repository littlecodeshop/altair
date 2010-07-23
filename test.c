#include <stdio.h>

union{
unsigned short HL;
struct {
unsigned char l;
unsigned char h;
} B;
} reg;

main(){

printf("%d",11>9);
reg.HL = 0x1234;
printf("%4x %2x %2x",reg.HL,reg.B.h,reg.B.l);
}
