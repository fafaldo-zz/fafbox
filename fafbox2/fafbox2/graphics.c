
#include <avr/io.h>
#include <avr/pgmspace.h>
#include "fafbox.h"
#include "graphics.h"


/*
	File responsible for drawing graphics on screen. It manages background tiles and sprites that can be drawn to the screen. It also enables user to move sprites to point specified.

	Drawing system implements double-buffering method, for better artifact handling. 
	There is a general purpose register in use as a video register - GPRIO0, defined as GRAPHICS_STATUS_REGISTER. In that register we have different defined bits, used for comunication between
	interrupt handling routine and our main code (see: fafbox.h).
	We have two bits responsible for communication:

	GSR_BANK_IN_USE_BIT - is used to indicate which bank is currently used inside interrupt, this bit should be changed to tell interrupt to switch banks. It's value is stored and saved
		before (or after) each frame INSIDE interrupt routine, so that changing banks will not cause artifacts if done in the middle of the frame. Setting/clearing bit in an I/O register
		should be translated to a single instruction, so the operation should be atomic.
	GSR_ACTIVE_PIXELS_BIT - is used internally by interrupt routine
	GSR_VBLANK_BIT - is used to indicate that VBLANK just occured (can be tested by main program to see if frame is finished and should be cleared after each such occurance so that it can
		be set again)
*/


uint16_t faf_tileTable[15][30];

SPRITE faf_spriteTable[32] = {{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0}};
uint8_t faf_usedSprites = 0;


/*
	Method used to init video procedure. It sets up Timer1 with appropriate values and starts timer (although no video will be rendered until we set GLOBAL_INTERRUPT_ENABLE flag with sei()).
*/
void initVideo() {
	TCCR1A = 0;
	TCCR1B = (1<<CS10) | (1<<WGM12);
	OCR1AH = high(800);
	OCR1AL = low(800);
	TIMSK1 = (1<<OCIE1A);
}

/*
	Method clears screen (fills both frame buffers with black color). This method should be called before we start drawing to screen - so before we call sei(), because it does not care
	for current bank in use.
*/
void clearVRAM() {
	fillVRAM(0, 0x00);
	fillVRAM(1, 0x00);
}

/*
	Method used to fill specified frame buffer with specific color. This method should be called before we start drawing to screen - so before we call sei(), because it does not care
	for current bank in use.
*/
void fillVRAM(uint8_t buffer, uint8_t color) {
	//before we write to RAM, we clear WRITE_ENABLE_PIN and READ_ENABLE_PIN, we disable video buffer (because we are writing, not reading) by clearing BUFFER_ENABLE_PIN and controller
	//port by disabling buffer (PERIPHERAL_ENABLE_PIN). These chips pins are inverted, so driving our pin high actually disables component
	CONTROL_PORT |= (1<<WRITE_READ_ENABLE_PIN | 1<<PERIPHERAL_ENABLE_PIN | 1<<OUTPUT_ENABLE_PIN | 1<<NETWORK_ENABLE_PIN);

	DATA_PORT = color;

	if(buffer == 0) {
		CONTROL_PORT &= ~(1<<BANK_SWITCH_PIN);
	} else {
		CONTROL_PORT |= (1<<BANK_SWITCH_PIN);
	}

	for(uint8_t i = 0; i < 240; i++) {
		HIGHER_ADDRESS_PORT = i;
		
		for(uint8_t j = 0; j < 256; j++) {
			LOWER_ADDRESS_PORT = j;
			CONTROL_PORT &= ~(1<<OUTPUT_ENABLE_PIN);
			CONTROL_PORT |= (1<<OUTPUT_ENABLE_PIN);
		}
	}

	//TODO no need to tidy-up? Can we leave LOWER as outputs?
	//we set lower address back to being input with pull-up resistors
	//LOWER_ADDRESS_DDR = 0x00;
	//LOWER_ADDRESS_PORT = 0xFF;

	//turn perpherals back on, we do not care for 
	//TODO check if we enable only before checking?
	//CONTROL_PORT &= ~(1<<PERIPHERAL_ENABLE_PIN);
}

/*
	Method used to draw palette of all available colors to both frame buffers. This method should be called before we start drawing to screen - so before we call sei(), because it does not care
	for current bank in use.
*/
void drawPalette() {
	CONTROL_PORT |= (1<<WRITE_READ_ENABLE_PIN | 1<<PERIPHERAL_ENABLE_PIN | 1<<OUTPUT_ENABLE_PIN | 1<<NETWORK_ENABLE_PIN);

	uint8_t color = 0;
	
	for(uint8_t i = 0; i < 240; i++) {
		HIGHER_ADDRESS_PORT = i;
		
		for(uint8_t j = 0; j < 256; j++) {
			color = (i/15)*16 + (j/16);
			
			LOWER_ADDRESS_PORT = j;
			DATA_PORT = color;

			CONTROL_PORT &= ~(1<<BANK_SWITCH_PIN);

			CONTROL_PORT &= ~(1<<OUTPUT_ENABLE_PIN);
			CONTROL_PORT |= (1<<OUTPUT_ENABLE_PIN);

			CONTROL_PORT |= (1<<BANK_SWITCH_PIN);	

			CONTROL_PORT &= ~(1<<OUTPUT_ENABLE_PIN);
			CONTROL_PORT |= (1<<OUTPUT_ENABLE_PIN);
		}
	}
	//LOWER_ADDRESS_DDR = 0x00;
	//LOWER_ADDRESS_PORT = 0xFF;
	//CONTROL_PORT &= ~(1<<PERIPHERAL_ENABLE_PIN);
}


/*
void drawSpriteFromFlash(uint16_t address, uint8_t x, uint8_t y) {
	//TODO add partly display
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
*/