#include "GC_Specific/gc_change_area.S"
#include "GC_Specific/gc_change_loc.S"
#include "GC_Specific/gc_change_cat.S"

global_change_main_msg:
.asciz "\x1B[2J\x1B[HChange Mode\n\n1. Delete Area %s\n2. Delete Loc %s\n3. Delete Cat %s\n4. Change Area %s\n5. Change Loc %s\n6. Change Cat %s\nESC. Exit Change Mode\nNOTE: Loc and Cat actions are localized only!\n"
gc_are_you_sure_msg:
.asciz "\x1B[2J\x1B[HAre you sure?\n7. Yes\n8/ESC. No, abort."
gc_task_completed_msg:
.asciz "\x1B[2J\x1B[HTask completed! Press any key to exit."
gc_please_wait_msg:
.asciz "\x1B[2J\x1B[HPlease wait..."

change_mode_disabled_msg:
.asciz "\x1B[2J\x1B[HNothing to change or delete! No records!\nPress any key to exit."

gc_sub_func_table:
.xword gc_delete_area
.xword gc_delete_loc
.xword gc_delete_cat
.xword gc_change_area
.xword gc_change_loc
.xword gc_change_cat

.align 6

.globl change_mode
change_mode:
/*Prologue*/
prologue 1, 8

/*Set edit mode flag high*/
mov x0, 1
str x0, [masterptr, in_editmode_flag]

/*See if we even have records to change*/
cmp recordnum, 0
beq disable_change_mode

/*Print the msg
x1 = ptr to area char that ends in null
x2 = ptr to loc char that ends in null
x3 = ptr to cat char that ends in null*/
global_change_start:
adr x0, global_change_main_msg
add x1, invbin_ptr, area
add x2, invbin_ptr, loc
add x3, invbin_ptr, cat
mov x4, x1
mov x5, x2
mov x6, x3
bl printf
/*Read keyboard inputs*/
global_change_main_idle_loop:
bl keyboard_input
cbz w0, -4
ldrb w19, [masterptr, keyboard_buffer]
cmp w19, ESC
beq global_change_main_epilogue
cmp w19, ascii_1
blo do_gc_beep_from_gc_main
cmp w19, ascii_6
bls do_gc_are_you_sure
do_gc_beep_from_gc_main:
bl beep
b global_change_main_idle_loop

/*DO are you sure?*/
do_gc_are_you_sure:
adr x0, gc_are_you_sure_msg
bl puts
do_gc_are_you_sure_idle_loop:
bl keyboard_input
cbz w0, -4
ldrb w0, [masterptr, keyboard_buffer]
cmp w0, ESC
beq global_change_main_epilogue
cmp w0, ascii_8
beq global_change_start
cmp w0, ascii_7
beq gc_do_adr_func_stuff
bl beep
b do_gc_are_you_sure_idle_loop

/*Now set x1 to point to  part of this func/code based on number hit using lookup table*/
gc_do_adr_func_stuff:
adr x1, gc_sub_func_table
and w19, w19, 0x0000000F
sub w0, w19, 1
lsl w0, w0, 3
ldr x0, [x1, x0]

/*Go!*/
blr x0

/*Task completed or aborted, loop in idle til key hit*/
cbnz w0, global_change_main_epilogue
adr x0, gc_task_completed_msg
bl puts
bl keyboard_input
cbz w0, -4
global_change_main_epilogue:
/*Set edit mode flag low*/
str xzr, [masterptr, in_editmode_flag]
mov w0, 0 //todo some return code for now...
epilogue 1, 8

//===============================

/*HUGE TODO we need the loaded stuff from invbin to be global, this is super slow but well need to rewrite all our super global regs ugh*/

gc_delete_area:
prologue 2, 0
/*Tell user to wait*/
adr x0, gc_please_wait_msg
bl puts
/*Grab data/malloc ptr*/
mov x19, dataentry_ptr
//Get entries amt for loop
mov x20, entriesamt
//Load flag value, if invalid (deleted), check next entry
gc_delete_area_loop:
ldrb w4, [x19, d_vflag]
ldr x1, [invbin_ptr, area]
cbz w4, gc_delete_area_incr_addr
//Valid entry found, is area matched with inv.bin?
ldr x2, [x19, d_area]
cmp x1, x2
bne gc_delete_area_incr_addr
//Delete dat shit
mov w4, 0
strb w4, [x19, d_vflag]
mov x0, x19
bl delete_csv_line
gc_delete_area_incr_addr:
add x19, x19, databin_entry_size
subs x20, x20, 1
bne gc_delete_area_loop
epilogue 2, 0

//===============================

gc_delete_loc:
prologue 2, 0
/*Tell user to wait*/
adr x0, gc_please_wait_msg
bl puts
/*Grab data/malloc ptr*/
mov x19, dataentry_ptr
//Get entries amt for loop
mov x20, entriesamt
//Load flag value, if invalid (deleted), check next entry
gc_delete_loc_loop:
ldrb w4, [x19, d_vflag]
ldr x1, [invbin_ptr, area]
ldr x5, [invbin_ptr, loc]
cbz w4, gc_delete_loc_incr_addr
//Valid entry found, is area matched with inv.bin?
ldr x2, [x19, d_area]
cmp x1, x2
bne gc_delete_loc_incr_addr
//Good now is loc matched with inv.bin?
ldr x2, [x19, d_loc]
cmp x5, x2
bne gc_delete_loc_incr_addr
//Delete dat shit
mov w4, 0
strb w4, [x19, d_vflag]
mov x0, x19
bl delete_csv_line
gc_delete_loc_incr_addr:
add x19, x19, databin_entry_size
subs x20, x20, 1
bne gc_delete_loc_loop
epilogue 2, 0

//===============================

gc_delete_cat:
prologue 2, 0
/*Tell user to wait*/
adr x0, gc_please_wait_msg
bl puts
/*Grab data/malloc ptr*/
mov x19, dataentry_ptr
//Get entries amt for loop
mov x20, entriesamt
//Load flag value, if invalid (deleted), check next entry
gc_delete_cat_loop:
ldrb w4, [x19, d_vflag]
ldr x1, [invbin_ptr, area]
ldr x5, [invbin_ptr, loc]
ldr x6, [invbin_ptr, cat]
cbz w4, gc_delete_cat_incr_addr
//Valid entry found, is area matched with inv.bin?
ldr x2, [x19, d_area]
cmp x1, x2
bne gc_delete_cat_incr_addr
//Good now is loc matched with inv.bin?
ldr x2, [x19, d_loc]
cmp x5, x2
bne gc_delete_cat_incr_addr
//Good now is cat matched too?
ldr x2, [x19, d_cat]
cmp x6, x2
bne gc_delete_cat_incr_addr
//Delete dat shit
mov w4, 0
strb w4, [x19, d_vflag]
mov x0, x19
bl delete_csv_line
gc_delete_cat_incr_addr:
add x19, x19, databin_entry_size
subs x20, x20, 1
bne gc_delete_cat_loop
epilogue 2, 0

//===============================

/*gc_change_area in GC_Specific directory
gc_change_loc in GC_Specific directory
gc_change_cat in GC_Specific directory*/

//===============================

disable_change_mode:
adr x0, change_mode_disabled_msg
bl puts
bl beep
bl keyboard_input
cbz w0, -4
b global_change_main_epilogue
