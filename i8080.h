#ifndef LCS_I8080_H
#define LCS_I8080_H

#define LCS_DEBUG
/* Macro for printing debug info */
#ifdef LCS_DEBUG
#define LCS_DPRINT(fmt, args...)    fprintf(stderr,fmt, ## args)
#else
#define LCS_DPRINT(fmt, args...)    /* Don't do anything in release builds */
#endif


typedef struct {

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

    unsigned char * mem;                             /* Core */

    void (* out_port_ptr)(unsigned char port,unsigned char v); /* port output */
    unsigned char (* in_port_ptr)(unsigned char port); 		/* port input */
    void (* interrupt_ptr)(int i); 		/* interruption */

} I8080_CPU;

void initCPU( I8080_CPU * acpu);
void cpu_run(I8080_CPU * cpu, int cycles);
#endif 
