


#include <avr/io.h>

#include <avr/interrupt.h>
#include "defines.h"
#include "graphics.h"
//#include "sprites.h"
//#include "game_sprites.h"
#include "snake_sprites.h"
#include "tiles.h"
#include "controller.h"


volatile unsigned char lifes = 3;
extern SPRITE sprite_table[32];

unsigned char plansza[30][30] = {0};
volatile unsigned char head_x = 15;
volatile unsigned char head_y = 10;
volatile unsigned char tail_x = 14;
volatile unsigned char tail_y = 10;

volatile unsigned char food_x = 1;
volatile unsigned char food_y = 15;

unsigned char i = 1;
unsigned char right = 1;
unsigned char down = 0;

unsigned char head = 2;
unsigned char tail = 1;

unsigned char game_over = 0;
unsigned char skip_tail_removal = 0;

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
	
	plansza[head_y][head_x] = head;
	plansza[tail_y][tail_x] = tail;
	plansza[food_y][food_x] = 0xFF;
	
	drawCustomSpriteFromFlash(part, 8, 4, head_x<<3, head_y<<2);
	drawCustomSpriteFromFlash(part, 8, 4, tail_x<<3, tail_y<<2);
	
	drawCustomSpriteFromFlash(food, 8, 4, food_x<<3, food_y<<2);
	
	//drawCustomSpriteFromFlash(part, 8, 4, 8, 8);
	
	initVideo();
	
	sei();
	
    while(1)
    {
		if(game_over) {
			waitForVBlank();
			continue;
		}
		
		i++;
		
		if(i%8 == 0) {
			plansza[tail_y][tail_x] = 0;
			if(right) {
				if(plansza[head_y][(head_x+1)%30] != 0 && plansza[head_y][(head_x+1)%30] != 0xFF) {
					game_over = 1;
					continue;
				} else {
					if(plansza[head_y][(head_x+1)%30] == 0xFF) {
						skip_tail_removal = 1;
						plansza[(head_y+10)%30][(head_x+11)%30] = 0xFF;
						drawCustomSpriteFromFlash(food, 8, 4, ((head_x+11)%30)<<3, ((head_y+10)%30)<<2); 
					}
					head = (head+1)%255;
					if(!head) head = 1;
					plansza[head_y][(head_x+1)%30] = head;
					head_x = (head_x+1)%30;
					drawCustomSpriteFromFlash(part, 8, 4, head_x*8, head_y*4);
				}
			} else if(down) {
				if(plansza[(head_y+1)%30][head_x] != 0 && plansza[(head_y+1)%30][head_x] != 0xFF) {
					game_over = 1;
					continue;
				} else {
					if(plansza[(head_y+1)%30][head_x] == 0xFF) {
						skip_tail_removal = 1;
						plansza[(head_y+11)%30][(head_x+10)%30] = 0xFF;
						drawCustomSpriteFromFlash(food, 8, 4, ((head_x+10)%30)<<3, ((head_y+11)%30)<<2);
					}
					head = (head+1)%255;
					if(!head) head = 1;
					plansza[(head_y+1)%30][head_x] = head;
					head_y = (head_y+1)%30;
					drawCustomSpriteFromFlash(part, 8, 4, head_x*8, head_y*4);
				}
			}
			
			if(!skip_tail_removal) {
				plansza[tail_y][tail_x] = 0;
				drawCustomSpriteFromFlash(back, 8, 4, tail_x*8, tail_y*4);
				tail = (tail+1)%255;
				if(!tail) tail = 1;
				
				if(plansza[(tail_y+1)%30][tail_x] == tail) {
					tail_y = (tail_y+1)%30;
					} else if(plansza[tail_y][(tail_x+1)%30] == tail) {
					tail_x = (tail_x+1)%30;
					} else if(plansza[(tail_y-1)%30][tail_x] == tail) {
					tail_y = (tail_y-1)%30;
					} else if(plansza[tail_y][(tail_x-1)%30] == tail) {
					tail_x = (tail_x-1)%30;
					} else if(plansza[(tail_y+1)%30][(tail_x+1)%30] == tail) {
					tail_y = (tail_y+1)%30;
					tail_x = (tail_x+1)%30;
					} else if(plansza[(tail_y-1)%30][(tail_x-1)%30] == tail) {
					tail_y = (tail_y-1)%30;
					tail_x = (tail_x-1)%30;
					} else if(plansza[(tail_y+1)%30][(tail_x-1)%30] == tail) {
					tail_y = (tail_y+1)%30;
					tail_x = (tail_x-1)%30;
					} else if(plansza[(tail_y-1)%30][(tail_x+1)%30] == tail) {
					tail_y = (tail_y-1)%30;
					tail_x = (tail_x+1)%30;
				}
			}
			skip_tail_removal = 0;
		}
		
		if(ButtonPushed(BUTTON_A)) {
			right = 1;
			down = 0;
		}
		if(ButtonPushed(BUTTON_B)) {
			right = 0;
			down = 1;
		}
		
		waitForVBlank();
    }
}

//popracowaæ nad przechodzniem taila w 0 itd