/*
 * fafbox2.c
 *
 * Created: 02-08-2016 18:49:41
 * Author : fafik
 */ 
#define F_CPU 25175000
#include <avr/io.h>
#include <avr/interrupt.h>
#include <util/delay.h>
#include "fafbox.h"
#include "graphics.h"

volatile uint8_t oneTime = 0;

#define WRRD 2
#define OT 4

int main(void) {
	/*
	//control
    PORTD = 0xFF;
	DDRD = 0xFF;
	
	//addresses
	DDRB = 0xFF;
	PORTB = 0x00;
	
	DDRC = 0xFF;
	PORTC = 0x00;
	*/
	
	/*
	//data
	DDRA = 0xFF;
	PORTA = 0b01100110;
	
	PORTD &= ~(1<<WRRD);
	
	_delay_ms(5000);
	
	PORTD |= (1<<WRRD);
	
	_delay_ms(5000);
	
	PORTD &= ~(1<<OT);
	_delay_ms(5000);
	PORTD |= (1<<OT);
	
	PORTA = 0x00;
	DDRA = 0x00;
	
	PORTD &= ~(1<<WRRD);
	
	PORTD &= ~(1<<OT);
	_delay_ms(5000);
	PORTD |= (1<<OT);
	*/
	
	/*_delay_ms(4000);
	
	
	DDRA = 0xFF;
	

	for(uint8_t i = 4; i <= 20; i++) {
		PORTA = i;
		PORTC = i;
		
		PORTD &= ~(1<<OT);
		asm volatile("nop");
		asm volatile("nop");
		PORTD |= (1<<OT);
		
		_delay_ms(1000);
	}

	
	PORTD &= ~(1<<WRRD);
	
	//_delay_ms(1000);
	
	DDRA = 0x00;
	
	//asm volatile("nop");
	//asm volatile("nop");
	
	//_delay_ms(1);
	
	
	

    while (1) {
		
		for(uint8_t i = 4; i < 255; i++) {
			PORTC = i;
			
			PORTD &= ~(1<<OT);
			
			_delay_ms(2000);
		}
		
    }*/
	
	_delay_ms(2000);
	
	initPorts();
	
	_delay_ms(2000);
	
	initVideo();
	
	_delay_ms(2000);
	
	fillVRAM(1, 0);
	//drawPalette();
	
	sei();
	
	while(1) {
		
	}
	
	
	/*
	PORTA = 0xFF;
	DDRA = 0xFF;
	
	PORTB = 0xFF;
	DDRB = 0xFF;
	
	PORTC = 0xFF;
	DDRC = 0xFF;
	
	PORTD = 0xFF;
	DDRD = 0xFF;
	
	while(1) {
		_delay_ms(500);
		PORTC = 0x00;
		_delay_ms(500);
		PORTC = 0xFF;
	}
	*/
}

