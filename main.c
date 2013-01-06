/*
 * =====================================================================================
 *
 *       Filename: main 
 *
 *    Description: Altair 8800 emulator
 *
 *        Version:  1.0
 *        Created:  0
 *       Revision:  none
 *       Compiler:  gcc
 *
 *         Author:  Richard Ribier (Coder), 
 *        Company:  LittleCodeShop
 *
 * =====================================================================================
 */

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
#include "serial.h"
#include "88dsk.h"

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


extern unsigned char buffer[3];
extern int bcount ;

static unsigned char in_port(unsigned char port)
{
    unsigned char ret=port;

    switch (port) {
	case ASR33_CTRL_PORT:
	    break;
	case ADM3A_CTRL_PORT:    
	    ret = TxStat_BIT;
	    /*if(_kbhit()){ //ca c'etait pour windows avant de mettre glut
	    //check if it is a control caracter for DSK
	    char c = _getch();
	    buffer[0] = c;
	    bcount = 1;
	    }*/
	    if(bcount)
            ret = ret|RxStat_BIT;
	    break;
	case ASR33_DATA_PORT:
	    if(bcount>0){
		ret = buffer[0];
		bcount = 0;
	    }
	    break;
	case ADM3A_DATA_PORT:    
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
    case DSK_CONTROL:
        ret = dskStatus();
        break;
    case DSK_FUNCTION:
        ret = sectorPosition();
        break;
    case DSK_RDWR:
        ret=dskRead();
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
    case DSK_CONTROL:
        dskControl(v);
        break;
    case DSK_FUNCTION:
        dskFunction(v);
        break;
    case DSK_RDWR:
        dskWrite(v);
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

void loadCoreMem(I8080_CPU * cpu,char *file,int offset)
{
    FILE * fp;
    fp = fopen(file,"rb");
    if(fp){
	//get size of file
	fseek(fp, 0, SEEK_END);
	long fileSize = ftell(fp);
	rewind(fp);
	fread(cpu->mem+offset,1,fileSize,fp);	

    }
    else { //ERROR
	LCS_DPRINT("Cannot read bin file \n");
    }

}

void emuRun(void)
{
    cpu_run(icpu,1000);
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

void keyboard(unsigned char key, int x, int y) 
{
	if (key == 27) 
	    exit(0);
	else
	{
	    buffer[0] = key;
	    bcount=1;
	}
}

int main(int argc, char** argv)
{

    icpu = malloc(sizeof(I8080_CPU));
    unsigned char * amem = malloc(0XFFFF);
    initCPU(icpu);
    icpu->out_port_ptr = out_port;
    icpu->in_port_ptr = in_port;
    icpu->mem = amem;

    printf("LittleCodeShop.com ALTAIR 8800 Emulator\n\n Execution will start @%X\n",icpu->reg.pc);

    //loadCoreMem( icpu, "files/4kbas.bin",0x0 ); //load the basic at offset 0
    loadCoreMem( icpu, "files/dsk_bootrom/88dskrom.bin",0xFF00 ); // the altair DSK rom starts at 0xFF00
    dskLoad("files/Cpm22HD.dsk",0);
    dskLoad("files/games.dsk",1);
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
