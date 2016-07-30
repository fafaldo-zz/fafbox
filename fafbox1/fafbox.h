
#ifndef __FAFBOX_H__
#define __FAFBOX_H__


/*
	General purpose register used for communication between interrupt handling routine and main code. It is also used internally inside that routine itself.
*/
#define GRAPHICS_STATUS_REGISTER GPIOR0
#define GSR_ACTIVE_PIXELS_BIT 0 			//used internally by interrupt, to decide whether this is an active frame and we should write some pixels to the screen
#define GSR_CURRENT_BANK_BIT 1 				//used to indicate bank in use by interrupt; is saved before/after each frame (see: graphics.c)
#define GSR_NEW_BANK_BIT 2				//used to let know our interrupt routine that bank needs to be changed
#define GSR_VBLANK_BIT 3 					//used to indicate that frame has just finished; if used by main code, should be cleared after usage

/*
	Main ports used by microcontroller
*/
#define LOWER_ADDRESS_PORT PORTA
#define LOWER_ADDRESS_DDR DDRA
#define HIGHER_ADDRESS_PORT PORTD
#define HIGHER_ADDRESS_DDR DDRD
#define DATA_PORT PORTC
#define DATA_DDR DDRC
#define CONTROL_PORT PORTB
#define CONTROL_DDR DDRB
#define HSYNC_PIN 0
#define VSYNC_PIN 1
#define WRITE_ENABLE_PIN 2
#define READ_ENABLE_PIN 3
#define VIDEO_ENABLE_PIN 4
#define BANK_SWITCH_PIN 5
#define PERIPHERAL_ENABLE_PIN 6

/*
	Ports used for SD card communication
*/
#define SD_PORT PORTB
#define SD_DDR DDRB
#define CS_PIN 4
#define MOSI_PIN 5
#define MISO_PIN 6
#define SCK_PIN 7

/*
	Ports used for peripheral controllers
*/
#define CONTROLLER_PORT PORTA
#define CONTROLLER_DDR DDRA
#define CONTROLLER_PIN PINA
#define BUTTON_A_PIN 0
#define BUTTON_B_PIN 1
#define BUTTON_C_PIN 2
#define BUTTON_D_PIN 3
#define BUTTON_E_PIN 4
#define BUTTON_F_PIN 5
#define BUTTON_G_PIN 6
#define BUTTON_H_PIN 7

/*
	Main macros
*/
#define CS_ENABLE() (PORTB &= ~(1<<4))
#define CS_DISABLE() (PORTB |= (1<<4)) 

#define low(x) ((x) & 0xFF)
#define high(x) (((x)>>8) & 0xFF)
#define nop() asm volatile("nop")


void initPorts();


#endif