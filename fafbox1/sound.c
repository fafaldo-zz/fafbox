#include <avr/io.h>
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
}

void playSound(uint8_t* notes, uint8_t size) {
    //resent current playing note
    faf_currentNoteFrame = 0;
    faf_currentNote = 0;
    
    //save current note buffer
    faf_notes = notes;
    
    //start playing
    faf_isPlaying = 1;
    
    //TODO start timer here
}

void stopSound() {
    //stop playing
    faf_isPlaying = 0;
    
    //TODO stop timer here
}