
#include <avr\io.h>
#include "fafbox.h"
#include "controller.h"


/*
	Method usd to check if any of the buttons has been pressed. It returns a bit mask
*/
uint8_t isButtonPushed(uint8_t button) {
	//we disable read/write operations and output video buffer
	CONTROL_PORT |= (1<<READ_ENABLE_PIN | 1<<WRITE_ENABLE_PIN | 1<<BUFFER_ENABLE_PIN);

	//we enable peripheral buffer and set control port as input (pulled-up with internal resistors)
	CONTROL_PORT &= ~(1<<PERIPHERAL_ENABLE_PIN);
	CONTROLLER_DDR = 0x00;
	CONTROLLER_PORT = 0xFF;

	//TODO optionally wait a couple of cycles for input

	return !(CONTROLLER_PIN & (1<<button));
}