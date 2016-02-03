
#include <avr\io.h>
#include "fafbox.h"


void initPorts(void)
{
	LOWER_ADDRESS_DDR = 0x00;
	LOWER_ADDRESS_PORT = 0xFF;
	HIGHER_ADDRESS_DDR = 0xFF;
	HIGHER_ADDRESS_PORT = 0x00;
	DATA_DDR = 0xFF;
	DATA_PORT = 0x00;

	CONTROL_DDR = 0xFF;
	CONTROL_PORT = (1<<HSYNC_PIN | 1<<VSYNC_PIN | 1<<BUFFER_ENABLE_PIN | 1<<WRITE_ENABLE_PIN | 1<<READ_ENABLE_PIN);
	
	VIDEO_REGISTER |= (1<<BANK_SELECT_BIT);
}

/* 
najpierw
- lower - wejście podciągnięte do 1
- higher - wyjście 0x00
- data - wyjście 0x00
- control - wyjście
	- HSYNC 1
	- VSYNC 1 
	- WRITE_ENABLE 1 
	- READ_ENABLE 1 
	- BUFFER_ENABLE 1 
	- BANK_SWITCH 0 
	- PERIPHERAL_ENABLE 0
- ustawiamy dane do rysowania z banku 1 

W normalnym trybie pracy PORT LOWER zawsze pracuje jako wejście podciągnięte do 1. Jest przełączany na wyjście tylko w przypadku zapisu i odczytu z RAM.
CONTROL PORT zawsze pracuje jako wyjście.
VIDEO_REGISTER ma ACTIVE_PIXELS_BIT włączany kiedy rysujemy piksele (żeby można było później skipnąć rysowanie jeśli nie trzeba) i VBLANK_BIT włączany kiedy mamy VBLANK.
*/