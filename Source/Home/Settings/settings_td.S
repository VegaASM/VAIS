settings_td_msg_on:
.asciz "\x1B[2J\x1B[HTwin Digits Qty Field Configuration\nCurrently: ON\n1. Check for TD's\n2. Don't check for TD's\n8/ESC. Go back to Settings Menu."
settings_td_msg_off:
.asciz "\x1B[2J\x1B[HTwin Digits Qty Field Configuration\nCurrently: OFF\n1. Check for TD's\n2. Don't check for TD's\n8/ESC. Go back to Settings Menu."

.align 6

.globl settings_td
settings_td:
/*Prologue*/
prologue 0, 0

settings_td_grab_td:
ldrb w1, [invbin_ptr, tdvalue]
cbz w1, 0xC
adr x0, settings_td_msg_on
b 0x8
adr x0, settings_td_msg_off
bl puts
settings_td_idle_loop:
bl keyboard_input
cbz w0, -4
ldrb w0, [masterptr, keyboard_buffer]
cmp w0, ESC
beq settings_td_epilogue
cmp w0, ascii_8
beq settings_td_epilogue
cmp w0, ascii_1
beq set_td_on
cmp w0, ascii_2
beq set_td_off
bl beep
b settings_td_idle_loop
set_td_off:
strb wzr, [invbin_ptr, tdvalue]
b settings_td_grab_td
set_td_on:
mov w0, 1
strb w0, [invbin_ptr, tdvalue]
b settings_td_grab_td

/*Epilogue*/
settings_td_epilogue:
epilogue 0, 0
