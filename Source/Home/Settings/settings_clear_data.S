settings_clear_data_msg:
.asciz "\x1B[2J\x1B[HAre you sure you want to Clear Data?\n7. Yes\n8/ESC. No, go back to Settings Menu."
settings_clear_data_clearing_msg:
.asciz "\x1B[2J\x1B[HClearing Data... Please wait..."
settings_data_has_been_cleared:
.asciz "\x1B[2J\x1B[HData has been cleared. Press any key to go back to Settings Menu."

.align 6

.globl settings_clear_data
settings_clear_data:
/*Prologue*/
prologue 0, 0

/*Print clear data msg*/
adr x0, settings_clear_data_msg
bl puts
settings_clear_data_idle_loop:
bl keyboard_input
cbz w0, settings_clear_data_idle_loop
ldrb w0, [masterptr, keyboard_buffer]
cmp w0, ESC
beq settings_clear_data_epilogue
cmp w0, ascii_8
beq settings_clear_data_epilogue
cmp w0, ascii_7
beq yes_clear_data
bl beep
b settings_clear_data_idle_loop
yes_clear_data:
adr x0, settings_clear_data_clearing_msg
bl puts
mov recordnum, 0
mov curdataentry_ptr, dataentry_ptr
mov x0, dataentry_ptr
mov x1, entriesamt
yes_clear_data_loop:
str xzr, [x0], databin_entry_size //clear vflag, eflag, pflag, and qflag
subs x1, x1, 1
bne yes_clear_data_loop
/*Data is now cleared, idle and wait*/
adr x0, settings_data_has_been_cleared
bl puts
bl keyboard_input
cbz w0, -4

/*Epilogue*/
settings_clear_data_epilogue:
epilogue 0, 0
