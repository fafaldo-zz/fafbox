
#ifndef __FAFBOX_H__
#define __FAFBOX_H__


/*
	General purpose register used for communication between interrupt handling routine and main code. It is also used internally inside that routine itself.
*/
#define GENERAL_STATUS_REGISTER GPIOR0
#define GSR_ACTIVE_PIXELS_BIT 0 			//used internally by interrupt, to decide whether this is an active frame and we should write some pixels to the screen
#define GSR_CURRENT_BANK_BIT 1 				//used to indicate bank in use by interrupt; is saved before/after each frame (see: graphics.c)
#define GSR_NEW_BANK_BIT 2					//used to let know our interrupt routine that bank needs to be changed
#define GSR_VBLANK_BIT 3 					//used to indicate that frame has just finished; if used by main code, should be cleared after usage
#define GSR_IS_PLAYING_BIT 4				//used to indicate if sound is playing

/*
	General purpose register used to store inputs from peripherals
*/
#define CONTROLLER_STATUS_REGISTER GPIOR1

/*
	Main ports used by microcontroller
*/
#define LOWER_ADDRESS_PORT PORTC
#define LOWER_ADDRESS_DDR DDRC
#define HIGHER_ADDRESS_PORT PORTB
#define HIGHER_ADDRESS_DDR DDRB
#define DATA_PORT PORTA
#define DATA_DDR DDRA
#define CONTROL_PORT PORTD
#define CONTROL_DDR DDRD
#define HSYNC_PIN 0
#define VSYNC_PIN 1
#define WRITE_READ_ENABLE_PIN 2 //1 - write enable (read driven high), 0 - read enable (write driven high)
#define BANK_SWITCH_PIN 3
#define OUTPUT_ENABLE_PIN 4
#define PERIPHERAL_ENABLE_PIN 5
#define SOUND_PIN 6
#define NETWORK_ENABLE_PIN 7

/*
	Ports used for SD card communication
*/
#define SD_PORT PORTB
#define SD_DDR DDRB
#define SD_CS_PIN 4
#define SD_MOSI_PIN 5
#define SD_MISO_PIN 6
#define SD_SCK_PIN 7

/*
	Ports used for peripheral controllers
*/
#define CONTROLLER_PORT PORTC
#define CONTROLLER_DDR DDRC
#define CONTROLLER_PIN PINC
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

#ifndef __ASSEMBLER__

void initPorts();

#endif


#endif