
#include <stdio.h>
#include <stdlib.h>

//OpenGL includes

#include <OpenGL/gl.h>
#include <OpenGL/glu.h>
#include <GLUT/glut.h>


#include "i8080.h"

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

static unsigned char key=0;
unsigned char buffer[3];
int bcount = 0;

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
    switch (port) {

	case 0x1:
	case 0x11:
	    //LCS_DPRINT("%c<-- OUT port %X\n",v&0x7F,port);
	    printf("%c",v&0x7F);
	    fflush(stdout);
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

    loadCoreMem( icpu, "4kbas.bin" );
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
