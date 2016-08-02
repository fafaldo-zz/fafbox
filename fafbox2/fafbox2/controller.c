
#include <avr\io.h>
#include "fafbox.h"
#include "controller.h"


/*
	Method used to check if any of the buttons has been pressed. It returns a bit mask
*/
uint8_t isButtonPushed(uint8_t button) {
	return !(CONTROLLER_STATUS_REGISTER & (1<<button));
}