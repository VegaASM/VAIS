delete_area_msg:
.asciz "\x1B[2J\x1B[HAre you sure you want to delete Area %s?\n\n7. Yes\n8/ESC. No, go back to Change Mode menu.\n"
delete_area_please_wait:
.asciz "\x1B[2J\x1B[HPlease wait..."
delete_area_done:
.asciz "\x1B[2J\x1B[HArea %s has been deleted.\nPress any key to continue.\n"

.align 6
.globl delete_area
delete_area:
/*Prologue*/
prologue 2, 0

/*Print*/
adr x0, delete_area_msg
add x1, masterptr, area
bl printf

/*Idle*/
delete_area_loop:
bl keyboard_input
cbz w0, -4
ldrb w0, [masterptr, keyboard_buffer]
cmp w0, ESC
beq delete_area_epilogue_nonzero
cmp w0, ascii_8
beq delete_area_epilogue_nonzero
cmp w0, ascii_7
beq yes_delete_area
bl beep
b delete_area_loop

/*Tell user to wait*/
yes_delete_area:
adr x0, delete_area_please_wait
bl puts
/*Grab data aka malloc ptr*/
mov x19, dataentry_ptr
/*Get entries amt for loop*/
mov x20, entriesamt
/*Load flag value, if invalid (deleted), check next entry*/
gc_delete_area_loop:
ldrb w4, [x19, d_vflag]
ldr x1, [masterptr, area]
cbz w4, gc_delete_area_incr_addr
/*Valid entry found, is area matched with inv.bin?*/
ldr x2, [x19, d_area]
cmp x1, x2
bne gc_delete_area_incr_addr
/*Delete dat shit*/
strb wzr, [x19, d_vflag]
mov x0, x19
bl delete_csv_line
gc_delete_area_incr_addr:
add x19, x19, databin_entry_size
subs x20, x20, 1
bne gc_delete_area_loop

/*Completed*/
adr x0, delete_area_done
add x1, masterptr, area
bl printf
bl keyboard_input
cbz w0, -4
mov w0, 0

delete_area_epilogue:
epilogue 2, 0

delete_area_epilogue_nonzero:
mov w0, -1
b delete_area_epilogue
