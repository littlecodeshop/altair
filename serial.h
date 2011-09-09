/*
 * =====================================================================================
 *
 *       Filename: serial.h 
 *
 *    Description: 
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

//  SIO card port 0h/1h -> ASR TTY
#define ASR33_CTRL_PORT     0x0 // status  
#define ASR33_DATA_PORT     0x1  

//  2SIO card port 10h/11h -> glass TTY 
#define ADM3A_CTRL_PORT     0x10 
#define ADM3A_DATA_PORT     0x11 

//  Possible values of status register

