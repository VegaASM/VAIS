/*Args: Void
Return Values:
w0 always returns 0; tell main to idle (don't power off)*/

#include "LIVE/live_inventory.S"
#include "Char/char_nav.S"
#include "Char/is_banned_area_loc.S"

cont_int_inv_flag_high_msg:
.asciz "\x1B[2J\x1B[HNOTICE!\nInventory has not been started, or you have finalized the inventory.\nPress any key to go back to Main Menu."

.data
area_msg:
.asciz "\x1B[2J\x1B[HArea:        " /*8 spaces, 1 for whitespace, 7 for area chars*/
loc_msg:
.asciz "\x1B[2J\x1B[HLoc:        " /*8 spaces, 1 for whitespace, 7 for loc chars*/
cat_msg:
.asciz "\x1B[2J\x1B[HCat:        " /*8 spaces, 1 for whitespace, 7 for cat chars*/
end_of_cat_msg:
.text

.align 6

.globl continue_inventory
continue_inventory:
/*Prologue*/
prologue 2, 0

/*Check for finalize flag*/
ldr x0, [masterptr, finalizeflag]
cbz x0, __start_cont_inv

/*Flag is high, Stop cont-int!*/
adr x0, cont_int_inv_flag_high_msg
bl puts
bl beep
bl keyboard_input
cbz w0, -4
b continue_inventory_epilogue

__start_cont_inv:
/*Set 7 spaces in each field*/
movz x0, 0x0020, lsl 48 //ugh little endian
movk x0, 0x2020, lsl 32
movk x0, 0x2020, lsl 16
movk x0, 0x2020
adr x1, loc_msg-8
adr x2, cat_msg-8
adr x3, end_of_cat_msg-8
str x0, [x1]
str x0, [x2]
str x0, [x3]

/*Now grab widths, and place in null byte using width as offset TODO on code optimization*/
/*TODO on 0 thru 7 checks*/
mov w7, wzr
ldrb w4, [invbin_ptr, areawidth]
ldrb w5, [invbin_ptr, locwidth]
ldrb w6, [invbin_ptr, catwidth]
strb w7, [x1, x4]
strb w7, [x2, x5]
strb w7, [x3, x6]


/*Is Area Enabled?*/
__start_continue_inventory_area:
ldrb w19, [invbin_ptr, arealoccatflags]
tbz w19, 2, force_set_blank_area

/*Get Area width*/
ldrb w20, [invbin_ptr, areawidth] /*Need width for later*/

/*Copy width*/
mov w1, w20

/*Based on width, copy Area's chars to append Area: */
add x2, masterptr, area
adr x0, loc_msg-8
ldrb w3, [x2], 1
strb w3, [x0], 1
subs w1, w1, 1
bne -0xC

/*Print it out!*/
area_entry_pre_idle_loop:
adr x0, area_msg
bl puts

/*Now idle here and wait on user to overwrite or press enter*/
area_entry_idle_loop:
bl keyboard_input
cbz w0, -4
ldrb w0, [masterptr, keyboard_buffer]
cmp w0, ESC
beq continue_inventory_epilogue
cmp w0, ascii_enter
beq check_area_field
cmp w0, ascii_plus
beq check_area_field
cmp w0, DELETE
beq area_erase_char_ci
cmp w0, ascii_Z
bhi do_area_beep
cmp w0, ascii_0
blo do_area_beep
cmp w0, ascii_A
bhs area_insert_char
cmp w0, ascii_9
bls area_insert_char
do_area_beep:
bl beep
b area_entry_idle_loop
area_insert_char:
adr x1, loc_msg-8
mov w2, w20
bl insert_char
cbz w0, area_entry_pre_idle_loop
b area_entry_idle_loop
area_erase_char_ci:
adr x0, loc_msg-8
mov w1, w20
bl erase_char
cbz w0, area_entry_pre_idle_loop
b area_entry_idle_loop
check_area_field:
adr x0, loc_msg-8
mov w1, w20
bl enter_field
cbnz w0, area_entry_idle_loop
adr x0, loc_msg-8
bl is_banned_area_loc
cbnz w0, area_entry_idle_loop
/*Write new area to inv.bin*/
adr x0, loc_msg-8
add x1, masterptr, area
ldrb w2, [x0], 1
strb w2, [x1], 1
subs w20, w20, 1
bne -0xC

/*--------------------------------------*/

/*Is Location Enabled?*/
__start_continue_inventory_loc:
tbz w19, 1, force_set_blank_loc

/*Get Loc width*/
ldrb w20, [invbin_ptr, locwidth] /*Need width for later*/

/*Copy width*/
mov w1, w20

/*Based on width, copy Loc's chars to append Loc: */
add x2, masterptr, loc
adr x0, cat_msg-8
ldrb w3, [x2], 1
strb w3, [x0], 1
subs w1, w1, 1
bne -0xC

/*Print it out!*/
loc_entry_pre_idle_loop:
adr x0, loc_msg
bl puts

loc_entry_idle_loop:
bl keyboard_input
cbz w0, -4
ldrb w0, [masterptr, keyboard_buffer]
cmp w0, ESC
beq go_to_area_or_main_menu
cmp w0, ascii_enter
beq check_loc_field
cmp w0, ascii_plus
beq check_loc_field
cmp w0, DELETE
beq loc_erase_char_ci
cmp w0, ascii_Z
bhi do_loc_beep
cmp w0, ascii_0
blo do_loc_beep
cmp w0, ascii_A
bhs loc_insert_char
cmp w0, ascii_9
bls loc_insert_char
do_loc_beep:
bl beep
b loc_entry_idle_loop
go_to_area_or_main_menu:
tbnz w19, 2, __start_continue_inventory_area
b continue_inventory_epilogue

loc_insert_char:
adr x1, cat_msg-8
mov w2, w20
bl insert_char
cbz w0, loc_entry_pre_idle_loop
b loc_entry_idle_loop
loc_erase_char_ci:
adr x0, cat_msg-8
mov w1, w20
bl erase_char
cbz w0, loc_entry_pre_idle_loop
b loc_entry_idle_loop
check_loc_field:
adr x0, cat_msg-8
mov w1, w20
bl enter_field
cbnz w0, loc_entry_idle_loop
adr x0, cat_msg-8
bl is_banned_area_loc
cbnz w0, loc_entry_idle_loop
/*Write new loc to inv.bin*/
adr x0, cat_msg-8
add x1, masterptr, loc
ldrb w2, [x0], 1
strb w2, [x1], 1
subs w20, w20, 1
bne -0xC

/*--------------------------------------*/

/*Is Category Enabled?*/
__start_continue_inventory_cat:
tbz w19, 0, force_set_blank_cat

/*Get Cat width*/
ldrb w20, [invbin_ptr, catwidth] /*Need width for later*/

/*Copy width*/
mov w1, w20

/*Based on width, copy Cat's chars to append Cat: then terminate with null*/
add x2, masterptr, cat
adr x0, end_of_cat_msg-8
ldrb w3, [x2], 1
strb w3, [x0], 1
subs w1, w1, 1
bne -0xC

/*Print it out!*/
cat_entry_pre_idle_loop:
adr x0, cat_msg
bl puts

/*Now idle here and wait on user to overwrite or press enter*/
cat_entry_idle_loop:
bl keyboard_input
cbz w0, -4
ldrb w0, [masterptr, keyboard_buffer]
cmp w0, ESC
beq go_to_area_loc_or_main_menu
cmp w0, ascii_enter
beq check_cat_field
cmp w0, ascii_plus
beq check_cat_field
cmp w0, DELETE
beq cat_erase_char_ci
cmp w0, ascii_Z
bhi do_cat_beep
cmp w0, ascii_0
blo do_cat_beep
cmp w0, ascii_A
bhs cat_insert_char
cmp w0, ascii_9
bls cat_insert_char
do_cat_beep:
bl beep
b cat_entry_idle_loop
go_to_area_loc_or_main_menu:
tbnz w19, 1, __start_continue_inventory_loc
tbnz w19, 2, __start_continue_inventory_area
b continue_inventory_epilogue /*NOTE it's impossible to reach here, but just incase inventory.bin was manually edited outside of VAIS and earlier inv.bin checks didn't catch it....*/

cat_insert_char:
adr x1, end_of_cat_msg-8
mov w2, w20
bl insert_char
cbz w0, cat_entry_pre_idle_loop
b cat_entry_idle_loop
cat_erase_char_ci:
adr x0, end_of_cat_msg-8
mov w1, w20
bl erase_char
cbz w0, cat_entry_pre_idle_loop
b cat_entry_idle_loop
check_cat_field:
/*enter was done, is digit width matched?*/
adr x0, end_of_cat_msg-8
mov w1, w20
bl enter_field
cbnz w0, cat_entry_idle_loop
/*Write new cat to inv.bin*/
adr x0, end_of_cat_msg-8
add x1, masterptr, cat
ldrb w2, [x0], 1
strb w2, [x1], 1
subs w20, w20, 1
bne -0xC

/*DO LIVE INVENTORY!
No Args
w0 returns two possible values
0 - go back to cat entry
!0 - go to main menu*/
DO_LIVE_INVENTORY:
bl live_inventory
cbnz w0, continue_inventory_epilogue
/*Hacky TODO fix me*/
tbnz w19, 0, __start_continue_inventory_cat
tbnz w19, 1, __start_continue_inventory_loc
b __start_continue_inventory_area

/*Epilogue*/
continue_inventory_epilogue:
mov w0, 0 /*tell main to NOT power off*/
epilogue 2, 0

/*Force Set Area to to blank in inventory.bin*/
force_set_blank_area:
movz x0, 0x0020, lsl 48
movk x0, 0x2020, lsl 32
movk x0, 0x2020, lsl 16
movk x0, 0x2020
str x0, [masterptr, area]
b __start_continue_inventory_loc

/*Force Set Loc to to blank in inventory.bin*/
force_set_blank_loc:
movz x0, 0x0020, lsl 48
movk x0, 0x2020, lsl 32
movk x0, 0x2020, lsl 16
movk x0, 0x2020
str x0, [masterptr, loc]
b __start_continue_inventory_cat

/*Force Set Cat to to blank in inventory.bin*/
force_set_blank_cat:
movz x0, 0x0020, lsl 48
movk x0, 0x2020, lsl 32
movk x0, 0x2020, lsl 16
movk x0, 0x2020
str x0, [masterptr, cat]
b DO_LIVE_INVENTORY
