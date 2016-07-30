

#define __SFR_OFFSET 0

#include <avr/io.h>
#include "fafbox.h"
#include "graphics.h"

#define LINE_COUNTER_REGISTER_HIGH r28
#define LINE_COUNTER_REGISTER_LOW r29

.extern faf_lineCounterHigh
.extern faf_lineCounterLow

/*
	VGA timing:

	clock - 25.175 MHz

	Horizontal front porch - 16
	Horizontal sync porch - 96
	Horizontal back porch - 48
	Horizontal video - 640
	
	Vertical front porch - 10
	Vertical sync porch - 2
	Vertical back porch - 33
	Vertical video - 480
*/

.global TIMER1_COMPA_vect
TIMER1_COMPA_vect:

	//horizontal sync porch - 96 cycles

	push r16 ;2

	in r16, SREG ;1
	push r16 ;2

	//adjust interrupt response time

	lds r16, TCNT1L ;2
	cpi r16, 16 ;1
	breq sixteen ;1/2
	cpi r16, 15 ;1
	breq fifteen ;1/2
	cpi r16, 14 ;1
	breq fourteen ;1/2
	cpi r16, 13 ;1
	breq thirteen ;1/2
	cpi r16, 12 ;1
	breq twelve ;1/2

sixteen:
	nop ;1
fifteen:
	nop ;1
fourteen:
	nop ;1
thirteen:
	nop ;1
twelve:


	//24 cycles from beginning of interrupt (including 16 cycles of HFP and 8 cycles of active pixels)

	//beginning of Horizontal Sync Porch

	cbi CONTROL_PORT, HSYNC_PIN ;2

	push r17 ;2
	push LINE_COUNTER_REGISTER_HIGH ;2
	push LINE_COUNTER_REGISTER_LOW ;2
	lds LINE_COUNTER_REGISTER_HIGH, faf_lineCounterHigh ;2
	lds LINE_COUNTER_REGISTER_LOW, faf_lineCounterLow ;2

	//12 cycles from beginning of HSP

	sbiw LINE_COUNTER_REGISTER_LOW, 2 ;2
	brcs turn_vsync_on ;1/2
	nop ;1
	sbi CONTROL_PORT, VSYNC_PIN ;2
	rjmp skip_turn_vsync_on ;2

turn_vsync_on:
	cbi CONTROL_PORT, VSYNC_PIN ;2
	nop ;1
	nop ;1

skip_turn_vsync_on:
	adiw LINE_COUNTER_REGISTER_LOW, 2 ;2

	//22 cycles from beginning of HSP

	ldi r17, high(35) ;1
	cpi LINE_COUNTER_REGISTER_LOW, low(35) ;1
	cpc r17, LINE_COUNTER_REGISTER_HIGH ;1
	breq turn_pixels_on ;1/2
	nop ;1
	rjmp skip_turn_pixels_on ;2

turn_pixels_on:
	sbi GRAPHICS_STATUS_REGISTER, ACTIVE_PIXELS_BIT ;2

skip_turn_pixels_on:
	
	//29 cycles from beginning of HSP

	ldi r17, high(415) ;1
	cpi LINE_COUNTER_REGISTER_LOW, low(415) ;1
	cpc r17, LINE_COUNTER_REGISTER_HIGH ;1
	breq turn_pixels_off ;1/2
	nop ;1
	nop ;1
	nop ;1
	rjmp skip_turn_pixels_off ;2

turn_pixels_off:
	cbi GRAPHICS_STATUS_REGISTER, ACTIVE_PIXELS_BIT ;2
	sbi GRAPHICS_STATUS_REGISTER, VBLANK_BIT ;2

skip_turn_pixels_off:

	//38 cycles from beginning of HSP

	ldi r17, high(424) ;1
	cpi LINE_COUNTER_REGISTER_LOW, low(424) ;1
	cpc r17, LINE_COUNTER_REGISTER_HIGH ;1
	breq clear_line_counter ;1/2
	nop ;1
	adiw LINE_COUNTER_REGISTER_LOW, 1 ;2
	rjmp skip_clear_line_counter ;2

clear_line_counter:
	bst GRAPHICS_STATUS_REGISTER, GSR_NEW_BANK_BIT ;1
	bld GRAPHICS_STATUS_REGISTER, GSR_CURRENT_BANK_BIT ;1
	clr LINE_COUNTER_REGISTER_LOW ;1
	clr LINE_COUNTER_REGISTER_HIGH	;1

skip_clear_line_counter:

	//47 cycles from beginning of HSP
	
	nop ;1
	nop ;1
	nop ;1

	nop ;1
	nop ;1
	nop ;1
	nop ;1
	nop ;1
	nop ;1
	nop ;1
	nop ;1
	nop ;1
	nop ;1

	nop ;1
	nop ;1
	nop ;1
	nop ;1
	nop ;1
	nop ;1
	nop ;1
	nop ;1
	nop ;1
	nop ;1

	nop ;1
	nop ;1
	nop ;1
	nop ;1
	nop ;1
	nop ;1
	nop ;1
	nop ;1
	nop ;1
	nop ;1

	nop ;1
	nop ;1
	nop ;1
	nop ;1
	nop ;1
	nop ;1
	nop ;1
	nop ;1
	nop ;1
	nop ;1

	nop ;1
	nop ;1
	nop ;1
	nop ;1
	nop ;1
	nop ;1
	
	//96 cycles from beginning of HSP
	//horizontal back porch - 48 cycles
	
	sbi CONTROL_PORT, HSYNC_PIN ;2

	sbis GRAPHICS_STATUS_REGISTER, ACTIVE_PIXELS_BIT ;1/2
	rjmp no_video ;2

video:

	//4 cycles from beginning of HBP

	//DATA_DDR is always output - no need to store
	//DATA_PORT might be random so save it (i.e. during writing)
	in r16, DATA_PORT ;1
	push r16 ;2

	//LOWER_ADDRESS_DDR might be random so save it (i.e. input during peripheral, output during writing)
	in r16, LOWER_ADDRESS_DDR ;1
	push r16 ;2
	//LOWER_ADDRESS_PORT might be random so save it (i.e. during writing)
	in r16, LOWER_ADDRESS_PORT ;1
	push r16 ;2
	
	//HIGHER_ADDRESS_DDR is always output - no need to store
	//HIGHER_ADDRESS_PORT might be random so save it (i.e. during writing)
	in r16, HIGHER_ADDRESS_PORT ;1
	push r16 ;2

	//CONTROL_DDR is always output - no need to store
	//CONTROL_PORT might be random so save it (i.e. READ_ENABLE_PIN/WRITE_ENABLE_PIN pin usage during writing)
	in r16, CONTROL_PORT ;1
	push r16 ;2

	//19 cycles from beginning of HBP


	//cancel all irrelevant outputs in CONTROL_PORT (currently stored in r16)
	//for now we set bank to 1, as we will clear it in a second if needed
	ori r16, (1<<WRITE_ENABLE_PIN | 1<<READ_ENABLE_PIN | 1<<BUFFER_ENABLE_PIN | 1<<PERIPHERAL_ENABLE_PIN | 1<<BANK_SWITCH_PIN) ;1

	//we copy new_bank_bit to current_bank_bit at the beginning of each frame, then we test this value to determine
	//if we should use bank 0 or 1 
	sbic GRAPHICS_STATUS_REGISTER, GSR_CURRENT_BANK_BIT ;1/2 
	andi r16, ~(1<<BANK_SWITCH_PIN) ;1

	out CONTROL_PORT, r16 ;1

	//23 cycles from beginning of HBP


	//we set DATA_PORT as floating input, just to make sure we do not input any data during reading
	//TODO not needed?
	ldi r16, 0x00 ;1
	out DATA_PORT, r16 ;1
	out DATA_DDR, r16 ;1

	//we set LOWER_ADDRESS_PORT as output (it could be input during peripheral reading) 
	ldi r16, 0xFF ;1
	out LOWER_ADDRESS_DDR, r16 ;1

	//28 cycles from beginning of HBP


	//TODO make sure we increment line counter in good place
	//we divide line counter by 2, to doulbe each line and display 240 lines
	mov r16, licznik_linii_reg_1 ;1
	lsr r16 ;1
	cpi licznik_linii_reg_2, 0x01 ;1
	brne highest_bit_not_set ;1/2
	ori r16, 0b10000000 ;1

highest_bit_not_set:

	out HIGHER_ADDRESS_PORT, r16 ;1
	ldi r16, 0 ;1
	out LOWER_ADDRESS_PORT, r16 ;1

	//36 cycles from beginning of HBP


	nop ;1
	nop ;1
	nop ;1
	nop ;1
	nop ;1
	nop ;1
	nop ;1
	nop ;1
	nop ;1
	nop ;1

	in r16, CONTROL_PORT ;1
	andi r16, ~(1<<BUFFER_ENABLE_PIN | 1<<READ_ENABLE_PIN) ;1

	//48 cycles from beginning of HBP
	//horizontal active pixels - 640 cycles


	out CONTROL_PORT, r16 ;1
	
	//256 pixels wide = 512 cycles, which leaves us with 128 cycles to do something else (64 on each end)
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1
	inc r16
	out LOWER_ADDRESS_PORT, r16 ;1

	//256 pixels sent
	

	sbi CONTROL_PORT, BUFFER_ENABLE_PIN ;2
	sbi CONTROL_PORT, READ_ENABLE_PIN ;2
	

	//restore all saved/changed data
	ldi r16, 0xFF
	out DATA_DDR, r16
	pop r16 ;2
	out CONTROL_PORT, r16 ;1
	pop r16 ;2
	out HIGHER_ADDRESS_PORT, r16 ;1
	pop r16 ;2
	out LOWER_ADDRESS_PORT, r16 ;1
	pop r16 ;2
	out LOWER_ADDRESS_DDR, r16 ;1
	pop r16 ;2
	out DATA_PORT, r16 ;1


no_video:

	sts faf_lineCounterLow, LINE_COUNTER_REGISTER_LOW ;2
	sts faf_lineCounterHigh, LINE_COUNTER_REGISTER_HIGH ;2
	pop LINE_COUNTER_REGISTER_LOW ;2
	pop LINE_COUNTER_REGISTER_HIGH ;2
	pop r17 ;2
	pop r16 ;2
	out SREG, r16 ;1
	pop r16 ;2

	reti ;4-5 ?