#include "Change_Mode/change_area.S"
#include "Change_Mode/change_loc.S"
#include "Change_Mode/change_cat.S"
#include "Change_Mode/delete_area.S"
#include "Change_Mode/delete_loc.S"
#include "Change_Mode/delete_cat.S"

change_mode_main_msg:
.asciz "\x1B[2J\x1B[HCHANGE MODE\n\n1. Delete Area %s\n2. Delete Loc %s\n3. Delete Cat %s\n4. Change Area %s\n5. Change Loc %s\n6. Change Cat %s\n8/ESC. Exit Change Mode\nNOTE: Loc and Cat actions are localized only!\n"

change_mode_disabled_msg:
.asciz "\x1B[2J\x1B[HNothing to change or delete! No records!\nPress any key to exit out of Change Mode."

gc_sub_func_table:
.xword delete_area
.xword delete_loc
.xword delete_cat
.xword change_area
.xword change_loc
.xword change_cat

.align 6

.globl change_mode
change_mode:
/*Prologue*/
prologue 0, 0

/*Set edit mode flag high*/
mov w0, 1
str x0, [masterptr, in_editmode_flag]

/*See if we even have records to change*/
cmp recordnum, 0
beq disable_change_mode

/*Print the msg
x1 = ptr to area char that ends in null
x2 = ptr to loc char that ends in null
x3 = ptr to cat char that ends in null*/
global_change_start:
adr x0, change_mode_main_msg
add x1, masterptr, area
add x2, masterptr, loc
add x3, masterptr, cat
mov x4, x1
mov x5, x2
mov x6, x3
bl printf
/*Read keyboard inputs*/
global_change_main_idle_loop:
bl keyboard_input
cbz w0, -4
ldrb w0, [masterptr, keyboard_buffer]
cmp w0, ESC
beq global_change_main_epilogue
cmp w0, ascii_8
beq global_change_main_epilogue
cmp w0, ascii_1
blo do_gc_beep_from_gc_main
cmp w0, ascii_6
bls gc_do_adr_func_stuff
do_gc_beep_from_gc_main:
bl beep
b global_change_main_idle_loop

/*Call function from table based on key input*/
gc_do_adr_func_stuff:
adr x1, gc_sub_func_table
sub w0, w0, ascii_1
lsl w0, w0, 3
ldr x0, [x1, x0]
blr x0

/*If non-zero returned, DONT go back to More Menus*/
cbnz w0, global_change_start

/*Func returned*/
global_change_main_epilogue:
/*Set edit mode flag low*/
str xzr, [masterptr, in_editmode_flag]
epilogue 0, 0

/*Disable Change Mode*/
disable_change_mode:
adr x0, change_mode_disabled_msg
bl puts
bl beep
bl keyboard_input
cbz w0, -4
b global_change_main_epilogue
