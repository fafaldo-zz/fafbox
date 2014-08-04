
#ifndef GRAPHICS_H_
#define GRAPHICS_H_

#include <avr/io.h>

void initPorts(void);
void initVideo(void);
void clearVRAM(void);
void fillVRAM(unsigned char);
void drawPalette(void);
void drawSpriteFromFlash(short,unsigned char,unsigned char);
void drawTileFromFlash(short,unsigned char,unsigned char);
void endFrame(void);
void drawBackground(void);
void moveSprite1(unsigned char, unsigned char);
void moveSprite2(unsigned char, unsigned char);
void moveSprite3(unsigned char, unsigned char);
void waitForVBlank(void);
void setTile(short,unsigned char, unsigned char);

void setSprite(unsigned char id, short address, unsigned char x, unsigned char y);
void moveSprite(unsigned char, unsigned char, unsigned char);

void drawCustomSpriteFromFlash(short address,unsigned char width, unsigned char height, unsigned char x, unsigned char y);

typedef struct
{
	short data;
	unsigned char x, y;
}SPRITE;

SPRITE getSprite(unsigned char);

#define TRANSPARENT_COLOR 0x00

#endif