


#include <avr/io.h>

#include <avr/interrupt.h>
#include "defines.h"
#include "graphics.h"
#include "sprites.h"
#include "game_sprites.h"
#include "tiles.h"


volatile unsigned char lifes = 3;
extern SPRITE sprite_table[8];

int main(void)
{	
	initPorts();
	
	for(unsigned char i = 0; i < 30; i++)
	{
		for(unsigned char j = 0; j < 15; j++)
		{
			setTile(tile_black, i, j);
		}
	}
	setSprite(0, ball, 16, 16);
	
	endFrame();
	
	
	
	initVideo();
	
	sei();
	
	unsigned char i = 1;
	unsigned char start_x = 16;
	unsigned char start_y = 16;
	unsigned char right = 1;
	unsigned char down = 1;
	
    while(1)
    {
		if(PINA & (1<<PA0)) {
		if(start_x <= 239-8 && right == 1) {
			start_x++;
		} else if(start_x >= 1 && right == 0) {
			start_x--;
		}
		if(start_y <= 119-8 && down == 1) {
			start_y++;
		} else if(start_y >= 1 && down == 0) {
			start_y--;
		}
		
		if(start_x == 0) {
			right = 1;
		} else if(start_x == 232) {
			right = 0;
		}		
		if(start_y == 0) {
			down = 1;
		} else if(start_y == 112) {
			down = 0;
		}
		
		
			moveSprite(0, start_x, start_y);
		}
		
		//endFrame();
		waitForVBlank();
    }
}