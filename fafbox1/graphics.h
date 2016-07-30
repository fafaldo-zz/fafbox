
#ifndef __GRAPHICS_H__
#define __GRAPHICS_H__


volatile uint8_t faf_lineCounterHigh;
volatile uint8_t faf_lineCounterLow;


void initVideo();
void clearVRAM();
void fillVRAM(uint8_t buffer, uint8_t color);
void drawPalette();
void drawSpriteFromFlash(uint16_t, uint8_t, uint8_t);
void drawTileFromFlash(uint16_t, uint8_t, uint8_t);
void endFrame();
void drawBackground();
void moveSprite1(uint8_t, uint8_t);
void moveSprite2(uint8_t, uint8_t);
void moveSprite3(uint8_t, uint8_t);
void waitForVBlank();
void setTile(uint16_t, uint8_t, uint8_t);

void setSprite(uint8_t, uint16_t, uint8_t, uint8_t);
void moveSprite(uint8_t, uint8_t, uint8_t);

void drawCustomSpriteFromFlash(uint16_t, uint8_t, uint8_t, uint8_t, uint8_t);

typedef struct {
	uint16_t data;
	uint8_t x, y;
} SPRITE;

SPRITE getSprite(uint8_t);

#define TRANSPARENT_COLOR 0x00


#endif