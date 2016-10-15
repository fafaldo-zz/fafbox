#include <avr/io.h>
#include "fafbox.h"
#include "sound.h"


/*
    Code responsible for playing sounds. It uses Timer0 available in Atmega644 to generate a PWM signal to drive our connected buzzer.
    PWM frequencies are defined in a separate header files, both - frequencies (in Hertz) and corresponding counter value.
    Sound is generated on OC0B pin of the microcontroller.
    
    Notes should be stored as global uint8_t arrays, and passed to playSound() method along with array's length.
    Notes duration is defined during init, and should be provided as an appropriate divider value defined as 'number of frames each note should last minus 1' (range 0-255). 
    Because refresh rate is 60Hz, value of 59 will result in note lasting for 1 second, 119 for 2 seconds and so on. Values larger then 255 (approximately 4.25 seconds) are invalid.
*/

void initSound(uint8_t noteDurationDivider) {
    faf_noteDurationDivider = noteDurationDivider; //add some assertions
    
    //do initialization of timers and port here, do not turn on timer as it will automatically start playing sound from buzzer
    TIMSK2 = 0;
    GENERAL_STATUS_REGISTER &= ~(1<<GSR_IS_PLAYING_BIT);
}

void playSound(uint8_t* notes, uint8_t size) {
    //resent current playing note
    faf_currentNoteFrame = 0;
    faf_currentNote = 0;
    
    //save current note buffer
    faf_notes = notes;
    faf_notesCount = size;
    
    TCCR2A = (1<<COM2B1 | 1<<WGM21 | 1<<WGM20);
    TCCR2B = (1<<WGM22 | 1<<CS22 | 1<<CS21 | 1<<CS20);

    //start playing
    GENERAL_STATUS_REGISTER |= (1<<GSR_IS_PLAYING_BIT);
}

void stopSound() {
    //stop playing
    GENERAL_STATUS_REGISTER &= ~(1<<GSR_IS_PLAYING_BIT);
    
    TCCR2A = 0;
    TCCR2B = 0;
}