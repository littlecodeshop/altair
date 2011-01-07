
#include <stdio.h>
#include <stdlib.h>

//OpenGL includes
#ifdef WINDOWS
#include <GL/gl.h>
#include <GL/glu.h>
#include <GL/glut.h>
#else
#include <OpenGL/gl.h>
#include <OpenGL/glu.h>
#include <GLUT/glut.h>
#endif


#include "i8080.h"
#include "font.h"

/* Bit manipulation and parity tables */
#define BIT(n)                  ( 1<<(n) )

#define BIT_SET(y, mask)        ( y |=  (mask) )
#define BIT_CLEAR(y, mask)      ( y &= ~(mask) )
#define BIT_FLIP(y, mask)       ( y ^=  (mask) )




/***************************************************
   Set bits        Clear bits      Flip bits
   y        0x0011          0x0011          0x0011
   mask     0x0101 |        0x0101 &~       0x0101 ^
   ---------       ----------      ---------
   result   0x0111          0x0010          0x0110
***************************************************/

////////////////////////////////////////////////////////////////////////////////
//    Examples:
//    mask= BIT(0) | BIT(8);      // Create mask with bit 0 and 8 set (0x0101)

//    BIT_SET(y, mask);           // Bits 0 and 8 of y have been set.
//    BIT_CLEAR(y, mask);         // Bits 0 and 8 of y have been cleared.
//    BIT_FLIP(y, mask);          // Bits 0 and 8 of y have been flipped.


I8080_CPU *icpu; 

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

extern unsigned char buffer[3];
extern int bcount ;

static unsigned char in_port(unsigned char port)
{
    unsigned char ret=port;

    //LCS_DPRINT("--> IN port %X\n",port);
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
    unsigned char ascii;
    switch (port) {

	case 0x1:
	case 0x11:
	    //LCS_DPRINT("%c<-- OUT port %X\n",v&0x7F,port);
	    ascii = v&0x7F;
	    console_output(ascii);
	  //  printf("%c",v&0x7F);
	  //  fflush(stdout);
	    break;
	default: 
	    //   LCS_DPRINT("%c<-- OUT port %X\n",v,port);
	    break;

    }
}

/* INTERRUPTS */
static void interrupt(int i)
{
    LCS_DPRINT("INTERUPTION\n");
    /*if (cpu->i) {
	cpu->i=cpu->ipend=0;
	cpu->cycles-=11;
	// RRR J'ai retiré ca ! RST(i);
    }
    else cpu->ipend=0x80|i;*/
}

void loadCoreMem(I8080_CPU * cpu,char *file)
{
    FILE * fp;
    fp = fopen(file,"rb");
    if(fp){
	//get size of file
	fseek(fp, 0, SEEK_END);
	long fileSize = ftell(fp);
	rewind(fp);
	fread(cpu->mem,1,fileSize,fp);	

    }
    else { //ERROR
	LCS_DPRINT("Cannot read bin file \n");
    }

}

void emuRun(void){
    cpu_run(icpu,1000);
}



void mouse(int button, int state, int x, int y) {
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

    icpu = malloc(sizeof(I8080_CPU));
    unsigned char * amem = malloc(0XFFFF);
    initCPU(icpu);
    icpu->out_port_ptr = out_port;
    icpu->in_port_ptr = in_port;
    icpu->mem = amem;

    loadCoreMem( icpu, "exbas40.bin" );
    glutInit(&argc, argv);
    //NOTE: pour avoir du zbuffer il suffit de mettre GLUT_DEPTH ici, dans les trucs iphone il faut mettre le define USE_DEPTH_BUFFER
    glutInitDisplayMode (GLUT_SINGLE | GLUT_RGB);
    glutInitWindowSize (250, 250); 
    glutInitWindowPosition (100, 100);
    glutCreateWindow (argv[0]);
    init ();
    glutDisplayFunc(console_display); 
    glutReshapeFunc(reshape); 
    glutMouseFunc(mouse);
    glutKeyboardFunc(console_keyboard);
    glutIdleFunc(emuRun);
    glutMainLoop();
    return 0;
}
