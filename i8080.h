#ifndef LCS_I8080_H
#define LCS_I8080_H
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
    unsigned char (* in_port_ptr)(unsigned char port); 		/*port input */

} I8080_CPU;

void initCPU( I8080_CPU * acpu);
static void cpu_run(int cycles);
#endif 
