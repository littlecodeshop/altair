/*
 * =====================================================================================
 *
 *       Filename: 88dsk 
 *
 *    Description:  emulation disk drive
 *
 *        Version:  1.0
 *        Created:  2011-05-23
 *       Revision:  none
 *       Compiler:  gcc
 *
 *         Author:  Richard Ribier (Coder), 
 *        Company:  LittleCodeShop
 *
 * =====================================================================================
 */


#define DSK_CONTROL       0x08 //select latches and enables controller and disk drives
#define DSK_FUNCTION      0x09 //control disk functions
#define DSK_RDWR          0x0A //write data

//DSK functions
#define STEP_IN           0x01
#define STEP_OUT          0x02
#define HEAD_LOAD         0x04
#define HEAD_UNLOAD       0x08
#define INT_ENABLED       0x10
#define INT_DISABLED      0x20
#define HEAD_CS           0x40
#define WRITE_ENABLE      0x80


//ok lets emulate this mofo :)

void dskControl(unsigned char data);
unsigned char dskStatus();
void dskFunction(unsigned char fnct);
