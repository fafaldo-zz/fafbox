

#define __SFR_OFFSET 0

#include <avr/io.h>
#include "fafbox.h"

.extern licznik_linii_sram_1
.extern licznik_linii_sram_2
.extern piksele_sram

.global TIMER1_COMPA_vect
TIMER1_COMPA_vect:

	// horizontal sync porch - 76 cykli

	push r16 ;2

	in r16, SREG ;1
	push r16 ;2

	lds r16, TCNT1L ;2
	cpi r16, 16 ;1
	breq szesnascie ;1/2
	cpi r16, 15 ;1
	breq pietnascie ;1/2
	cpi r16, 14 ;1
	breq czternascie ;1/2
	cpi r16, 13 ;1
	breq trzynascie ;1/2
	cpi r16, 12 ;1
	breq dwanascie ;1/2

szesnascie:
	nop ;1
pietnascie:
	nop ;1
czternascie:
	nop ;1
trzynascie:
	nop ;1
dwanascie:


	// tutaj po 24 cyklach od rozpoczêcia przerwania i od pocz¹tku HSP

	cbi SYNC_PORT, HSYNC_PIN ;2

	push r17 ;2
	push licznik_linii_reg_1 ;2
	push licznik_linii_reg_2 ;2
	lds licznik_linii_reg_1, licznik_linii_sram_1 ;2
	lds licznik_linii_reg_2, licznik_linii_sram_2 ;2

	// tutaj po 36 cyklach od HSP

	//ldi r16, low(525 ;1
	ldi r17, high(491) ;1
	cpi licznik_linii_reg_1, low(491) ;1
	cpc r17, licznik_linii_reg_2 ;1
	breq wlacz_vsync ;1/2
	nop ;1
	rjmp dalej_wlacz_vsync ;2

wlacz_vsync:
	cbi SYNC_PORT, VSYNC_PIN ;2

dalej_wlacz_vsync:

	// tutaj po 43 cyklach od HSP

	//ldi r16, low(2 ;1
	ldi r17, high(493) ;1
	cpi licznik_linii_reg_1, low(493) ;1
	cpc r17, licznik_linii_reg_2 ;1
	breq wylacz_vsync ;1/2
	nop ;1
	rjmp dalej_wylacz_vsync ;2

wylacz_vsync:
	sbi SYNC_PORT, VSYNC_PIN ;2

dalej_wylacz_vsync:

	// tutaj po 50 cyklach od HSP

	//ldi r16, low(34 ;1
	ldi r17, high(524) ;1
	cpi licznik_linii_reg_1, low(524) ;1
	cpc r17, licznik_linii_reg_2 ;1
	breq wlacz_piksele ;1/2
	nop ;1
	nop ;1
	nop
	rjmp dalej_wlacz_piksele ;2

wlacz_piksele:
	//ldi piksele_reg, 1 ;1
	sbi VIDEO_REGISTER, ACTIVE_PIXELS_BIT ;2
	clr licznik_linii_reg_1 ;1
	clr licznik_linii_reg_2 ;1

dalej_wlacz_piksele:
	

	// tutaj po 59 cyklach od HSP

	//ldi r16, low(514 ;1
	ldi r17, high(480) ;1
	cpi licznik_linii_reg_1, low(480) ;1
	cpc r17, licznik_linii_reg_2 ;1
	breq wylacz_piksele ;1/2
	nop ;1
	nop ;1
	nop ;1
	rjmp nie_wylaczaj_pikseli ;2
wylacz_piksele:
	cbi VIDEO_REGISTER, ACTIVE_PIXELS_BIT ;2
	sbi VIDEO_REGISTER, VBLANK_BIT ;2

nie_wylaczaj_pikseli:


	// tutaj po 68 cyklach od HSP

	nop
	nop
	//nop
	//nop
	//nop
	//nop
	
	
	
	sbi SYNC_PORT, HSYNC_PIN ;2

	// tutaj koñczy siê horizontal sync porch, trwa³ 76 cykli

	// tutaj zaczyna siê horizontal back porch - 36 cykli


	sbis VIDEO_REGISTER, ACTIVE_PIXELS_BIT ;1/2
	rjmp nie_ma_obrazu ;2


jest_obraz:


	; DATA_DDR jest zawsze wyjsciem wiec nie ma sensu zapisywac
	; DATA_PORT mogl miec dowolna wartosc, bo moglismy akurat cos zapisywac do RAMu
	in r16, DATA_PORT ;1
	push r16 ;2
	; LOWER_ADDRESS_PORT mogl miec dowolna wartosc bo moglismy akurat zapisywac cos do RAMu
	in r16, LOWER_ADDRESS_PORT ;1
	push r16 ;2
	; LOWER_ADDRESS_DDR mogl miec dowolna wartosc, bo mogl byc w trakcie zapisywania do RAMu lub odczytu wejsc
	in r16, LOWER_ADDRESS_DDR ;1
	push r16 ;2
	; HIGHER_ADDRESS_DDR jest zawsze wyjsciem, nie ma sensu zapisywac
	; HIGHER_ADDRESS_PORT mogl miec dowolna wartosc j.w.
	in r16, HIGHER_ADDRESS_PORT ;1
	push r16 ;2
	; CONTROL_PORT_DDR jest zawsze wyjsciem
	; CONTROL_PORT mogl miec dowolna wartosc, bo moglismy akurat cos zapisywac do RAMu uzywajac WRITE_ENABLE_PIN lub READ_ENABLE_PIN wiec zapisujemy
	in r16, CONTROL_PORT ;1
	push r16 ;2


	; ustawiamy caly CONTROL_PORT na 1
	ori r16, (1<<HSYNC_PIN | 1<<VSYNC_PIN | 1<<WRITE_ENABLE_PIN | 1<<READ_ENABLE_PIN | 1<<BUFFER_ENABLE_PIN | 1<<PERIPHERAL_ENABLE_PIN | 1<<BANK_SWITCH_PIN) ;1

	; jesli aktualny BANK jest ustawiony na 0 (ten do którego akutalnie wpisujemy nowe dane) to pomijamy i rysujemy z banku 1
	; jesli aktualny bank do ktorego piszemy jest 1, to rysujemy z banku 0
	; wpis w VIDEO_REGISTER jest zmieniany po kazdym zakonczeniu wpisywania ramki i oznacza gdzie aktualnie WPISUJEMY dane (RYSUJEMY dane zawsze z przeciwnego).
	sbic VIDEO_REGISTER, BANK_SELECT_BIT ;1/2 
	andi r16, ~(1<<BANK_SWITCH_PIN) ;1


	out CONTROL_PORT, r16 ;1

	ldi r16, 0x00 ;1
	out DATA_PORT, r16 ;1
	out DATA_DDR, r16 ;1 
	ldi r16, 0xFF ;1
	out LOWER_ADDRESS_DDR, r16 ;1

	//26

	mov r16, licznik_linii_reg_1 ;1
	lsr r16 ;1
	cpi licznik_linii_reg_2, 0x01 ;1
	brne nie_dodawaj ;1/2
	ori r16, 0b10000000 ;1


nie_dodawaj:

	
	lsr r16 ;1
	lsl r16 ;1


	out HIGHER_ADDRESS_PORT, r16 ;1
	ldi r16, 0 ;1
	out LOWER_ADDRESS_PORT, r16 ;1

	//36

	in r16, CONTROL_PORT ;1
	andi r16, ~(1<<BUFFER_ENABLE_PIN | 1<<READ_ENABLE_PIN) ;1
	out CONTROL_PORT, r16 ;1
	
	//39
	ldi r16, 1 ;1
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

	
	
	

	sbi CONTROL_PORT, BUFFER_ENABLE_PIN ;2
	sbi CONTROL_PORT, READ_ENABLE_PIN ;2
	

	; odnawiamy wszystkie zmienione porty
	pop r16 ;2
	out CONTROL_PORT, r16 ;1
	pop r16 ;2
	out HIGHER_ADDRESS_PORT, r16 ;1
	pop r16 ;2
	out LOWER_ADDRESS_DDR, r16 ;1
	pop r16 ;2
	out LOWER_ADDRESS_PORT, r16 ;1
	pop r16 ;2
	out DATA_PORT, r16 ;1	
	; ustawiamy data jako wyjscie (nie wiem po co skoro zawsze jest wyjsciem ale nei usuwam skoro dziala)
	ldi r16, 0xFF
	out DATA_DDR, r16
	

nie_ma_obrazu:

	adiw licznik_linii_reg_1, 1 ;2
	sts licznik_linii_sram_1, licznik_linii_reg_1 ;2
	sts licznik_linii_sram_2, licznik_linii_reg_2 ;2
	pop licznik_linii_reg_2 ;2
	pop licznik_linii_reg_1 ;2
	pop r17 ;2
	pop r16 ;2
	out SREG, r16 ;1
	pop r16 ;2

	reti ;