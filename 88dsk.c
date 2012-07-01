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
unsigned char   sector = 0;
unsigned char   track = 0;
unsigned char * drive_data;
int             data_position = 0;


void dskLoad(char *file)
{
    FILE * fp;
    fp = fopen(file,"rb");
    if(fp){
	//get size of file
	fseek(fp, 0, SEEK_END);
	long fileSize = ftell(fp);
	rewind(fp);
    drive_data = (unsigned char *)malloc(fileSize*sizeof(unsigned char));
	fread(drive_data,1,fileSize,fp);	

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
    if(track>0) ret |= 0x40;

    return ret;
}

void dskFunction(unsigned char fnct)
{
    if(fnct&STEP_IN){printf("step in\n");track=(track+1)%77;}
    if(fnct&STEP_OUT){printf("step out\n");track=(track-1);}
    if(fnct&HEAD_LOAD){
        //printf("head load\n");
    }
    if(fnct&HEAD_UNLOAD){
        //printf("head unload\n");
    }
    if(fnct&INT_ENABLED){printf("int enabled\n");}
    if(fnct&INT_DISABLED){printf("int disabled\n");}
    if(fnct&HEAD_CS){printf("head current switch\n");}
    if(fnct&WRITE_ENABLE){printf("************write enable***********\n");data_position=0;}
    fflush(stdout);
}

unsigned char sectorPosition()
{
    //a chaque fois qu'on nous demande sur quel secteur on est on avance :)
    sector=(sector+1)%32;
    data_position = 0;
    return ((sector<<1)&0x3E);
}

unsigned char dskRead()
{
    //read data in this sector and track
    int read_pos = (track*32*SECTOR_SZ)+(sector*SECTOR_SZ)+data_position++;
    //printf("t%d s%d pos%d data %X\n",track,sector,data_position-1,drive_data[read_pos]);
    return drive_data[read_pos];
}

void dskWrite(unsigned char v){
    printf("Writing %d %c @t%ds%d",v,v,track,sector);
    int write_pos = (track*32*SECTOR_SZ)+(sector*SECTOR_SZ)+data_position++;
    drive_data[write_pos] = v;
}
