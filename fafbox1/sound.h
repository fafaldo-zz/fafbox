
#ifndef __SOUND_H__
#define __SOUND_H__

#define MAX_NOTES_COUNT 100

volatile uint8_t faf_noteDurationDivider = 60;
volatile uint8_t faf_currentNoteFrame = 0;
volatile uint8_t faf_currentNote = 0;
volatile uint8_t* faf_notes;
volatile uint8_t faf_isPlaying = 0;

void initSound();
void playSound(uint8_t notes[], uint8_t loop);

#define NOTE_C4_FREQ 262
#define NOTE_C#4_FREQ 277
#define NOTE_D4_FREQ 294
#define NOTE_D#4_FREQ 311
#define NOTE_E4_FREQ 330
#define NOTE_F4_FREQ 349
#define NOTE_F#4_FREQ 370
#define NOTE_G4_FREQ 392
#define NOTE_G#4_FREQ 415
#define NOTE_A4_FREQ 440
#define NOTE_A#4_FREQ 466
#define NOTE_B4_FREQ 494

#define NOTE_C4_VAL 90
#define NOTE_C#4_VAL 90
#define NOTE_D4_VAL 90
#define NOTE_D#4_VAL 31
#define NOTE_E4_VAL 33
#define NOTE_F4_VAL 34
#define NOTE_F#4_VAL 37
#define NOTE_G4_VAL 39
#define NOTE_G#4_VAL 41
#define NOTE_A4_VAL 44
#define NOTE_A#4_VAL 40
#define NOTE_B4_VAL 49

#endif