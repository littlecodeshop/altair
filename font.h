
#define HEXIFY(X) 0x##X##LU

#define B8IFY(Y) (((Y&0x0000000FLU)?1:0)  + \
	((Y&0x000000F0LU)?2:0)  + \
	((Y&0x00000F00LU)?4:0)  + \
	((Y&0x0000F000LU)?8:0)  + \
	((Y&0x000F0000LU)?16:0) + \
	((Y&0x00F00000LU)?32:0) + \
	((Y&0x0F000000LU)?64:0) + \
	((Y&0xF0000000LU)?128:0))

#define B8(Z) ((unsigned char)B8IFY(HEXIFY(Z)))
void initConsole();
void makeRasterFont(void);
void console_keyboard(unsigned char key, int x, int y);
void console_display(void);
void init(void);
void reshape(int w, int h);
void console_output(unsigned char ascii);
