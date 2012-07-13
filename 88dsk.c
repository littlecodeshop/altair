/*
 * =====================================================================================
 *
 *       Filename: 88dsk 
 *
 *    Description: 
 *
 *        Version:  1.0
 *        Created:  Sat Jun 30 22:01:59 2012
 *       Revision:  none
 *       Compiler:  gcc
 *
 *         Author:  Richard Ribier (Coder), 
 *        Company:  LittleCodeShop
 *
 * =====================================================================================
 */

#include "88dsk.h"
#include <stdio.h>
#include <stdlib.h>

unsigned int    drive = 0;

//each drive will be represented by this struct
typedef struct _drive_info  {
    unsigned char   sector;
    unsigned char   track ;
    unsigned char * drive_data;
    int             data_position;
} drive_info;

drive_info drv[2];

void dskLoad(char *file,int drivenum)
{
    FILE * fp;
    fp = fopen(file,"rb");
    if(fp){
	//get size of file
	fseek(fp, 0, SEEK_END);
	long fileSize = ftell(fp);
	rewind(fp);
    (drv[drivenum].drive_data) = (unsigned char *)malloc(fileSize*sizeof(unsigned char));
	fread((drv[drivenum].drive_data),1,fileSize,fp);	
    //reset stuff
    drv[drivenum].sector=0;
    drv[drivenum].track=0;
    drv[drivenum].data_position=0;

    }
    else { //ERROR
        printf("Load disk error\n");
    }
}

void dskControl(unsigned char data)
{
    //are we talking anihilation here ?? -> if bit 7 is 1 
    if(0x80&data){
    printf("total anihilations !! what do I do here ?\n");
    return;
    }

    //get the disk number
    unsigned char dsk_num = data&0xf;
    printf("Disk selection %d\n",dsk_num);
    fflush(stdout);
    drive =dsk_num;
}

unsigned char dskStatus()
{

    unsigned char ret = 0x0;
    if((drv[drive].track)>0) ret |= 0x40;

    return ret;
}

void dskFunction(unsigned char fnct)
{
    if(fnct&STEP_IN){printf("step in\n");(drv[drive].track)=((drv[drive].track)+1)%77;}
    if(fnct&STEP_OUT){printf("step out\n");(drv[drive].track)=((drv[drive].track)-1);}
    if(fnct&HEAD_LOAD){
        //printf("head load\n");
    }
    if(fnct&HEAD_UNLOAD){
        //printf("head unload\n");
    }
    if(fnct&INT_ENABLED){printf("int enabled\n");}
    if(fnct&INT_DISABLED){printf("int disabled\n");}
    if(fnct&HEAD_CS){printf("head current switch\n");}
    if(fnct&WRITE_ENABLE){printf("************write enable***********\n");(drv[drive].data_position)=0;}
    fflush(stdout);
}

unsigned char sectorPosition()
{
    //a chaque fois qu'on nous demande sur quel secteur on est on avance :)
    drv[drive].sector=((drv[drive].sector)+1)%32;
    (drv[drive].data_position) = 0;
    return (((drv[drive].sector)<<1)&0x3E);
}

unsigned char dskRead()
{
    //read data in this sector and track
    int read_pos = ((drv[drive].track)*32*SECTOR_SZ)+((drv[drive].sector)*SECTOR_SZ)+(drv[drive].data_position)++;
    //printf("t%d s%d pos%d data %X\n",track,sector,(drv[drive].data_position)-1,(drv[drive].drive_data)[read_pos]);
    return (drv[drive].drive_data)[read_pos];
}

void dskWrite(unsigned char v){
    printf("Writing %d %c @t%ds%d",v,v,(drv[drive].track),drv[drive].sector);
    int write_pos = ((drv[drive].track)*32*SECTOR_SZ)+((drv[drive].sector)*SECTOR_SZ)+(drv[drive].data_position)++;
    (drv[drive].drive_data)[write_pos] = v;
}
