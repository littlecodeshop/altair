#include <stdio.h>
#include <stdlib.h>

//OpenGL includes

#include <OpenGL/gl.h>
#include <OpenGL/glu.h>
#include <GLUT/glut.h>

static GLfloat spin = 0.0;
int starttrace=0;
#define DEBUG
/* Macro for printing debug info */
#ifdef DEBUG
#define DEBUG_PRINT(fmt, args...)    fprintf(stderr,fmt, ## args)
#else
#define DEBUG_PRINT(fmt, args...)    /* Don't do anything in release builds */
#endif

/* The memory of the venerable MITS Altair 8800 */
unsigned char mem[0xFFFF];

/* Bit manipulation and parity tables */
#define BIT(n)                  ( 1<<(n) )

#define BIT_SET(y, mask)        ( y |=  (mask) )
#define BIT_CLEAR(y, mask)      ( y &= ~(mask) )
#define BIT_FLIP(y, mask)       ( y ^=  (mask) )




  /*
   Set bits        Clear bits      Flip bits
   y        0x0011          0x0011          0x0011
   mask     0x0101 |        0x0101 &~       0x0101 ^
   	    ---------       ----------      ---------
   result   0x0111          0x0010          0x0110
   */

////////////////////////////////////////////////////////////////////////////////
//    Examples:
//    mask= BIT(0) | BIT(8);      // Create mask with bit 0 and 8 set (0x0101)

//    BIT_SET(y, mask);           // Bits 0 and 8 of y have been set.
//    BIT_CLEAR(y, mask);         // Bits 0 and 8 of y have been cleared.
//    BIT_FLIP(y, mask);          // Bits 0 and 8 of y have been flipped.


unsigned char ParityTable256[256] = 
{
#   define P2(n) n, n^1, n^1, n
#   define P4(n) P2(n), P2(n^1), P2(n^1), P2(n)
#   define P6(n) P4(n), P4(n^1), P4(n^1), P4(n)
    P6(0), P6(1), P6(1), P6(0)
};

/* Tx Rx values */
#define RxStat_BIT	0x01	// Ready to receive
#define TxStat_BIT	0x02	// Ready to transmit

/* i8080 CPU */
/* opcode cycles */
static const unsigned char lut_cycles[0x100]={
    4, 10,7, 5, 5, 5, 7, 4, 0, 10,7, 5, 5, 5, 7, 4,
    0, 10,7, 5, 5, 5, 7, 4, 0, 10,7, 5, 5, 5, 7, 4,
    0, 10,16,5, 5, 5, 7, 4, 0, 10,16,5, 5, 5, 7, 4,
    0, 10,13,5, 10,10,10,4, 0, 10,13,5, 5, 5, 7, 4,
    5, 5, 5, 5, 5, 5, 7, 5, 5, 5, 5, 5, 5, 5, 7, 5,
    5, 5, 5, 5, 5, 5, 7, 5, 5, 5, 5, 5, 5, 5, 7, 5,
    5, 5, 5, 5, 5, 5, 7, 5, 5, 5, 5, 5, 5, 5, 7, 5,
    7, 7, 7, 7, 7, 7, 7, 7, 5, 5, 5, 5, 5, 5, 7, 5,
    4, 4, 4, 4, 4, 4, 7, 4, 4, 4, 4, 4, 4, 4, 7, 4,
    4, 4, 4, 4, 4, 4, 7, 4, 4, 4, 4, 4, 4, 4, 7, 4,
    4, 4, 4, 4, 4, 4, 7, 4, 4, 4, 4, 4, 4, 4, 7, 4,
    4, 4, 4, 4, 4, 4, 7, 4, 4, 4, 4, 4, 4, 4, 7, 4,
    5, 10,10,10,11,11,7, 11,5, 10,10,0, 11,17,7, 11,
    5, 10,10,10,11,11,7, 11,5, 0, 10,10,11,0, 7, 11,
    5, 10,10,18,11,11,7, 11,5, 5, 10,4, 11,0, 7, 11,
    5, 10,10,4, 11,11,7, 11,5, 5, 10,4, 11,0, 7, 11
};

static unsigned char lut_parity[0x100]; /* quick parity flag lookuptable, 4: even, 0: uneven */


/* opcode mnemonics (debug) */
#ifdef DEBUG
static const char* lut_mnemonic[0x100]={
    "nop",     "lxi b,#", "stax b",  "inx b",   "inr b",   "dcr b",   "mvi b,#", "rlc",     "ill",     "dad b",   "ldax b",  "dcx b",   "inr c",   "dcr c",   "mvi c,#", "rrc",
    "ill",     "lxi d,#", "stax d",  "inx d",   "inr d",   "dcr d",   "mvi d,#", "ral",     "ill",     "dad d",   "ldax d",  "dcx d",   "inr e",   "dcr e",   "mvi e,#", "rar",
    "ill",     "lxi h,#", "shld",    "inx h",   "inr h",   "dcr h",   "mvi h,#", "daa",     "ill",     "dad h",   "lhld",    "dcx h",   "inr l",   "dcr l",   "mvi l,#", "cma",
    "ill",     "lxi sp,#","sta $",   "inx sp",  "inr M",   "dcr M",   "mvi M,#", "stc",     "ill",     "dad sp",  "lda $",   "dcx sp",  "inr a",   "dcr a",   "mvi a,#", "cmc",
    "mov b,b", "mov b,c", "mov b,d", "mov b,e", "mov b,h", "mov b,l", "mov b,M", "mov b,a", "mov c,b", "mov c,c", "mov c,d", "mov c,e", "mov c,h", "mov c,l", "mov c,M", "mov c,a",
    "mov d,b", "mov d,c", "mov d,d", "mov d,e", "mov d,h", "mov d,l", "mov d,M", "mov d,a", "mov e,b", "mov e,c", "mov e,d", "mov e,e", "mov e,h", "mov e,l", "mov e,M", "mov e,a",
    "mov h,b", "mov h,c", "mov h,d", "mov h,e", "mov h,h", "mov h,l", "mov h,M", "mov h,a", "mov l,b", "mov l,c", "mov l,d", "mov l,e", "mov l,h", "mov l,l", "mov l,M", "mov l,a",
    "mov M,b", "mov M,c", "mov M,d", "mov M,e", "mov M,h", "mov M,l", "hlt",     "mov M,a", "mov a,b", "mov a,c", "mov a,d", "mov a,e", "mov a,h", "mov a,l", "mov a,M", "mov a,a",
    "add b",   "add c",   "add d",   "add e",   "add h",   "add l",   "add M",   "add a",   "adc b",   "adc c",   "adc d",   "adc e",   "adc h",   "adc l",   "adc M",   "adc a",
    "sub b",   "sub c",   "sub d",   "sub e",   "sub h",   "sub l",   "sub M",   "sub a",   "sbb b",   "sbb c",   "sbb d",   "sbb e",   "sbb h",   "sbb l",   "sbb M",   "sbb a",
    "ana b",   "ana c",   "ana d",   "ana e",   "ana h",   "ana l",   "ana M",   "ana a",   "xra b",   "xra c",   "xra d",   "xra e",   "xra h",   "xra l",   "xra M",   "xra a",
    "ora b",   "ora c",   "ora d",   "ora e",   "ora h",   "ora l",   "ora M",   "ora a",   "cmp b",   "cmp c",   "cmp d",   "cmp e",   "cmp h",   "cmp l",   "cmp M",   "cmp a",
    "rnz",     "pop b",   "jnz $",   "jmp $",   "cnz $",   "push b",  "adi #",   "rst 0",   "rz",      "ret",     "jz $",    "ill",     "cz $",    "call $",  "aci #",   "rst 1",
    "rnc",     "pop d",   "jnc $",   "out p",   "cnc $",   "push d",  "sui #",   "rst 2",   "rc",      "ill",     "jc $",    "in p",    "cc $",    "ill",     "sbi #",   "rst 3",
    "rpo",     "pop h",   "jpo $",   "xthl",    "cpo $",   "push h",  "ani #",   "rst 4",   "rpe",     "pchl",    "jpe $",   "xchg",    "cpe $",   "ill",     "xri #",   "rst 5",
    "rp",      "pop psw", "jp $",    "di",      "cp $",    "push psw","ori #",   "rst 6",   "rm",      "sphl",    "jm $",    "ei",      "cm $",    "ill",     "cpi #",   "rst 7"
};
#endif

static struct {

    union {
	struct {
	    unsigned short pc;              /* programcounter */
	    unsigned short sp;              /* stackpointer */
	    unsigned short psw,bc,de,hl;    /* register pairs */
	};
	struct {
	    unsigned char pc_low,pc_high;
	    unsigned char sp_low,sp_high;
	    unsigned char flags;            /* sz0a0p1c */
	    unsigned char a,c,b,e,d,l,h;    /* regs */
	};
    } reg;

    int cycles;
    unsigned short result;                          /* temp result */
    unsigned char i;                                /* interrupt bit */
    unsigned char ipend;                            /* pending int */
    unsigned char a;                                /* aux carry bit */
} cpu;

#define A               cpu.reg.a
#define F               cpu.reg.flags
#define B               cpu.reg.b
#define C               cpu.reg.c
#define D               cpu.reg.d
#define E               cpu.reg.e
#define H               cpu.reg.h
#define L               cpu.reg.l
#define PC              cpu.reg.pc
#define PCL             cpu.reg.pc_low
#define PCH             cpu.reg.pc_high
#define SP              cpu.reg.sp
#define SPL             cpu.reg.sp_low
#define SPH             cpu.reg.sp_high
#define PSW             cpu.reg.psw
#define BC              cpu.reg.bc
#define DE              cpu.reg.de
#define HL              cpu.reg.hl
#define RES             cpu.result

#define ISNOTZERO()     ((RES&0xff)!=0)
#define ISZERO()        ((RES&0xff)==0)
#define ISNOTCARRY()    ((RES&0x100)==0)
#define ISCARRY()       ((RES&0x100)!=0)
#define ISPODD()        (lut_parity[RES&0xff]==0)
#define ISPEVEN()       (lut_parity[RES&0xff]!=0)
#define ISPLUS()        ((RES&0x80)==0)
#define ISMIN()         ((RES&0x80)!=0)

#define R8(a)           mem[(a)]
#define R16(a)          (R8((a)+1)<<8|(R8(a)))
#define W8(a,v)         mem[(a)]=v
#define PUSH16(v)       SP-=2; W8(SP,(v)&0xff); W8(SP+1,(v)>>8&0xff)
#define POP16()         R16(SP); SP+=2
#define JUMP()          PC=R16(PC)
#define CALL()          PUSH16(PC+2); JUMP()
#define CCON()          cpu.cycles-=6; CALL()
#define RET()           PC=POP16()
#define RCON()          cpu.cycles-=6; RET()
#define RST(x)          PUSH16(PC); PC=(x)<<3
#define FSZP(r)         RES=(RES&0x100)|r
#define INR(r)          r++; FSZP(r)
#define DCR(r)          r--; FSZP(r)
#define FAUX()          cpu.a=(A&0xf)>(RES&0xf)
#define ADD(r)          RES=A+r; FAUX(); A=RES&0xff
#define ADC(r)          RES=(RES>>8&1)+A+r; FAUX(); A=RES&0xff
#define DAD(r)          RES=(RES&0xff)|((r+HL)>>8&0x100); HL+=r
#define CMP(r)          RES=A-r; FAUX()
#define SUB(r)          CMP(r); A=RES&0xff
#define SBB(r)          RES=(A-r)-(RES>>8&1); FAUX(); A=RES&0xff
#define ANA(r)          RES=A=A&r
#define XRA(r)          RES=A=A^r
#define ORA(r)          RES=A=A|r


static unsigned char key=0;
unsigned char buffer[3];
int bcount = 0;

static unsigned char in_port(unsigned char port)
{
    unsigned char ret=port;

    //DEBUG_PRINT("--> IN port %X\n",port);
    switch (port) {
	case 0x00:
	    break;
	case 0x10:    
	    ret = TxStat_BIT;
	    /*if(_kbhit()){
		//check if it is a control caracter for DSK
		char c = _getch();
		buffer[0] = c;
		bcount = 1;
	    }*/
	    if(bcount)
		ret = ret|RxStat_BIT;
	    break;
	case 0x01:
	    if(bcount>0){
		ret = buffer[0];
		bcount = 0;
	    }
	    break;
	case 0x11:    
	    {
		unsigned char b = buffer[0];
		unsigned char parity = ParityTable256[b];
		if(parity){
		    unsigned char mask=0x80;
		    BIT_SET(b, mask); 
		}
		ret = b;
		bcount = 0;
	    }
	    break;
	default: 
	    ret=0x0;
	    break;
    }

    return ret;
}

static void out_port(unsigned char port,unsigned char v)
{
    switch (port) {

	case 0x1:
	case 0x11:
	    //DEBUG_PRINT("%c<-- OUT port %X\n",v&0x7F,port);
	    printf("%c",v&0x7F);
	    fflush(stdout);
	    break;
	default: 
	 //   DEBUG_PRINT("%c<-- OUT port %X\n",v,port);
	    break;

    }
}

/* INTERRUPTS */
static void interrupt(int i)
{
    DEBUG_PRINT("INTERUPTION\n");
    if (cpu.i) {
	cpu.i=cpu.ipend=0;
	cpu.cycles-=11;
	RST(i);
    }
    else cpu.ipend=0x80|i;
}

/* RUN CPU OPCODES */
static void cpu_run(int cycles)
{
    int opcode;

    cpu.cycles+=cycles;

    while (cpu.cycles>0) {
//if(cpu.reg.pc == 0x0C07) starttrace=1;
//	if(starttrace)
//	DEBUG_PRINT("%04x:%10s @pc:%02X RES:%04X a:%02X f:%02X b:%02X c:%02X d:%02X e:%02X h:%02X l:%02X sp:%04X\n",PC,lut_mnemonic[mem[PC]],mem[PC],RES,A,F,B,C,D,E,H,L,SP);
	opcode=R8(PC); PC++;
	cpu.cycles-=lut_cycles[opcode];

	switch (opcode) {
	    /* MOVE, LOAD, AND STORE */
	    case 0x40: break;                               /* mov b,b */
	    case 0x41: B=C; break;                          /* mov b,c */
	    case 0x42: B=D; break;                          /* mov b,d */
	    case 0x43: B=E; break;                          /* mov b,e */
	    case 0x44: B=H; break;                          /* mov b,h */
	    case 0x45: B=L; break;                          /* mov b,l */
	    case 0x46: B=R8(HL); break;                     /* mov b,M */
	    case 0x47: B=A; break;                          /* mov b,a */

	    case 0x48: C=B; break;                          /* mov c,b */
	    case 0x49: break;                               /* mov c,c */
	    case 0x4a: C=D; break;                          /* mov c,d */
	    case 0x4b: C=E; break;                          /* mov c,e */
	    case 0x4c: C=H; break;                          /* mov c,h */
	    case 0x4d: C=L; break;                          /* mov c,l */
	    case 0x4e: C=R8(HL); break;                     /* mov c,M */
	    case 0x4f: C=A; break;                          /* mov c,a */

	    case 0x50: D=B; break;                          /* mov d,b */
	    case 0x51: D=C; break;                          /* mov d,c */
	    case 0x52: break;                               /* mov d,d */
	    case 0x53: D=E; break;                          /* mov d,e */
	    case 0x54: D=H; break;                          /* mov d,h */
	    case 0x55: D=L; break;                          /* mov d,l */
	    case 0x56: D=R8(HL); break;                     /* mov d,M */
	    case 0x57: D=A; break;                          /* mov d,a */

	    case 0x58: E=B; break;                          /* mov e,b */
	    case 0x59: E=C; break;                          /* mov e,c */
	    case 0x5a: E=D; break;                          /* mov e,d */
	    case 0x5b: break;                               /* mov e,e */
	    case 0x5c: E=H; break;                          /* mov e,h */
	    case 0x5d: E=L; break;                          /* mov e,l */
	    case 0x5e: E=R8(HL); break;                     /* mov e,M */
	    case 0x5f: E=A; break;                          /* mov e,a */

	    case 0x60: H=B; break;                          /* mov h,b */
	    case 0x61: H=C; break;                          /* mov h,c */
	    case 0x62: H=D; break;                          /* mov h,d */
	    case 0x63: H=E; break;                          /* mov h,e */
	    case 0x64: break;                               /* mov h,h */
	    case 0x65: H=L; break;                          /* mov h,l */
	    case 0x66: H=R8(HL); break;                     /* mov h,M */
	    case 0x67: H=A; break;                          /* mov h,a */

	    case 0x68: L=B; break;                          /* mov l,b */
	    case 0x69: L=C; break;                          /* mov l,c */
	    case 0x6a: L=D; break;                          /* mov l,d */
	    case 0x6b: L=E; break;                          /* mov l,e */
	    case 0x6c: L=H; break;                          /* mov l,h */
	    case 0x6d: break;                               /* mov l,l */
	    case 0x6e: L=R8(HL); break;                     /* mov l,M */
	    case 0x6f: L=A; break;                          /* mov l,a */

	    case 0x70: W8(HL,B); break;                     /* mov M,b */
	    case 0x71: W8(HL,C); break;                     /* mov M,c */
	    case 0x72: W8(HL,D); break;                     /* mov M,d */
	    case 0x73: W8(HL,E); break;                     /* mov M,e */
	    case 0x74: W8(HL,H); break;                     /* mov M,h */
	    case 0x75: W8(HL,L); break;                     /* mov M,l */
		       /* mov M,M = hlt */
	    case 0x77: W8(HL,A); break;                     /* mov M,a */

	    case 0x78: A=B; break;                          /* mov a,b */
	    case 0x79: A=C; break;                          /* mov a,c */
	    case 0x7a: A=D; break;                          /* mov a,d */
	    case 0x7b: A=E; break;                          /* mov a,e */
	    case 0x7c: A=H; break;                          /* mov a,h */
	    case 0x7d: A=L; break;                          /* mov a,l */
	    case 0x7e: A=R8(HL); break;                     /* mov a,M */
	    case 0x7f: break;                               /* mov a,a */

	    case 0x06: B=R8(PC); PC++; break;               /* mvi b,# */
	    case 0x0e: C=R8(PC); PC++; break;               /* mvi c,# */
	    case 0x16: D=R8(PC); PC++; break;               /* mvi d,# */
	    case 0x1e: E=R8(PC); PC++; break;               /* mvi e,# */
	    case 0x26: H=R8(PC); PC++; break;               /* mvi h,# */
	    case 0x2e: L=R8(PC); PC++; break;               /* mvi l,# */
	    case 0x36: W8(HL,R8(PC)); PC++; break;          /* mvi M,# */
	    case 0x3e: A=R8(PC); PC++; break;               /* mvi a,# */

	    case 0x01: BC=R16(PC); PC+=2; break;            /* lxi b,# */
	    case 0x11: DE=R16(PC); PC+=2; break;            /* lxi d,# */
	    case 0x21: HL=R16(PC); PC+=2; break;            /* lxi h,# */

	    case 0x02: W8(BC,A); break;                     /* stax b */
	    case 0x12: W8(DE,A); break;                     /* stax d */
	    case 0x0a: A=R8(BC); break;                     /* ldax b */
	    case 0x1a: A=R8(DE); break;                     /* ldax d */
	    case 0x22: W8(R16(PC),L); W8(R16(PC)+1,H); PC+=2; break;        /* shld */
	    case 0x2a: L=R8(R16(PC)); H=R8(R16(PC)+1); PC+=2; break;        /* lhld */
	    case 0x32: W8(R16(PC),A); PC+=2; break;         /* sta $ */
	    case 0x3a: A=R8(R16(PC)); PC+=2; break;         /* lda $ */

	    case 0xeb: HL^=DE; DE^=HL; HL^=DE; break;       /* xchg */


		       /* STACK OPS */
	    case 0xc5: PUSH16(BC); break;                   /* push b */
	    case 0xd5: PUSH16(DE); break;                   /* push d */
	    case 0xe5: PUSH16(HL); break;                   /* push h */
	    case 0xf5: F=(RES>>8&1)|2|lut_parity[RES&0xff]|(cpu.a<<4)|(((RES&0xff)==0)<<6)|(RES&0x80); PUSH16(PSW); break;  /* push psw */

	    case 0xc1: BC=POP16(); break;                   /* pop b */
	    case 0xd1: DE=POP16(); break;                   /* pop d */
	    case 0xe1: HL=POP16(); break;                   /* pop h */
	    case 0xf1: PSW=POP16(); RES=(F<<8&0x100)|(lut_parity[F&0x80]!=(F&4))|(F&0x80)|((F&0x40)?0:6); cpu.a=F>>4&1; break;      /* pop psw */

	    case 0xe3: L^=R8(SP); W8(SP,R8(SP)^L); L^=R8(SP); H^=R8(SP+1); W8(SP+1,R8(SP+1)^H); H^=R8(SP+1); break; /* xthl */

	    case 0xf9: SP=HL; break;                        /* sphl */

	    case 0x31: SP=R16(PC); PC+=2; break;            /* lxi sp,# */

	    case 0x33: SP++; break;                         /* inx sp */
	    case 0x3b: SP--; break;                         /* dcx sp */


		       /* JUMP */
	    case 0xc3: JUMP(); break;                       /* jmp $ */

	    case 0xc2: if (ISNOTZERO()) JUMP(); else PC+=2; break;  /* jnz $ */
	    case 0xca: if (ISZERO()) JUMP(); else PC+=2; break;     /* jz $ */
	    case 0xd2: if (ISNOTCARRY()) JUMP(); else PC+=2; break; /* jnc $ */
	    case 0xda: if (ISCARRY()) JUMP(); else PC+=2; break;    /* jc $ */
	    case 0xe2: if (ISPODD()) JUMP(); else PC+=2; break;     /* jpo $ */
	    case 0xea: if (ISPEVEN()) JUMP(); else PC+=2; break;    /* jpe $ */
	    case 0xf2: if (ISPLUS()) JUMP(); else PC+=2; break;     /* jp $ */
	    case 0xfa: if (ISMIN()) JUMP(); else PC+=2; break;      /* jm $ */

	    case 0xe9: PC=HL; break;                        /* pchl */


		       /* CALL */
	    case 0xcd: CALL(); break;                       /* call $ */

	    case 0xc4: if (ISNOTZERO()) { CCON(); } else PC+=2; break;      /* cnz $ */
	    case 0xcc: if (ISZERO()) { CCON(); } else PC+=2; break;         /* cz $ */
	    case 0xd4: if (ISNOTCARRY()) { CCON(); } else PC+=2; break;     /* cnc $ */
	    case 0xdc: if (ISCARRY()) { CCON(); } else PC+=2; break;        /* cc $ */
	    case 0xe4: if (ISPODD()) { CCON(); } else PC+=2; break;         /* cpo $ */
	    case 0xec: if (ISPEVEN()) { CCON(); } else PC+=2; break;        /* cpe $ */
	    case 0xf4: if (ISPLUS()) { CCON(); } else PC+=2; break;         /* cp $ */
	    case 0xfc: if (ISMIN()) { CCON(); } else PC+=2; break;          /* cm $ */


			   /* RETURN */
	    case 0xc9: RET(); break;                        /* ret */

	    case 0xc0: if (ISNOTZERO()) { RCON(); } break;  /* rnz */
	    case 0xc8: if (ISZERO()) { RCON(); } break;     /* rz */
	    case 0xd0: if (ISNOTCARRY()) { RCON(); } break; /* rnc */
	    case 0xd8: if (ISCARRY()) { RCON(); } break;    /* rc */
	    case 0xe0: if (ISPODD()) { RCON(); } break;     /* rpo */
	    case 0xe8: if (ISPEVEN()) { RCON(); } break;    /* rpe */
	    case 0xf0: if (ISPLUS()) { RCON(); } break;     /* rp */
	    case 0xf8: if (ISMIN()) { RCON(); } break;      /* rm */


			   /* RESTART */
	    case 0xc7: case 0xcf: case 0xd7: case 0xdf: case 0xe7: case 0xef: case 0xf7: case 0xff:
			   RST(opcode>>3&7); break;                /* rst x */


			   /* INCREMENT AND DECREMENT */
	    case 0x04: INR(B); break;                       /* inr b */
	    case 0x0c: INR(C); break;                       /* inr c */
	    case 0x14: INR(D); break;                       /* inr d */
	    case 0x1c: INR(E); break;                       /* inr e */
	    case 0x24: INR(H); break;                       /* inr h */
	    case 0x2c: INR(L); break;                       /* inr l */
	    case 0x34: W8(HL,(R8(HL)+1)&0xff); FSZP(R8(HL)); break; /* inr M */
	    case 0x3c: INR(A); break;                       /* inr a */

	    case 0x05: DCR(B); break;                       /* dcr b */
	    case 0x0d: DCR(C); break;                       /* dcr c */
	    case 0x15: DCR(D); break;                       /* dcr d */
	    case 0x1d: DCR(E); break;                       /* dcr e */
	    case 0x25: DCR(H); break;                       /* dcr h */
	    case 0x2d: DCR(L); break;                       /* dcr l */
	    case 0x35: W8(HL,(R8(HL)+0xff)&0xff); FSZP(R8(HL)); break;      /* dcr M */
	    case 0x3d: DCR(A); break;                       /* dcr a */

	    case 0x03: BC++; break;                         /* inx b */
	    case 0x13: DE++; break;                         /* inx d */
	    case 0x23: HL++; break;                         /* inx h */

	    case 0x0b: BC--; break;                         /* dcx b */
	    case 0x1b: DE--; break;                         /* dcx d */
	    case 0x2b: HL--; break;                         /* dcx h */


		       /* ADD */
	    case 0x80: ADD(B); break;                       /* add b */
	    case 0x81: ADD(C); break;                       /* add c */
	    case 0x82: ADD(D); break;                       /* add d */
	    case 0x83: ADD(E); break;                       /* add e */
	    case 0x84: ADD(H); break;                       /* add h */
	    case 0x85: ADD(L); break;                       /* add l */
	    case 0x86: ADD(R8(HL)); break;                  /* add M */
	    case 0x87: ADD(A); break;                       /* add a */

	    case 0x88: ADC(B); break;                       /* adc b */
	    case 0x89: ADC(C); break;                       /* adc c */
	    case 0x8a: ADC(D); break;                       /* adc d */
	    case 0x8b: ADC(E); break;                       /* adc e */
	    case 0x8c: ADC(H); break;                       /* adc h */
	    case 0x8d: ADC(L); break;                       /* adc l */
	    case 0x8e: ADC(R8(HL)); break;                  /* adc M */
	    case 0x8f: ADC(A); break;                       /* adc a */

	    case 0xc6: ADD(R8(PC)); PC++; break;            /* adi # */
	    case 0xce: ADC(R8(PC)); PC++; break;            /* aci # */

	    case 0x09: DAD(BC); break;                      /* dad b */
	    case 0x19: DAD(DE); break;                      /* dad d */
	    case 0x29: DAD(HL); break;                      /* dad h */
	    case 0x39: DAD(SP); break;                      /* dad sp */


		       /* SUBTRACT */
	    case 0x90: SUB(B); break;                       /* sub b */
	    case 0x91: SUB(C); break;                       /* sub c */
	    case 0x92: SUB(D); break;                       /* sub d */
	    case 0x93: SUB(E); break;                       /* sub e */
	    case 0x94: SUB(H); break;                       /* sub h */
	    case 0x95: SUB(L); break;                       /* sub l */
	    case 0x96: SUB(R8(HL)); break;                  /* sub M */
	    case 0x97: SUB(A); break;                       /* sub a */

	    case 0x98: SBB(B); break;                       /* sbb b */
	    case 0x99: SBB(C); break;                       /* sbb c */
	    case 0x9a: SBB(D); break;                       /* sbb d */
	    case 0x9b: SBB(E); break;                       /* sbb e */
	    case 0x9c: SBB(H); break;                       /* sbb h */
	    case 0x9d: SBB(L); break;                       /* sbb l */
	    case 0x9e: SBB(R8(HL)); break;                  /* sbb M */
	    case 0x9f: SBB(A); break;                       /* sbb a */

	    case 0xd6: SUB(R8(PC)); PC++; break;            /* sui # */
	    case 0xde: SBB(R8(PC)); PC++; break;            /* sbi # */


		       /* LOGICAL */
	    case 0xa0: ANA(B); break;                       /* ana b */
	    case 0xa1: ANA(C); break;                       /* ana c */
	    case 0xa2: ANA(D); break;                       /* ana d */
	    case 0xa3: ANA(E); break;                       /* ana e */
	    case 0xa4: ANA(H); break;                       /* ana h */
	    case 0xa5: ANA(L); break;                       /* ana l */
	    case 0xa6: ANA(R8(HL)); break;                  /* ana M */
	    case 0xa7: ANA(A); break;                       /* ana a */

	    case 0xe6: ANA(R8(PC)); PC++; break;            /* ani # */

	    case 0xa8: XRA(B); break;                       /* xra b */
	    case 0xa9: XRA(C); break;                       /* xra c */
	    case 0xaa: XRA(D); break;                       /* xra d */
	    case 0xab: XRA(E); break;                       /* xra e */
	    case 0xac: XRA(H); break;                       /* xra h */
	    case 0xad: XRA(L); break;                       /* xra l */
	    case 0xae: XRA(R8(HL)); break;                  /* xra M */
	    case 0xaf: XRA(A); break;                       /* xra a */

	    case 0xee: XRA(R8(PC)); PC++; break;            /* xri # */

	    case 0xb0: ORA(B); break;                       /* ora b */
	    case 0xb1: ORA(C); break;                       /* ora c */
	    case 0xb2: ORA(D); break;                       /* ora d */
	    case 0xb3: ORA(E); break;                       /* ora e */
	    case 0xb4: ORA(H); break;                       /* ora h */
	    case 0xb5: ORA(L); break;                       /* ora l */
	    case 0xb6: ORA(R8(HL)); break;                  /* ora M */
	    case 0xb7: ORA(A); break;                       /* ora a */

	    case 0xf6: ORA(R8(PC)); PC++; break;            /* ori # */

	    case 0xb8: CMP(B); break;                       /* cmp b */
	    case 0xb9: CMP(C); break;                       /* cmp c */
	    case 0xba: CMP(D); break;                       /* cmp d */
	    case 0xbb: CMP(E); break;                       /* cmp e */
	    case 0xbc: CMP(H); break;                       /* cmp h */
	    case 0xbd: CMP(L); break;                       /* cmp l */
	    case 0xbe: CMP(R8(HL)); break;                  /* cmp M */
	    case 0xbf: CMP(A); break;                       /* cmp a */

	    case 0xfe: CMP(R8(PC)); PC++; break;            /* cpi # */


		       /* ROTATE */
	    case 0x07: RES=(RES&0xff)|(A<<1&0x100); A<<=1; break;   /* rlc */
	    case 0x0f: RES=(RES&0xff)|(A<<8&0x100); A>>=1; break;   /* rrc */
	    case 0x17: { int c=A<<1&0x100; A=A<<1|(RES>>8&1); RES=(RES&0xff)|c; break; }    /* ral */
	    case 0x1f: { int c=A<<8&0x100; A=A>>1|(RES>>1&0x80); RES=(RES&0xff)|c; break; } /* rar */


		       /* SPECIALS */
	    case 0x2f: A=~A; break;                         /* cma */
	    case 0x37: RES|=0x100; break;                   /* stc */
	    case 0x3f: RES^=0x100; break;                   /* cmc */

	    case 0x27: {                                    /* daa */
			   int c=RES,a=cpu.a;
			   if (cpu.a||((A&0xf)>9)) { ADD(6); } if (cpu.a) a=cpu.a;
			   if ((RES&0x100)||((A&0xf0)>0x90)) { ADD(0x60); } if (RES&0x100) c=RES;
			   RES=(RES&0xff)|(c&0x100); cpu.a=a;
			   break;
		       }


		       /* INPUT/OUTPUT */
	    case 0xd3: out_port(R8(PC),A); PC++; break;     /* out p */
	    case 0xdb: A=in_port(R8(PC)); PC++; break;      /* in p */


		       /* CONTROL */
	    case 0xf3: cpu.i=0; break;                      /* di */
	    case 0xfb: cpu.i=1; if (cpu.ipend&0x80) interrupt(cpu.ipend&0x7f); break;       /* ei */
	    case 0x00: break;                               /* nop */
	    case 0x76: cpu.cycles=0; break;                 /* hlt (mov M,M) */

	    default: break;
	}



    }
}


void loadCoreMem(char *file)
{
    FILE * fp;
    fp = fopen(file,"rb");
    if(fp){
	//get size of file
	fseek(fp, 0, SEEK_END);
	long fileSize = ftell(fp);
	rewind(fp);
	fread(mem,1,fileSize,fp);	
	
    }
    else { //ERROR
	DEBUG_PRINT("Cannot read bin file \n");
    }

}

void emuRun(void){
cpu_run(1000);
}

void init(void) 
{
    glClearColor (0.0, 0.0, 0.0, 0.0);
    glClearDepth(1.0);
    glShadeModel (GL_SMOOTH);
    glEnable(GL_DEPTH_TEST);
    glEnable(GL_LIGHT0);
}
void drawAxis()
{
    glPushMatrix();
    // Je veux pas de lightning ici
    glDisable(GL_LIGHTING);
    //I draw 2 axis
    glColor3f(1.0,0.0,0.0);
    glBegin(GL_LINES);

    glColor3f(1.0, 0.0, 0.0);                  /* red */ 
    glVertex3f(-5.0,0.0,0.0);
    glVertex3f(5.0,0.0,0.0);

    glColor3f(0.0, 1.0, 0.0);                  /* Green */ 
    glVertex3f(0.0,-5.0,0.0);
    glVertex3f(0.0,5.0,0.0);

    glColor3f(0.0, 0.0, 1.0);                  /* Blue */ 
    glVertex3f(0.0,0.0,-5.0);
    glVertex3f(0.0,0.0,5.0);

    glEnd();
    glEnable(GL_LIGHTING);
    glPopMatrix();     

}
void display(void)
{

    glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);
    glLoadIdentity();

    drawAxis();

    glEnable(GL_LIGHTING);
    glPushMatrix();
    glRotatef(spin,1.0,1.0,1.0);
    glTranslatef(.0,.0,-4.0);
    glutSolidTeapot(.9);
    drawAxis();
    //Le cube tourne autour de l'axe de la tasse rotate->translate
    glPushMatrix();
    glRotatef(spin*2,1.0,1.0,1.0);
    glTranslatef(1.0,.0,-1);
    //et aussi autour de lui meme 
    glRotatef(spin*3,1.0,1.0,1.0);
    glTranslatef(2.0,.0,-0.5);
    glutSolidCube(.8);
    drawAxis();
    glPopMatrix();
    glPopMatrix();
    glDisable(GL_LIGHTING);

    glutSwapBuffers();


}
void reshape(int w, int h)
{
    glViewport (0, 0, (GLsizei) w, (GLsizei) h);
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glOrtho(-5.0, 5.0, -5.0, 5.0, -5.0, 5.0);
    //glFrustum (-5.0, 5.0, -5.0, 5.0, 2.0, 10.0);

    glMatrixMode(GL_MODELVIEW);
    //glLoadIdentity();
}
void mouse(int button, int state, int x, int y) 
{
    switch (button) {
	case GLUT_LEFT_BUTTON:
	    break;
	case GLUT_RIGHT_BUTTON:
	    break;
	default:
	    break;
    }
}

void keyboard(unsigned char key, int x, int y) {
    if (key == 27) 
	exit(0);
    else
    {
	buffer[0] = key;
	bcount=1;
    }
}


int main(int argc, char** argv){

    //put this parity thing somewhere else or at least understand it !
    int i;
    for (i=0;i<0x100;i++) lut_parity[i]=4&(4^(i<<2)^(i<<1)^i^(i>>1)^(i>>2)^(i>>3)^(i>>4)^(i>>5));

    loadCoreMem("4kbas.bin");
    PC = 0x0;
    glutInit(&argc, argv);
    //NOTE: pour avoir du zbuffer il suffit de mettre GLUT_DEPTH ici, dans les trucs iphone il faut mettre le define USE_DEPTH_BUFFER
    glutInitDisplayMode (GLUT_DOUBLE | GLUT_RGBA|GLUT_DEPTH);
    glutInitWindowSize (250, 250); 
    glutInitWindowPosition (100, 100);
    glutCreateWindow (argv[0]);
    init ();
    glutDisplayFunc(display); 
    glutReshapeFunc(reshape); 
    glutMouseFunc(mouse);
    glutKeyboardFunc(keyboard);
    glutIdleFunc(emuRun);
    glutMainLoop();
    return 0;
}
