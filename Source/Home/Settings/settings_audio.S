settings_audio_msg_on:
.asciz "\x1B[2J\x1B[HAudio Configuration\nCurrently: ON\n1. Audio (Beep) On\n2. Audio (Beep) Off\n8/ESC. Go back to Settings Menu."
settings_audio_msg_off:
.asciz "\x1B[2J\x1B[HAudio Configuration\nCurrently: OFF\n1. Audio (Beep) On\n2. Audio (Beep) Off\n8/ESC. Go back to Settings Menu."

.align 6

.globl settings_audio
settings_audio:
/*Prologue*/
prologue 0, 0

settings_audio_grab_audio:
ldrb w1, [invbin_ptr, soundkeyflags]
tbz w1, 0, 0xC
adr x0, settings_audio_msg_on
b 0x8
adr x0, settings_audio_msg_off
bl puts
settings_audio_idle_loop:
bl keyboard_input
cbz w0, -4
ldrb w0, [masterptr, keyboard_buffer]
cmp w0, ESC
beq settings_audio_epilogue
cmp w0, ascii_8
beq settings_audio_epilogue
cmp w0, ascii_1
beq set_audio_on
cmp w0, ascii_2
beq set_audio_off
bl beep
b settings_audio_idle_loop
set_audio_off:
strb wzr, [invbin_ptr, soundkeyflags]
b settings_audio_grab_audio
set_audio_on:
mov w0, 1
strb w0, [invbin_ptr, soundkeyflags]
b settings_audio_grab_audio

/*Epilogue*/
settings_audio_epilogue:
epilogue 0, 0
