/*
 * fafbox2.c
 *
 * Created: 02-08-2016 18:49:41
 * Author : fafik
 */ 

#include <avr/io.h>
#include <avr/interrupt.h>
#include "fafbox.h"
#include "graphics.h"


int main(void) {
    initPorts();
	initVideo();
	sei();

	clearVRAM();

    while (1) {
    }
}

