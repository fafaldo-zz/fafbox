
#ifndef DEFINES_H_
#define DEFINES_H_

#include <avr/io.h>

#define VIDEO_REGISTER GPIOR0
#define ACTIVE_PIXELS_BIT 0
#define BANK_SELECT_BIT 1
#define VBLANK_BIT 2
#define LOWER_ADDRESS_PORT PORTA
#define LOWER_ADDRESS_DDR DDRA
#define HIGHER_ADDRESS_PORT PORTD
#define HIGHER_ADDRESS_DDR DDRD
#define DATA_PORT PORTC
#define DATA_DDR DDRC
#define SYNC_PORT PORTB
#define CONTROL_PORT PORTB
#define CONTROL_DDR DDRB
#define HSYNC_PIN 0
#define VSYNC_PIN 1
#define BANK_SWITCH_PIN 5
#define WRITE_ENABLE_PIN 2
#define READ_ENABLE_PIN 3
#define BUFFER_ENABLE_PIN 4
#define PERIPHERAL_ENABLE_PIN 6
#define licznik_linii_reg_1 r28
#define licznik_linii_reg_2 r29
//#define licznik_linii_sram_1 0x0100
//#define licznik_linii_sram_2 0x0101
#define piksele_reg r20
//#define piksele_sram 0x0102

#ifndef __ASSEMBLER__

volatile unsigned char licznik_linii_sram_1;
volatile unsigned char licznik_linii_sram_2;
volatile unsigned char piksele_sram;

#endif

#define low(x) ((x) & 0xFF)
#define high(x) (((x)>>8) & 0xFF)

#define nop() asm volatile("nop")


#endif