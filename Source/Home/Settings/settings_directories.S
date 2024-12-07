settings_directories_msg:
.asciz "\x1B[2J\x1B[HArea Enabled: %s\nLoc Enabled: %s\nCat Enabled: %s\n\nChoose option:\n1. Area, Loc, Cat\n2. Area, Loc\n3. Area, Cat\n4. Area\n5. Loc, Cat\n6. Loc\n8/ESC. Go back to Settings Menu\n"
__yes_msg:
.asciz "YES"
__no_msg:
.asciz "NO"
.align 6

.globl settings_directories
settings_directories:
/*Prologue*/
prologue 0, 0

settings_directories_get_flags:
/*get arealoccat flags and update string accordingly*/
ldrb w0, [invbin_ptr, arealoccatflags]
adr x1, __yes_msg
adr x4, __no_msg
mov x2, x1
mov x3, x1
tbnz w0, 2, 0x8
mov x1, x4
tbnz w0, 1, 0x8
mov x2, x4
tbnz w0, 0, 0x8
mov x3, x4
/*Print directory msg*/
adr x0, settings_directories_msg
bl printf
/*get input and idle*/
settings_directories_idle_loop:
bl keyboard_input
cbz w0, -4
ldrb w0, [masterptr, keyboard_buffer]
cmp w0, ESC
beq settings_directories_epilogue
cmp w0, ascii_8
beq settings_directories_epilogue
cmp w0, ascii_1
blo 0xC
cmp w0, ascii_6
bls 0xC
bl beep
b settings_directories_idle_loop
/*Now grab new flags based on input using L-Table*/
adr x1, new_arealocflag_table
and w0, w0, 0x0000000F
sub w0, w0, 1
ldrb w2, [x1, x0]
/*write new flags*/
strb w2, [invbin_ptr, arealoccatflags]
/*go back to getting flags again*/
b settings_directories_get_flags

/*Epilogue*/
settings_directories_epilogue:
epilogue 0, 0

new_arealocflag_table:
.byte 0b111 //area, loc, cat
.byte 0b110 //area, loc
.byte 0b101 //area, cat
.byte 0b100 //area
.byte 0b011 //loc, cat
.byte 0b010 //loc
.align 6
