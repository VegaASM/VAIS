delete_loc_msg:
.asciz "\x1B[2J\x1B[HAre you sure you want to delete Location %s?\n\n7. Yes\n8/ESC. No, go back to Change Mode menu.\n"
delete_loc_please_wait:
.asciz "\x1B[2J\x1B[HPlease wait..."
delete_loc_done:
.asciz "\x1B[2J\x1B[HLocation %s has been deleted.\nPress any key to continue.\n"

.align 6
.globl delete_loc
delete_loc:
/*Prologue*/
prologue 2, 0

/*Print*/
adr x0, delete_loc_msg
add x1, masterptr, loc
bl printf

/*Idle*/
delete_loc_loop:
bl keyboard_input
cbz w0, -4
ldrb w0, [masterptr, keyboard_buffer]
cmp w0, ESC
beq delete_loc_epilogue_nonzero
cmp w0, ascii_8
beq delete_loc_epilogue_nonzero
cmp w0, ascii_7
beq yes_delete_loc
bl beep
b delete_loc_loop

/*Tell user to wait*/
yes_delete_loc:
adr x0, delete_loc_please_wait
bl puts
/*Grab data aka malloc ptr*/
mov x19, dataentry_ptr
/*Get entries amt for loop*/
mov x20, entriesamt
/*Load flag value, if invalid (deleted), check next entry*/
gc_delete_loc_loop:
ldrb w4, [x19, d_vflag]
ldr x1, [masterptr, area]
ldr x5, [masterptr, loc]
cbz w4, gc_delete_loc_incr_addr
/*Valid entry found, is area matched with inv.bin?*/
ldr x2, [x19, d_area]
cmp x1, x2
bne gc_delete_loc_incr_addr
/*Good now is loc matched with inv.bin?*/
ldr x2, [x19, d_loc]
cmp x5, x2
bne gc_delete_loc_incr_addr
/*Delete dat shit*/
strb wzr, [x19, d_vflag]
mov x0, x19
bl delete_csv_line
gc_delete_loc_incr_addr:
add x19, x19, databin_entry_size
subs x20, x20, 1
bne gc_delete_loc_loop

/*Completed*/
adr x0, delete_loc_done
add x1, masterptr, loc
bl printf
bl keyboard_input
cbz w0, -4
mov w0, 0

delete_loc_epilogue:
epilogue 2, 0

delete_loc_epilogue_nonzero:
mov w0, -1
b delete_loc_epilogue
