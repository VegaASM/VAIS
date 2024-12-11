gc_change_cat_please_wait_msg:
.asciz "\x1B[2J\x1B[HPlease wait..."
change_cat_completed_msg:
.asciz "\x1B[2J\x1B[HCat has been updated.\nPress any key to continue."

.data
gc_enter_cat_msg:
.asciz "\x1B[2J\x1B[HChange Cat %s to:        \n"
gc_enter_cat_end_msg:
.text
.align 6

.globl change_cat
change_cat:
prologue 4, 0
/*Grab width*/
ldrb w21, [invbin_ptr, catwidth]
gc_change_cat_pre_idle_loop:
adr x0, gc_enter_cat_msg
add x1, masterptr, cat
bl printf
gc_change_cat_idle_loop:
bl keyboard_input
cbz w0, -4
ldrb w0, [masterptr, keyboard_buffer]
cmp w0, ESC
beq gc_change_cat_epi_nonzero
cmp w0, ascii_enter
beq gc_check_cat_field
cmp w0, ascii_plus
beq gc_check_cat_field
cmp w0, DELETE
beq gc_cat_erase_char
cmp w0, ascii_Z
bhi gc_cat_beep
cmp w0, ascii_0
blo gc_cat_beep
cmp w0, ascii_A
bhs gc_cat_insert_char
cmp w0, ascii_9
bls gc_cat_insert_char
gc_cat_beep:
bl beep
b gc_change_cat_idle_loop
gc_cat_insert_char:
adr x1, gc_enter_cat_end_msg-9
mov w2, w21
bl insert_char
cbz w0, gc_change_cat_pre_idle_loop
b gc_change_cat_idle_loop
gc_cat_erase_char:
adr x0, gc_enter_cat_end_msg-9
mov w1, w21
bl erase_char
cbz w0, gc_change_cat_pre_idle_loop
b gc_change_cat_idle_loop
gc_check_cat_field:
adr x0, gc_enter_cat_end_msg-9
mov w1, w21
bl enter_field
cbnz w0, gc_change_cat_idle_loop
/*Tell user to wait*/
adr x0, gc_change_cat_please_wait_msg
bl puts
/*Find all valid shit thats in qualied cat and change to new cat*/
mov x19, dataentry_ptr //get data start ptr
adr x1, gc_enter_cat_end_msg-9 //get new cat
ldr x1, [x1]
and x22, x1, 0x00FFFFFFFFFFFFFF //Clear out the \n thats at the most sig'd byte
mov x20, entriesamt //loop counter
/*cehck if valid entry, if not try next*/
gc_change_cat_loop:
ldrb w0, [x19, d_vflag]
ldr x2, [masterptr, area] //get old area
ldr x5, [masterptr, loc] //get old loc
ldr x6, [masterptr, cat] //get old cat
cbz w0, gc_change_cat_incr_addr
/*Valid entry found, is area matched with inv.bin?*/
ldr x0, [x19, d_area]
cmp x0, x2
bne gc_change_cat_incr_addr
/*Is Loc matched with inv.bin*/
ldr x0, [x19, d_loc]
cmp x0, x5
bne gc_change_cat_incr_addr
/*Is cat matched with inv.bin*/
ldr x0, [x19, d_cat]
cmp x0, x6
bne gc_change_cat_incr_addr
/*Change cat*/
str x22, [x19, d_cat]
mov x0, x19
bl write_csv_line
/*Do next entry, decrement loop*/
gc_change_cat_incr_addr:
add x19, x19, databin_entry_size
subs x20, x20, 1
bne gc_change_cat_loop
/*if and only if new cat matches cat in question, Write new cat to inv.bin*/
adr x0, gc_enter_cat_end_msg-9
add x1, masterptr, cat
ldrb w2, [x0], 1
strb w2, [x1], 1
subs w21, w21, 1
bne -0xC

/*Reset field with spaces, causes buffer issues with printf TODO fix*/
/*adr x0, gc_enter_cat_end_msg-9
movz w1, 0x2020
str w1, [x0]
strh w1, [x0, 4]
strb w1, [x0, 6]*/

/*Done!*/
adr x0, change_cat_completed_msg
bl puts
bl keyboard_input
cbz w0, -4
mov w0, 0

gc_change_cat_epi:
epilogue 4, 0

gc_change_cat_epi_nonzero:
mov w0, -1
b gc_change_cat_epi
