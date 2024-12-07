#include "Sub/width_changer.S"

settings_widths_msg:
.asciz "\x1B[2J\x1B[HCurrent Width Settings\nArea %u, Loc %u, Cat %u\n\nChoose option:\n1. Change Area Width\n2. Change Loc Width\n3. Change Cat Width\n8/ESC. Go Back to Settings Menu.\n"

.align 6

.globl settings_widths
settings_widths:
/*Prologue*/
prologue 0, 0

/*Get all width settings*/
settings_grab_all_widths:
ldrb w1, [invbin_ptr, areawidth]
ldrb w2, [invbin_ptr, locwidth]
ldrb w3, [invbin_ptr, catwidth]
/*print*/
adr x0, settings_widths_msg
bl printf
/*read keyboard inputs*/
settings_width_idle_loop:
bl keyboard_input
cbz w0, -4
ldrb w0, [masterptr, keyboard_buffer]
cmp w0, ESC
beq settings_widths_epilogue
cmp w0, ascii_8
beq settings_widths_epilogue
cmp w0, ascii_1
blo 0xC
cmp w0, ascii_3
bls 0xC
bl beep
b settings_width_idle_loop
and w0, w0, 0x0000000F
sub w0, w0, 1
bl width_changer /*w0 arg = what width to change*/
b settings_grab_all_widths

/*Epilogue*/
settings_widths_epilogue:
epilogue 0, 0
