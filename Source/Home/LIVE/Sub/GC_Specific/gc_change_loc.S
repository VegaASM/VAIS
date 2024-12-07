gc_change_loc_please_wait_msg:
.asciz "\x1B[2J\x1B[HPlease wait..."

.data
gc_enter_loc_msg:
.asciz "\x1B[2J\x1B[HChange Loc %s to:        \n"
gc_enter_loc_end_msg:
.text
.align 6

.globl gc_change_loc
gc_change_loc:
prologue 4, 0
/*Grab width*/
ldrb w21, [invbin_ptr, locwidth]
gc_change_loc_pre_idle_loop:
adr x0, gc_enter_loc_msg
add x1, invbin_ptr, loc
bl printf
gc_change_loc_idle_loop:
bl keyboard_input
cbz w0, -4
ldrb w0, [masterptr, keyboard_buffer]
cmp w0, ESC
beq gc_change_loc_epi_task_incomplete
cmp w0, ascii_enter
beq gc_check_loc_field
cmp w0, ascii_plus
beq gc_check_loc_field
cmp w0, DELETE
beq gc_loc_erase_char
cmp w0, ascii_Z
bhi gc_loc_beep
cmp w0, ascii_0
blo gc_loc_beep
cmp w0, ascii_A
bhs gc_loc_insert_char
cmp w0, ascii_9
bls gc_loc_insert_char
gc_loc_beep:
bl beep
b gc_change_loc_idle_loop
gc_loc_insert_char:
adr x1, gc_enter_loc_end_msg-9
mov w2, w21
bl insert_char
cbz w0, gc_change_loc_pre_idle_loop
b gc_change_loc_idle_loop
gc_loc_erase_char:
adr x0, gc_enter_loc_end_msg-9
mov w1, w21
bl erase_char
cbz w0, gc_change_loc_pre_idle_loop
b gc_change_loc_idle_loop
gc_check_loc_field:
adr x0, gc_enter_loc_end_msg-9
mov w1, w21
bl enter_field
cbnz w0, gc_change_loc_idle_loop
/*Tell user to wait*/
adr x0, gc_change_loc_please_wait_msg
bl puts
/*Find all valid shit thats in qualied loc and change to new loc*/
mov x19, dataentry_ptr //get data start ptr
adr x1, gc_enter_loc_end_msg-9 //get new loc
ldr x1, [x1]
and x22, x1, 0x00FFFFFFFFFFFFFF //Clear out the \n thats at the most sig'd byte
mov x20, entriesamt //loop counter
/*cehck if valid entry, if not try next*/
gc_change_loc_loop:
ldrb w0, [x19, d_vflag]
ldr x2, [invbin_ptr, area] //get old area
ldr x5, [invbin_ptr, loc] //get old loc
cbz w0, gc_change_loc_incr_addr
/*Valid entry found, is area matched with inv.bin?*/
ldr x0, [x19, d_area]
cmp x0, x2
bne gc_change_loc_incr_addr
/*Is Loc matched with inv.bin*/
ldr x0, [x19, d_loc]
cmp x0, x5
bne gc_change_loc_incr_addr
/*Change loc*/
str x22, [x19, d_loc]
mov x0, x19
bl write_csv_line
/*Do next entry, decremetn loop*/
gc_change_loc_incr_addr:
add x19, x19, databin_entry_size
subs x20, x20, 1
bne gc_change_loc_loop
/*if and only if new loc matches loc in qestion, Write new loc to inv.bin*/
adr x0, gc_enter_loc_end_msg-9
add x1, invbin_ptr, loc
ldrb w2, [x0], 1
strb w2, [x1], 1
subs w21, w21, 1
bne -0xC
gc_change_loc_epi:
epilogue 4, 0

gc_change_loc_epi_task_incomplete:
mov w0, -1
b gc_change_loc_epi
