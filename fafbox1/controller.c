
#include <avr\io.h>
#include "controller.h"

unsigned char ButtonPushed(unsigned char button) 
{
	return !(CONTROLLER_PIN & (1<<button));
}