

#include <avr/io.h>
#include <avr/pgmspace.h>
#include "fafbox.h"
#include "graphics.h"
#include "sprites.h"
#include "tiles.h"


short tile_table[15][30];

SPRITE sprite_table[32] = {{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0}};
unsigned char used_sprites = 0;


void clearVRAM(void)
{
	fillVRAM(0x00);
}

void fillVRAM(unsigned char color)
{
	// przed zapisaniem do ramu zerujemy write i read enable, zerujemy buffer_enable (bo zapisujemy a nie rysujemy) i peripheral (bo korzystamy z lower adresu)
	// wlasciwie to ustawiamy na high bo tak zerujemy
	CONTROL_PORT |= (1<<READ_ENABLE_PIN | 1<<WRITE_ENABLE_PIN | 1<<BUFFER_ENABLE_PIN | 1<<PERIPHERAL_ENABLE_PIN);
	LOWER_ADDRESS_DDR = 0xFF;
	DATA_PORT = color;
	for(unsigned char i = 0; i < 120; i++)
	{
		HIGHER_ADDRESS_PORT = i<<1;
		for(unsigned char j = 0; j < 240; j++)
		{
			LOWER_ADDRESS_PORT = j;
			CONTROL_PORT &= ~(1<<WRITE_ENABLE_PIN);
			CONTROL_PORT |= (1<<WRITE_ENABLE_PIN);
		}
	}
	// potem lower z powrotem jako wejscie i otwieramy bufor peripheral
	LOWER_ADDRESS_DDR = 0x00;
	LOWER_ADDRESS_PORT = 0xFF;
	CONTROL_PORT &= ~(1<<PERIPHERAL_ENABLE_PIN);
}

void drawPalette()
{
	CONTROL_PORT |= (1<<READ_ENABLE_PIN | 1<<WRITE_ENABLE_PIN | 1<<BUFFER_ENABLE_PIN | 1<<PERIPHERAL_ENABLE_PIN);
	LOWER_ADDRESS_DDR = 0xFF;
	unsigned char kolor = 0;
	
	for(unsigned char i = 0; i < 120; i++)
	{
		HIGHER_ADDRESS_PORT = i<<1;
		for(unsigned char j = 0; j < 240; j++)
		{
			kolor = (i/7)*16 + (j/15);
			LOWER_ADDRESS_PORT = j;
			DATA_PORT = kolor;
			CONTROL_PORT &= ~(1<<WRITE_ENABLE_PIN);
			CONTROL_PORT |= (1<<WRITE_ENABLE_PIN);	
		}
	}
	LOWER_ADDRESS_DDR = 0x00;
	LOWER_ADDRESS_PORT = 0xFF;
	CONTROL_PORT &= ~(1<<PERIPHERAL_ENABLE_PIN);
}

void initVideo(void)
{
	TCCR1A = 0;
	TCCR1B = (1<<CS10) | (1<<WGM12);
	OCR1AH = high(636);
	OCR1AL = low(636);
	TIMSK1 = (1<<OCIE1A);
}

void drawSpriteFromFlash(short address, unsigned char x, unsigned char y)
{
	// TODO - dodaæ wyœwietlanie czêœciowe
	//if(x > 232 || y > 232) return;
	
	CONTROL_PORT |= (1<<READ_ENABLE_PIN | 1<<WRITE_ENABLE_PIN | 1<<BUFFER_ENABLE_PIN | 1<<PERIPHERAL_ENABLE_PIN);
	LOWER_ADDRESS_DDR = 0xFF;
	for(unsigned char i = 0; i < 8; i++)
	{
		HIGHER_ADDRESS_PORT = (y+i)<<1;
		for(unsigned char j = 0; j < 8; j++)
		{
			LOWER_ADDRESS_PORT = x+j;
			unsigned char kolor = pgm_read_byte(address++);
			//unsigned char kolor = 0xFF;
			if(kolor == TRANSPARENT_COLOR) continue;
			DATA_PORT = kolor;
			CONTROL_PORT &= ~(1<<WRITE_ENABLE_PIN);
			CONTROL_PORT |= (1<<WRITE_ENABLE_PIN);
		}
	}
	LOWER_ADDRESS_DDR = 0x00;
	LOWER_ADDRESS_PORT = 0xFF;
	CONTROL_PORT &= ~(1<<PERIPHERAL_ENABLE_PIN);
}

void drawCustomSpriteFromFlash(short address, unsigned char width, unsigned char height, unsigned char x, unsigned char y)
{
	// TODO - dodaæ wyœwietlanie czêœciowe
	//if(x > 232 || y > 232) return;
	
	CONTROL_PORT |= (1<<READ_ENABLE_PIN | 1<<WRITE_ENABLE_PIN | 1<<BUFFER_ENABLE_PIN | 1<<PERIPHERAL_ENABLE_PIN);
	LOWER_ADDRESS_DDR = 0xFF;
	for(unsigned char i = 0; i < height; i++)
	{
		HIGHER_ADDRESS_PORT = (y+i)<<1;
		for(unsigned char j = 0; j < width; j++)
		{
			LOWER_ADDRESS_PORT = x+j;
			unsigned char kolor = pgm_read_byte(address++);
			//if(kolor == TRANSPARENT_COLOR) continue;
			DATA_PORT = kolor;
			CONTROL_PORT &= ~(1<<WRITE_ENABLE_PIN);
			CONTROL_PORT |= (1<<WRITE_ENABLE_PIN);
		}
	}
	LOWER_ADDRESS_DDR = 0x00;
	LOWER_ADDRESS_PORT = 0xFF;
	CONTROL_PORT &= ~(1<<PERIPHERAL_ENABLE_PIN);
}

void drawTileFromFlash(short address, unsigned char x, unsigned char y)
{
	// TODO - dodaæ wyœwietlanie czêœciowe
	//if(x > 232 || y > 232) return;
	
	CONTROL_PORT |= (1<<READ_ENABLE_PIN | 1<<WRITE_ENABLE_PIN | 1<<BUFFER_ENABLE_PIN | 1<<PERIPHERAL_ENABLE_PIN);
	LOWER_ADDRESS_DDR = 0xFF;
	for(unsigned char i = 0; i < 8; i++)
	{
		HIGHER_ADDRESS_PORT = (y+i)<<1;
		for(unsigned char j = 0; j < 8; j++)
		{
			LOWER_ADDRESS_PORT = x+j;
			unsigned char kolor = pgm_read_byte(address++);
			DATA_PORT = kolor;
			CONTROL_PORT &= ~(1<<WRITE_ENABLE_PIN);
			CONTROL_PORT |= (1<<WRITE_ENABLE_PIN);
		}
	}
	LOWER_ADDRESS_DDR = 0x00;
	LOWER_ADDRESS_PORT = 0xFF;
	CONTROL_PORT &= ~(1<<PERIPHERAL_ENABLE_PIN);
}

void drawBackground(void)
{
	CONTROL_PORT |= (1<<READ_ENABLE_PIN | 1<<WRITE_ENABLE_PIN | 1<<BUFFER_ENABLE_PIN | 1<<PERIPHERAL_ENABLE_PIN);
	LOWER_ADDRESS_DDR = 0xFF;
	
	for(unsigned char i = 0; i < 15; i++)
	{
		for(unsigned char j = 0; j < 30; j++)
		{
			short tile_address = tile_table[i][j];
			for(unsigned char k = i*8; k < i*8+8; k++)
			{
				HIGHER_ADDRESS_PORT = k<<1;
				for(unsigned char l = j*8; l < j*8+8; l++)
				{
					LOWER_ADDRESS_PORT = l;
					DATA_PORT = pgm_read_byte(tile_address++);
					CONTROL_PORT &= ~(1<<WRITE_ENABLE_PIN);
					CONTROL_PORT |= (1<<WRITE_ENABLE_PIN);
				}
			}
		}
	}
	LOWER_ADDRESS_DDR = 0x00;
	LOWER_ADDRESS_PORT = 0xFF;
	CONTROL_PORT &= ~(1<<PERIPHERAL_ENABLE_PIN);
}

// swap video buffers
void endFrame(void)
{
	// jesli pisalismy do 1 to zerujemy na 0 i ustawiamy CONTROL_PORT (wykorzystywany przy rysowaniu) na 1 
	// tak naprade chyba nie musimy tego robic bo w przerwaniu i tak to robimy ale nie usuwam
	if(VIDEO_REGISTER & (1<<BANK_SELECT_BIT))
	{
		 VIDEO_REGISTER &= ~(1<<BANK_SELECT_BIT);
		 CONTROL_PORT |= (1<<BANK_SWITCH_PIN);
	}
	else
	{
		VIDEO_REGISTER |= (1<<BANK_SELECT_BIT);
		CONTROL_PORT &= ~(1<<BANK_SWITCH_PIN);
	}
}

void waitForVBlank(void)
{
	endFrame();
	while(!(VIDEO_REGISTER & (1<<VBLANK_BIT)));
	VIDEO_REGISTER &= ~(1<<VBLANK_BIT);
}

void setTile(short adress, unsigned char x, unsigned char y)
{
	tile_table[y][x] = adress;
	
	drawTileFromFlash(tile_table[y][x], x*8, y*8);
}

void setSprite(unsigned char id, short address, unsigned char x, unsigned char y)
{
	sprite_table[id].data = address;
	sprite_table[id].x = x;
	sprite_table[id].y = y;
	
	used_sprites++;
	
	//drawSpriteFromFlash(sprite_table[id].data, x, y);
}

SPRITE getSprite(unsigned char id) {
	return sprite_table[id];
}

void moveSprite(unsigned char id, unsigned char x, unsigned char y)
{
	if(sprite_table[id].x == x && sprite_table[id].y == y) return;
	
	if(sprite_table[id].x%8 != 0) {
		drawTileFromFlash(tile_table[sprite_table[id].y/8][sprite_table[id].x/8+1], (sprite_table[id].x/8)*8+8, (sprite_table[id].y/8)*8);
		drawTileFromFlash(tile_table[sprite_table[id].y/8][sprite_table[id].x/8], (sprite_table[id].x/8)*8, (sprite_table[id].y/8)*8);
	}
	if(sprite_table[id].x%8 != 0 && sprite_table[id].y%8 != 0) {
		drawTileFromFlash(tile_table[sprite_table[id].y/8+1][sprite_table[id].x/8+1], (sprite_table[id].x/8)*8+8, (sprite_table[id].y/8)*8+8);
	}
	if(sprite_table[id].y%8 != 0) {
		drawTileFromFlash(tile_table[sprite_table[id].y/8+1][sprite_table[id].x/8], (sprite_table[id].x/8)*8, (sprite_table[id].y/8)*8+8);
		drawTileFromFlash(tile_table[sprite_table[id].y/8][sprite_table[id].x/8], (sprite_table[id].x/8)*8, (sprite_table[id].y/8)*8);
	}
	
	sprite_table[id].x = x;
	sprite_table[id].y = y;
	
	for(unsigned char i = 0; i < used_sprites; i++)
	{
		if(sprite_table[i].x > sprite_table[id].x-8 && sprite_table[i].x < sprite_table[id].x+8 &&
		   sprite_table[i].y > sprite_table[id].y-8 && sprite_table[i].y < sprite_table[id].y+8)
		{
			drawSpriteFromFlash(sprite_table[i].data, sprite_table[i].x, sprite_table[i].y);
		}
	}
	
	// tu zmieniaj¹c kolejnoœæ, albo dodaj¹c to wywo³anie do pêtli chyba mo¿na zachowaæ g³êbokoœæ sprite'ów
	//SPRITE local = getSprite(id);
	//if(local.data == ball) x = 16;
	//drawSpriteFromFlash(sprite_table[id].data, x, y);
}