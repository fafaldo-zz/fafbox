#ifndef __CONTROLLER_H__
#define __CONTROLLER_H__


#include "fafbox.h"

#define BTN_A_1 BUTTON_A_PIN
#define BTN_B_1 BUTTON_B_PIN
#define BTN_LEFT_1 BUTTON_C_PIN
#define BTN_RIGHT_1 BUTTON_D_PIN 
#define BTN_A_2 BUTTON_E_PIN
#define BTN_B_2 BUTTON_F_PIN
#define BTN_LEFT_2 BUTTON_G_PIN
#define BTN_RIGHT_2 BUTTON_H_PIN 

#ifndef __ASSEMBLER__

uint8_t isButtonPushed(uint8_t);

#endif


#endif