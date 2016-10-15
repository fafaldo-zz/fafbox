#ifndef __SOUND_CONTROLLER_H__
#define __SOUND_CONTROLLER_H__


#define CPU_FREQUENCY_VALUE 25175000
#define MAX_NOTES_COUNT 100


#ifndef __ASSEMBLER__

volatile uint8_t faf_noteDurationDivider = 60;
volatile uint8_t faf_currentNoteFrame = 0;
volatile uint8_t faf_currentNote = 0;
volatile uint8_t* faf_notes;
volatile uint8_t faf_notesCount = 0;

void initPorts();
void initSound(uint8_t noteDurationDivider);
void playSound(uint8_t notes[], uint8_t size);

#endif


#define NOTE_C4_FREQ 262
#define NOTE_CH4_FREQ 277
#define NOTE_D4_FREQ 294
#define NOTE_DH4_FREQ 311
#define NOTE_E4_FREQ 330
#define NOTE_F4_FREQ 349
#define NOTE_FH4_FREQ 370
#define NOTE_G4_FREQ 392
#define NOTE_GH4_FREQ 415
#define NOTE_A4_FREQ 440
#define NOTE_AH4_FREQ 466
#define NOTE_B4_FREQ 494

#define NOTE_C4_VAL (CPU_FREQUENCY_VALUE / (1024 * NOTE_C4_FREQ) - 1)
#define NOTE_CH4_VAL (CPU_FREQUENCY_VALUE / (1024 * NOTE_CH4_FREQ) - 1)
#define NOTE_D4_VAL (CPU_FREQUENCY_VALUE / (1024 * NOTE_D4_FREQ) - 1)
#define NOTE_DH4_VAL (CPU_FREQUENCY_VALUE / (1024 * NOTE_DH4_FREQ) - 1)
#define NOTE_E4_VAL (CPU_FREQUENCY_VALUE / (1024 * NOTE_E4_FREQ) - 1)
#define NOTE_F4_VAL (CPU_FREQUENCY_VALUE / (1024 * NOTE_F4_FREQ) - 1)
#define NOTE_FH4_VAL (CPU_FREQUENCY_VALUE / (1024 * NOTE_FH4_FREQ) - 1)
#define NOTE_G4_VAL (CPU_FREQUENCY_VALUE / (1024 * NOTE_G4_FREQ) - 1)
#define NOTE_GH4_VAL (CPU_FREQUENCY_VALUE / (1024 * NOTE_GH4_FREQ) - 1)
#define NOTE_A4_VAL (CPU_FREQUENCY_VALUE / (1024 * NOTE_A4_FREQ) - 1)
#define NOTE_AH4_VAL (CPU_FREQUENCY_VALUE / (1024 * NOTE_AH4_FREQ) - 1)
#define NOTE_B4_VAL (CPU_FREQUENCY_VALUE / (1024 * NOTE_B4_FREQ) - 1)

#define WHOLE_NOTE 1000
#define HALF_NOTE 500
#define QUARTER_NOTE 250


#endif