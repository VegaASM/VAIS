power_off_msg:
.asciz "\x1B[2J\x1B[HNOTICE! Data has *NOT* been finalized. Are you sure you want to Power Off?\n\n7. Yes\n8/ESC. No, go back to Main Menu."
.align 6

.globl power_off
power_off:
/*Prologue*/
prologue 0, 0
/*Check for finalize flag*/
ldr x0, [masterptr, finalizeflag]
cbz x0, power_off_pre_beep
power_off_epilogue_nonzero:
ldrb w0, [masterptr, fdstorespot]
bl close /*No sense ECing this, since we are closing VAIS anyway*/
mov w0, -1 //tell main to poweroff
power_off_epilogue:
epilogue 0, 0
/*At this point we need a standard prologue and epilogue*/
power_off_pre_beep:
adr x0, power_off_msg
bl puts
bl beep /*Beep no matter what to alert the USER*/
power_off_idle_loop:
bl keyboard_input
cbz w0, -4
ldrb w0, [masterptr, keyboard_buffer]
cmp w0, ESC
beq power_off_epilogue_zero
cmp w0, ascii_8
beq power_off_epilogue_zero
cmp w0, ascii_7
beq power_off_epilogue_nonzero
bl beep
b power_off_idle_loop
power_off_epilogue_zero:
mov w0, 0 /*Keep VAIS running*/
b power_off_epilogue
