/*
 * fafbox2.c
 *
 * Created: 02-08-2016 18:49:41
 * Author : fafik
 */ 
#define F_CPU 20000000
#include <avr/io.h>
#include <avr/interrupt.h>
#include <util/delay.h>
#include "fafbox.h"


int main(void) {
    CONTROL_DDR = 0xFF;
	CONTROL_PORT = (1<<HSYNC_PIN | 1<<VSYNC_PIN | 1<<SOUND_PIN | 1<<PERIPHERAL_ENABLE_PIN | 1<<NETWORK_ENABLE_PIN | 1<<WRITE_READ_ENABLE_PIN | 1<<BANK_SWITCH_PIN | 1<<OUTPUT_ENABLE_PIN);
	
	DATA_DDR = 0xFF;
	DATA_PORT = 0b00001110;
	
	LOWER_ADDRESS_DDR = 0xFF;
	LOWER_ADDRESS_PORT = 0b10101010;
	
	HIGHER_ADDRESS_DDR = 0xFF;
	HIGHER_ADDRESS_PORT = 0b01010101;
	
	CONTROL_PORT &= ~(1<<OUTPUT_ENABLE_PIN);
	_delay_ms(10000);
	CONTROL_PORT |= (1<<OUTPUT_ENABLE_PIN);
	
	
	DATA_DDR = 0x00;
	DATA_PORT = 0x00;
	
	CONTROL_PORT &= ~(1<<WRITE_READ_ENABLE_PIN);
	
	CONTROL_PORT &= ~(1<<OUTPUT_ENABLE_PIN);
	

    while (1) {
    }
}

