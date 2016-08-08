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
#include "graphics.h"

volatile uint8_t oneTime = 0;

#define WRRD 2
#define OT 4
#define BE 5

int main(void) {
	/*
	//control
    PORTD = 0xFF;
	DDRD = 0xFF;
	
	//addresses
	DDRB = 0xFF;
	DDRB = 0x00;
	
	DDRC = 0xFF;
	PORTC = 0x00;
	
	//data
	DDRA = 0xFF;
	PORTA = 0b01100110;
	
	PORTD |= (1<<BE);
	PORTD |= (1<<WRRD);
	
	//_delay_ms(100);
	
	for(uint8_t i = 0; i < 255; i++) {
		PORTA = i;
		PORTC = i;
		
		PORTD &= ~(1<<OT);
		asm volatile("nop");
		asm volatile("nop");
		PORTD |= (1<<OT);
	}
	
	PORTD &= ~(1<<WRRD);
	
	PORTA = 0x00;
	DDRA = 0x00;
	PORTD &= ~(1<<BE);
	
	asm volatile("nop");
	asm volatile("nop");
	
	PORTD &= ~(1<<OT);

    while (1) {
		for(uint8_t i = 0; i < 255; i++) {
			PORTC = i;
			
			_delay_ms(1000);
		}
    }
	*/
	
	initPorts();
	initVideo();
	sei();
	
	fillVRAM(0, 0xFF);
	
	while(1) {
		
	}
}

