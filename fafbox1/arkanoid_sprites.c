#include <avr/pgmspace.h>
#include "arkanoid_sprites.h"

const unsigned char ball[8][8] PROGMEM ={
{0b11111111,0b11111111,0b11111111,0b11111111,0b11111111,0b11111111,0b11111111,0b11111111},{0b11111111,0b11111111,0b0,0b0,0b0,0b0,0b11111111,0b11111111},{0b11111111,0b0,0b11011011,0b11011011,0b11011011,0b11011011,0b0,0b11111111},{0b0,0b11011011,0b1101101,0b11011011,0b11011011,0b11011011,0b11011011,0b0},{0b0,0b11011011,0b11011011,0b11011011,0b11011011,0b11011011,0b11011011,0b0},{0b11111111,0b0,0b11011011,0b11011011,0b11011011,0b11011011,0b0,0b11111111},{0b11111111,0b11111111,0b0,0b0,0b0,0b0,0b11111111,0b11111111},{0b11111111,0b11111111,0b11111111,0b11111111,0b11111111,0b11111111,0b11111111,0b11111111}};

//const unsigned char brick[4][16] PROGMEM ={
//{0b0,0b0,0b0,0b0,0b0,0b0,0b0,0b0,0b0,0b0,0b0,0b0,0b0,0b0,0b0,0b0,},{0b0,0b10100101,0b10100101,0b11111100,0b11111100,0b11111100,0b11111100,0b111111000b11111100,0b11111100,0b11111100,0b11111100,0b11111100,0b11111100,0b11111100,0b0,},{0b0,0b10100101,0b11111100,0b11111100,0b11111100,0b11111100,0b11111100,0b111111000b11111100,0b11111100,0b11111100,0b11111100,0b11111100,0b11111100,0b11111100,0b0,},{0b0,0b0,0b0,0b0,0b0,0b0,0b0,0b00b0,0b0,0b0,0b0,0b0,0b0,0b0,0b0,},};
//
//const unsigned char heart[16][16] PROGMEM ={
//{0b0,0b0,0b0,0b0,0b0,0b0,0b0,0b0,0b0,0b0,0b0,0b0,0b0,0b0,0b0,0b0,},{0b0,0b0,0b11100,0b11100,0b11100,0b11100,0b0,0b00b0,0b0,0b11100,0b11100,0b11100,0b11100,0b0,0b0,},{0b0,0b11100,0b11100,0b11100,0b11100,0b11100,0b11100,0b00b0,0b11100,0b11100,0b11100,0b11100,0b11100,0b11100,0b0,},{0b0,0b11100,0b11100,0b11100,0b11100,0b11100,0b11100,0b111000b11100,0b11100,0b11100,0b11100,0b11100,0b11100,0b11100,0b0,},{0b0,0b11100,0b11100,0b11100,0b11100,0b11100,0b11100,0b111000b11100,0b11100,0b11100,0b11100,0b11100,0b11100,0b11100,0b0,},{0b0,0b11100,0b11100,0b11100,0b11100,0b11100,0b11100,0b111000b11100,0b11100,0b11100,0b11100,0b11100,0b11100,0b11100,0b0,},{0b0,0b11100,0b11100,0b11100,0b11100,0b11100,0b11100,0b111000b11100,0b11100,0b11100,0b11100,0b11100,0b11100,0b11100,0b0,},{0b0,0b11100,0b11100,0b11100,0b11100,0b11100,0b11100,0b111000b11100,0b11100,0b11100,0b11100,0b11100,0b11100,0b11100,0b0,}{0b0,0b11100,0b11100,0b11100,0b11100,0b11100,0b11100,0b111000b11100,0b11100,0b11100,0b11100,0b11100,0b11100,0b11100,0b0,},{0b0,0b0,0b11100,0b11100,0b11100,0b11100,0b11100,0b111000b11100,0b11100,0b11100,0b11100,0b11100,0b11100,0b0,0b0,},{0b0,0b0,0b0,0b11100,0b11100,0b11100,0b11100,0b111000b11100,0b11100,0b11100,0b11100,0b11100,0b0,0b0,0b0,},{0b0,0b0,0b0,0b11100,0b11100,0b11100,0b11100,0b111000b11100,0b11100,0b11100,0b11100,0b11100,0b0,0b0,0b0,},{0b0,0b0,0b0,0b0,0b11100,0b11100,0b11100,0b111000b11100,0b11100,0b11100,0b11100,0b0,0b0,0b0,0b0,},{0b0,0b0,0b0,0b0,0b0,0b11100,0b11100,0b111000b11100,0b11100,0b11100,0b0,0b0,0b0,0b0,0b0,},{0b0,0b0,0b0,0b0,0b0,0b0,0b11100,0b111000b11100,0b11100,0b0,0b0,0b0,0b0,0b0,0b0,},{0b0,0b0,0b0,0b0,0b0,0b0,0b0,0b00b0,0b0,0b0,0b0,0b0,0b0,0b0,0b0,},};
//
//const unsigned char plank[4][16] PROGMEM ={
//{0b11111111,0b0,0b0,0b0,0b0,0b0,0b0,0b0,0b0,0b0,0b0,0b0,0b0,0b0,0b0,0b11111111,},{0b0,0b1000111,0b1000111,0b1000111,0b1000111,0b1000111,0b1000111,0b10001110b1000111,0b1000111,0b1000111,0b1000111,0b1000111,0b1000111,0b1000111,0b0,},{0b0,0b1000111,0b1000111,0b1000111,0b1000111,0b1000111,0b1000111,0b10001110b1000111,0b1000111,0b1000111,0b1000111,0b1000111,0b1000111,0b1000111,0b0,},{0b11111111,0b0,0b0,0b0,0b0,0b0,0b0,0b00b0,0b0,0b0,0b0,0b0,0b0,0b0,0b11111111,},};
//
//