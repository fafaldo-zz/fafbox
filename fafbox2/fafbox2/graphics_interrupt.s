
#include <avr/io.h>
#include "fafbox.h"
#include "graphics.h"
#include "sound.h"

#define LINE_COUNTER_REGISTER_HIGH r29
#define LINE_COUNTER_REGISTER_LOW r28

.extern faf_lineCounterHigh
.extern faf_lineCounterLow
.extern faf_noteDurationDivider
.extern faf_currentNote
.extern faf_currentNoteFrame
.extern faf_notes
.extern faf_notesCount

/*
	VGA timing:

	clock - 25.175 MHz

	Horizontal front porch - 16
	Horizontal sync porch - 96
	Horizontal back porch - 48
	Horizontal video - 640
	
	Vertical sync porch - 2
	Vertical back porch - 33
	Vertical video - 480
	Vertical front porch - 10
*/

/*
	General logic behind this interrupt:

	1. Push status register
	2. Equalize interrupt latency
	3. Turn HSYNC on
	4. Store all required registers
*/

.global TIMER1_COMPA_vect
TIMER1_COMPA_vect:

	//horizontal sync porch - 96 cycles

	push r16 ;2

	in r16, _SFR_IO_ADDR(SREG) ;1
	push r16 ;2

	//adjust interrupt response time

	lds r16, _SFR_MEM_ADDR(TCNT1L) ;2
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

	push r17 ;2

	//26 cycles from beginning of interrupt (including 16 cycles of HFP and 10 cycles of active pixels)

	//beginning of Horizontal Sync Porch

	cbi _SFR_IO_ADDR(CONTROL_PORT), HSYNC_PIN ;2
	
	push LINE_COUNTER_REGISTER_HIGH ;2
	push LINE_COUNTER_REGISTER_LOW ;2
	lds LINE_COUNTER_REGISTER_HIGH, faf_lineCounterHigh ;2
	lds LINE_COUNTER_REGISTER_LOW, faf_lineCounterLow ;2

	//10 cycles from beginning of HSP


	//PLAY SOUND

	/*
		if(is at the beginning of a frame) {
			if(is playing) {
				if(current note frame == note duration divider) {
					current note frame = 0
					current note ++

					if(current note == note count) {
						turn off counter
						exit
					}
				}

				if(current note frame == 0) {
					register = notes[current note]
				}

				current note frame ++
			}
		}
	*/

	//(1) playing = true, new note = true, finish = false, enter = true: 59 cycles +
	//(2) playing = true, new note = true, finish = false, enter = false: not possible +
	//(3) playing = true, new note = true, finish = true, enter = true/false: 49 cycles (+10) +
	//(4) playing = true, new note = false, finish = true/false, enter = true: 50 cycles (+4) -
	//(5) playing = true, new note = false, finish = true/false, enter = false: 42 cycles +6 (from difference in enter = true/false) = 48 (+6) -
	//(6) playing = false, dont care: 19 cycles (+34) -

	//we play sound only on line 255 (lower value of line counter will go through 255 only once)
	ldi r16, 0xFF ;1
	cpse LINE_COUNTER_REGISTER_LOW, r16 ;1/3
	jmp no_sound_update ;3

	push r18 ;2
	push r19 ;2
	push r30 ;2
	push r31 ;2

	sbis _SFR_IO_ADDR(GENERAL_STATUS_REGISTER), GSR_IS_PLAYING_BIT ;1/2
	rjmp after_sound_update_delay ;2

	//14 cycles (1) (3) (4) (5)

	lds r16, faf_currentNoteFrame ;2
	lds r17, faf_noteDurationDivider ;2
	lds r18, faf_currentNote ;2
	lds r19, faf_notesCount ;2

	//22 cycles (1) (3) (4) (5)

	cp r16, r17 ;1
	breq next_note ;1/2

	nop ;1
	nop ;1
	nop ;1

	nop ;1
	nop ;1

	rjmp after_next_note ;2

next_note:

	//25 cycles (1) (3)

	clr r16 ;1
	inc r18 ;1

	cp r18, r19 ;1
	breq playing_finished ;1/2
	rjmp after_next_note ;2

playing_finished:

	//30 cycles (3)

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

	clr r16 ;1
	sts _SFR_MEM_ADDR(TCCR2A), r16 ;2
	sts _SFR_MEM_ADDR(TCCR2B), r16 ;2
	cbi _SFR_IO_ADDR(GENERAL_STATUS_REGISTER), GSR_IS_PLAYING_BIT ;2
	//no need to store not frame or note - just stop playing and exit
	rjmp after_sound_update ;2

after_next_note:

	//31 cycles (1) (4) (5)

	cpi r16, 0 ;1
	breq fill_in_new_note ;1/2

	nop ;1
	nop ;1
	nop ;1

	nop ;1
	nop ;1
	nop ;1

	nop ;1

	rjmp after_fill_in_new_note ;2

fill_in_new_note:

	//34 cycles (1) (4)

	ldi r30, lo8(faf_notes) ;1
	ldi r31, hi8(faf_notes) ;1

	//we do this only if r16 is 0
	add r30, r18 ;1
	adc r31, r16 ;1

	ld r19, Z ;2
	sts _SFR_MEM_ADDR(OCR2A), r19 ;2

after_fill_in_new_note:

	//42 cycles (1) (4) (5)

	inc r16 ;1

	sts faf_currentNote, r18 ;2
	sts faf_currentNoteFrame, r16 ;2
	rjmp after_sound_update ;2

after_sound_update_delay:

	//15 cycles (6)

	//34 nops
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

after_sound_update:

	//49 cycles (1) (3) (4) (5) (6)

	pop r31 ;2
	pop r30 ;2
	pop r19 ;2
	pop r18 ;2

	rjmp sound_updated ;2

no_sound_update:

	//5 cycles (7)

	//delay 54 cycles
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
	nop ;1

	nop ;1
	nop ;1
	nop ;1
	nop ;1

sound_updated:

	//59 cycles (1) (3) (4) (5) (6) (7)

	//update sound to 100% (50% duty cycle)
	lds r16, _SFR_MEM_ADDR(OCR2A) ;2
	lsr r16 ;1
	sts _SFR_MEM_ADDR(OCR2B), r16 ;2

	//74 cycles from beginning of HSP

	sbiw LINE_COUNTER_REGISTER_LOW, 2 ;2
	brcs turn_vsync_on ;1/2
	nop ;1
	sbi _SFR_IO_ADDR(CONTROL_PORT), VSYNC_PIN ;2
	rjmp skip_turn_vsync_on ;2

turn_vsync_on:
	cbi _SFR_IO_ADDR(CONTROL_PORT), VSYNC_PIN ;2
	nop ;1
	nop ;1

skip_turn_vsync_on:
	adiw LINE_COUNTER_REGISTER_LOW, 2 ;2

	//84 cycles from beginning of HSP

	ldi r17, high(35) ;1
	cpi LINE_COUNTER_REGISTER_LOW, low(35) ;1
	cpc r17, LINE_COUNTER_REGISTER_HIGH ;1
	breq turn_pixels_on ;1/2
	nop ;1
	rjmp skip_turn_pixels_on ;2

turn_pixels_on:
	sbi _SFR_IO_ADDR(GENERAL_STATUS_REGISTER), GSR_ACTIVE_PIXELS_BIT ;2

skip_turn_pixels_on:
	
	//91 cycles from beginning of HSP

	nop ;1
	//nop ;1
	//nop ;1
	//nop ;1
	//nop ;1
	push r26 ;2
	push r27 ;2

	//96 cycles from beginning of HSP

	//horizontal back porch - 48 cycles

	sbi _SFR_IO_ADDR(CONTROL_PORT), HSYNC_PIN ;2

	ldi r17, high(515) ;1
	cpi LINE_COUNTER_REGISTER_LOW, low(515) ;1
	cpc r17, LINE_COUNTER_REGISTER_HIGH ;1
	breq turn_pixels_off ;1/2
	nop ;1
	nop ;1
	nop ;1
	rjmp skip_turn_pixels_off ;2

turn_pixels_off:
	cbi _SFR_IO_ADDR(GENERAL_STATUS_REGISTER), GSR_ACTIVE_PIXELS_BIT ;2
	sbi _SFR_IO_ADDR(GENERAL_STATUS_REGISTER), GSR_VBLANK_BIT ;2

skip_turn_pixels_off:

	//11 cycles from beginning of HBP

	ldi r17, high(524) ;1
	cpi LINE_COUNTER_REGISTER_LOW, low(524) ;1
	cpc r17, LINE_COUNTER_REGISTER_HIGH ;1
	breq clear_line_counter ;1/2
	nop ;1
	nop ;1
	nop ;1
	adiw LINE_COUNTER_REGISTER_LOW, 1 ;2
	rjmp skip_clear_line_counter ;2

clear_line_counter:
	in r17, _SFR_IO_ADDR(GENERAL_STATUS_REGISTER) ;1
	bst r17, GSR_NEW_BANK_BIT ;1
	bld r17, GSR_CURRENT_BANK_BIT ;1
	out _SFR_IO_ADDR(GENERAL_STATUS_REGISTER), r17 ;1
	clr LINE_COUNTER_REGISTER_LOW ;1
	clr LINE_COUNTER_REGISTER_HIGH	;1

skip_clear_line_counter:

	//22 cycles from beginning of HBP


	//STORE VALUES

	//CONTROL_DDR is always output - no need to store
	//CONTROL_PORT might be random so save it (i.e. OUTPUT_ENABLE_PIN pin usage during writing)
	in r17, _SFR_IO_ADDR(CONTROL_PORT) ;1
	push r17 ;2

	//LOWER_ADDRESS_DDR is always output outside of interrupt - no need to store it (it is input only here)
	//LOWER_ADDRESS_PORT might be random so save it (i.e. during writing)
	in r16, _SFR_IO_ADDR(LOWER_ADDRESS_PORT) ;1
	push r16 ;2
	
	//HIGHER_ADDRESS_DDR is always output - no need to store, only 1 pin is overriden as input when in SPI mode
	//HIGHER_ADDRESS_PORT might be random so save it (i.e. during writing)
	in r16, _SFR_IO_ADDR(HIGHER_ADDRESS_PORT) ;1
	push r16 ;2

	//DATA_DDR is always output - no need to store, set as input only here during reading
	//DATA_PORT might be random so save it (i.e. during writing)
	in r16, _SFR_IO_ADDR(DATA_PORT) ;1
	push r16 ;2

	//34 cycles from beginning of HBP


	//SET VALUES

	//cancel all irrelevant outputs in CONTROL_PORT (currently stored in r17)
	//we set BANK_SWITCH_PIN to 1, as we will clear it in a second if needed
	//we set WRITE_READ_ENABLE_PIN to write for now, as setting it to read later will open video buffer, it should be write anyway, if OUTPUT_ENABLE_PIN was on, we turn it off to stop writing
	//we set OUTPUT_ENABLE_PIN to stop writing
	//we do not touch HSYNC_PIN
	//we do not touch VSYNC_PIN
	//we set PERIPHERAL_ENABLE_PIN to disable for now (we will turn it on after we set all ports as input), it should be turned off anyway but whatever
	//we do not touch SOUND_PIN - pushing and poping sound bit should not override sound pin behavior
	//we deselect NETWORK_ENABLE_PIN, it should be turned off anyway but whatever
	ori r17, (1<<BANK_SWITCH_PIN | 1<<WRITE_ENABLE_PIN | 1<<READ_ENABLE_PIN | 1<<PERIPHERAL_ENABLE_PIN | 1<<NETWORK_ENABLE_PIN) ;1
	out _SFR_IO_ADDR(CONTROL_PORT), r17 ;1

	//set port as input with pull-ups, before we open controller buffer
	ldi r16, 0x00 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_DDR), r16 ;1
	ldi r17, 0xFF ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r17 ;1

	//set port as output with all ones for now, before we open sd buffer, not to select CS line by mistake; no need to change DDR
	out _SFR_IO_ADDR(HIGHER_ADDRESS_PORT), r17 ;1

	//TODO global register for control port might improve speed (saves instruction cycles)

	//now we enable all peripherals
	in r17, _SFR_IO_ADDR(CONTROL_PORT) ;1
	andi r17, ~(1<<PERIPHERAL_ENABLE_PIN) ;1
	out _SFR_IO_ADDR(CONTROL_PORT), r17 ;1


	//READ INPUT

	in r16, CONTROLLER_PIN ;1
	out _SFR_IO_ADDR(CONTROLLER_STATUS_REGISTER), r16 ;1


	sbis _SFR_IO_ADDR(GENERAL_STATUS_REGISTER), GSR_ACTIVE_PIXELS_BIT ;1/2
	rjmp no_video ;2

video:	

	//48 cycles from beginning of HBP

	//horizontal active pixels - 640 cycles -> 640 cycles - 512 for activepixels = 128 free pixels / 2 = 64 pixels on each side to make sure video is centered - dont care for now

	//now we disable all peripherals
	ori r17, (1<<PERIPHERAL_ENABLE_PIN) ;1
	out _SFR_IO_ADDR(CONTROL_PORT), r17 ;1

	//no need to chage higher address

	//now we turn lower back to being output
	ldi r16, 0xFF ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_DDR), r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1

	//set port as floating input, to protect from short-circuit when we do reading
	ldi r16, 0 ;1
	out _SFR_IO_ADDR(DATA_DDR), r16 ;1

	//7 cycles from beginning of HAP

	//we copied new bank at the beginning of the new frame, now we test its value and if its 0 then clear it
	sbis _SFR_IO_ADDR(GENERAL_STATUS_REGISTER), GSR_CURRENT_BANK_BIT ;1/2 
	andi r17, ~(1<<BANK_SWITCH_PIN) ;1
	out _SFR_IO_ADDR(CONTROL_PORT), r17 ;1


	mov r26, LINE_COUNTER_REGISTER_LOW ;1
	mov r27, LINE_COUNTER_REGISTER_HIGH ;1
	sbiw r26, 36 ;2

	//TODO make sure we increment line counter in good place
	//we divide line counter by 2, to doulbe each line and display 240 lines
	lsr r26 ;1
	cpi r27, 0x01 ;1
	brne highest_bit_not_set ;1/2
	ori r26, 0b10000000 ;1

highest_bit_not_set:

	//call my_delay

	/*
	cpi LINE_COUNTER_REGISTER_LOW, 0
	breq iszero
	ldi r26, 1
	rjmp iszerodalej
iszero:
	ldi r26, 2
iszerodalej:
*/
	//ldi r16, 0b10101010
	out _SFR_IO_ADDR(HIGHER_ADDRESS_PORT), r26 ;1
	ldi r16, 0 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1


	//cli

	//call my_delay


	//starting read will open video buffer
	andi r17, ~(1<<READ_ENABLE_PIN) ;1

	//15 cycles from beginning of HAP

	out _SFR_IO_ADDR(CONTROL_PORT), r17 ;1
	
	/*
	call my_delay
	call my_delay
	call my_delay
	call my_delay
	call my_delay
	call my_delay
	call my_delay
	call my_delay
	call my_delay
	call my_delay
	call my_delay
	call my_delay
	call my_delay
	call my_delay
	call my_delay
	call my_delay
	call my_delay
	call my_delay
	call my_delay
	call my_delay
	call my_delay
	call my_delay
	call my_delay
	call my_delay
	call my_delay
	call my_delay
	call my_delay
	call my_delay
	call my_delay*/
	//call my_delay
	
	//256 pixels wide = 512 cycles, which leaves us with 128 cycles to do something else (64 on each end)
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	//call my_delay
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	//call my_delay
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	//call my_delay
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	//call my_delay
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	//call my_delay
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	//call my_delay
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	//call my_delay
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	//call my_delay
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	//call my_delay
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	//call my_delay
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1

	//call my_delay
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1

	//call my_delay

	//sei

	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	inc r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	

	//256 pixels sent
	
	//we stop reading (that will close video buffer) and outputting data
	ori r17, (1<<READ_ENABLE_PIN) ;1
	out _SFR_IO_ADDR(CONTROL_PORT), r17 ;1

	//return data port to output, we not have any data left on RAM pins as we disabled output
	ldi r16, 0xFF ;1
	out _SFR_IO_ADDR(DATA_DDR), r16 ;1

	//restore all saved/changed data
	pop r16 ;2
	out _SFR_IO_ADDR(DATA_PORT), r16 ;1
	pop r16 ;2
	out _SFR_IO_ADDR(HIGHER_ADDRESS_PORT), r16 ;1
	pop r16 ;2
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	pop r16 ;2
	out _SFR_IO_ADDR(CONTROL_PORT), r16 ;1

	sts faf_lineCounterLow, LINE_COUNTER_REGISTER_LOW ;2
	sts faf_lineCounterHigh, LINE_COUNTER_REGISTER_HIGH ;2
	pop LINE_COUNTER_REGISTER_LOW ;2
	pop LINE_COUNTER_REGISTER_HIGH ;2
	pop r17 ;2
	pop r27 ;2
	pop r26 ;2
	pop r16 ;2
	out _SFR_IO_ADDR(SREG), r16 ;1
	pop r16 ;2

	reti ;4-5 ?

no_video:

	//48 cycles from beginning of HBP

	//horizontal active pixels - 640 cycles
	
	//do some reading and writing to SPI here

	//now we disable all peripherals
	ori r17, (1<<PERIPHERAL_ENABLE_PIN) ;1
	out _SFR_IO_ADDR(CONTROL_PORT), r17 ;1

	//do not change data port for now
	//no need to chage higher address

	//now we turn lower back to being output
	ldi r16, 0xFF ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_DDR), r16 ;1
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1


	ldi r16, 0xFF ;1
	cpse LINE_COUNTER_REGISTER_LOW, r16 ;1/3
	jmp no_inc ;3

	lds r16, faf_secondsCounter
	inc r16
	sts faf_secondsCounter, r16

no_inc:


	//restore all saved/changed data
	pop r16 ;2
	out _SFR_IO_ADDR(DATA_PORT), r16 ;1
	pop r16 ;2
	out _SFR_IO_ADDR(HIGHER_ADDRESS_PORT), r16 ;1
	pop r16 ;2
	out _SFR_IO_ADDR(LOWER_ADDRESS_PORT), r16 ;1
	pop r16 ;2
	out _SFR_IO_ADDR(CONTROL_PORT), r16 ;1


	sts faf_lineCounterLow, LINE_COUNTER_REGISTER_LOW ;2
	sts faf_lineCounterHigh, LINE_COUNTER_REGISTER_HIGH ;2
	pop LINE_COUNTER_REGISTER_LOW ;2
	pop LINE_COUNTER_REGISTER_HIGH ;2
	pop r17 ;2
	pop r27 ;2
	pop r26 ;2
	pop r16 ;2
	out _SFR_IO_ADDR(SREG), r16 ;1
	pop r16 ;2

	reti ;4-5 ?
	
my_delay:
	

	ldi r18, 0
pe1:
	ldi r19, 0
pe2:
	ldi r20, 0
pe3:
	inc r20
	cpi r20, 255
	brne pe3

	inc r19
	cpi r19, 255
	brne pe2

	inc r18
	cpi r18, 255
	brne pe1
	
	ret