sound_terminal_command:
.asciz "paplay beep.ogg"
//.asciz "play -q -n -V1 synth 0.05 sin 400" //requires sox package
.align 6

.globl beep
beep:
/*Check if audio is enabled in Settings(inventory.bin)*/
ldrb w0, [invbin_ptr, soundkeyflags]
tbz w0, 0, audio_disabled
/*Audio is indeed enabled*/
prologue 0, 0
adr x0, sound_terminal_command
bl system
epilogue 0, 0
/*Audio disabled*/
audio_disabled:
ret
