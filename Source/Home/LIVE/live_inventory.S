#include "inv_funcs.S"
#include "tab_func.S"
#include "symbol_func.S"
#include "Sub/more_menus.S"
#include "Limits/price_limit_check.S"
#include "Limits/qty_limit_check.S"
#include "Limits/twindigits.S"
#include "write_entry.S"

out_of_memory_msg:
.asciz "\x1B[2J\x1B[HERROR! You are out of memory for more Inventory entries. Press any key to escape out of Live Inventory."

.data
live_info_start_field:
.ascii "\x1B[2J\x1B[HArea: %s Loc: %s Cat: %s\nPrice:           . "
price_cursor_start_spot:
.ascii " <<\n  Qty:             "
qty_cursor_start_spot:
.asciz "   \n\nTotal Inv: %.2f\nArea Total %.2f\nLoc Total %.2f\nCat Total %.2f\n\nESC = Exit Live Inventory\nTab = More Menus\n"
.text

.align 6
.globl live_inventory
live_inventory:
stp fp, lr, [sp, -0x70]! /*Cant use macro because floats*/
stp x19, x20, [sp, 0x10]
str x21, [sp, 0x20]
stp q28, q29, [sp, 0x30]
stp q30, q31, [sp, 0x50]
mov fp, sp

/*0x0 fp
0x8 lr
0x10 x19
0x18 x20
0x20 x21
0x28 unused
0x30 q28
0x40 q29
0x50 q30
0x60 q31
*/

/*Lets begin*/
__start_live_inventory:
/*First-time generate Totals*/
/*
Total cost = d0
Area total = d1
loc total = d2
cat total = d3*/
/*Total up all everything*/
movi d31, 0
movi d30, 0
movi d29, 0
movi d28, 0
mov x8, entriesamt
mov x4, dataentry_ptr

/*place inv.bin area loc and cat in x5, x6, and x7*/
ldr x5, [invbin_ptr, area]
ldr x6, [invbin_ptr, loc]
ldr x7, [invbin_ptr, cat]

/*First check if entry is valid*/
total_everything_loop:
ldrb w9, [x4, d_vflag]
cbz w9, total_everything_loop_decrementer
/*Entry is valid, do total cost first*/
ldr d4, [x4, d_cost]
fadd d31, d31, d4
/*Load enable/disable flags*/
ldrb w11, [invbin_ptr, arealoccatflags]
/*Is Area enabled?*/
tbz w11, 2, total_everything_loop_decrementer
/*Do Area total now*/
ldr x10, [x4, d_area]
cmp x5, x10
bne total_everything_loop_decrementer
fadd d30, d30, d4
/*Is Loc enabled?*/
tbz w11, 1, total_everything_loop_decrementer
/*Do Loc within Area total now*/
ldr x10, [x4, d_loc]
cmp x6, x10
bne total_everything_loop_decrementer
fadd d29, d29, d4
/*Is Cat enabled?*/
tbz w11, 0, total_everything_loop_decrementer
/*Do Cat within Loc total now*/
ldr x10, [x4, d_cat]
cmp x7, x10
bne total_everything_loop_decrementer
fadd d28, d28, d4
total_everything_loop_decrementer:
subs x8, x8, 1
add x4, x4, databin_entry_size
bne total_everything_loop

/*Set initial (live) cursor in non-volatile reg*/
adr x20, price_cursor_start_spot

/*Set qty cursor spot to check live cursor against*/
adr x19, qty_cursor_start_spot

/*Reset exit-out-of-prompt flag*/
mov w21, 0

/*Place updated floats in volatile args*/
update_float_args:
fmov d0, d31
fmov d1, d30
fmov d2, d29
fmov d3, d28

/*Place Area, loc, cat char ptrs in x1 thru x3*/
add x1, invbin_ptr, area
add x2, invbin_ptr, loc
add x3, invbin_ptr, cat

/*Print the whole field*/
adr x0, live_info_start_field
bl printf

//====================================

live_inventory_idle_loop:
/*Check exit-out-of-prompt flag*/
cbnz w21, live_call_tab_func
bl keyboard_input
cbz w0, -4
ldrb w0, [masterptr, keyboard_buffer]
cmp w0, ESC
beq live_esc_hit
cmp w0, ascii_dot
beq live_dot_hit
cmp w0, ascii_tab
beq live_more_menus
cmp w0, DELETE
beq live_del_hit
cmp w0, ascii_plus
beq live_tab_hit
cmp w0, ascii_enter
beq live_enter_hit
cmp w0, ascii_mulli
beq live_mulli_hit
cmp w0, ascii_dash
beq live_sub_hit
cmp w0, ascii_slash
beq live_div_hit
cmp w0, ascii_0
blo live_beep
cmp w0, ascii_9
bls live_insert_char
live_beep:
bl beep
b live_inventory_idle_loop

//====================================

live_esc_hit:
mov x0, x20
bl inv_esc_func
mov x20, x0
cbnz x0, update_float_args

/*Epilogue*/
live_inventory_epilogue:
mov w0, 0 //tell continue_inventory to go back to area/loc/cat selection
ldp q30, q31, [sp, 0x50]
ldp q28, q29, [sp, 0x30]
ldr x21, [sp, 0x20]
ldp x19, x20, [sp, 0x10]
ldp fp, lr, [sp], 0x70
ret

live_insert_char:
mov x1, x20 //w0 already set
bl inv_insert_char
cbz x0, update_float_args
b live_inventory_idle_loop

live_del_hit:
mov x0, x20
bl inv_erase_char
cbz x0, update_float_args
b live_inventory_idle_loop

live_dot_hit:
mov x0, x20
bl inv_insert_dot
cbz x0, update_float_args
b live_inventory_idle_loop

live_tab_hit:
/*Are we in price or qty field?*/
cmp x20, x19
bne check_priceqtyfield_for_limitchecks
/*Call twindigit checker for qty field*/
adr x0, qty_cursor_start_spot-12
bl twindigits
tbnz w0, 1, live_call_qty_limit_check
cbz w0, 0xC
mov w21, 1 //Set exit prompt flag to skip reprint
b update_float_args
movz x0, 0x2020, lsl 48
movk x0, 0x2020, lsl 32
movk x0, 0x2020, lsl 16
movk x0, 0x2020
str x0, [x19, -12] //Clear out qty field
str w0, [x19, -4]
strb w0, [x19]
b update_float_args

/*Are we in price or qty field?*/
check_priceqtyfield_for_limitchecks:
cmp x20, x19
beq live_call_qty_limit_check

/*Has Price exceeded the limits?*/
strb wzr, [curdataentry_ptr, d_pflag] //reset pflag of data entry first
adr x0, price_cursor_start_spot-12
bl price_limit_check
tbnz w0, 1, live_call_tab_func
cbz w0, 0xC
mov w21, 1 //Set exit prompt flag to skip reprint
strb w21, [curdataentry_ptr, d_pflag] //set pflag bypass high
b update_float_args
movz x0, 0x2020, lsl 48
movk x0, 0x2020, lsl 32
movk x0, 0x2020, lsl 16
movk x0, 0x2020
str x0, [x20, -12] //Clear out price field, DONT overwrite dot
strh w0, [x20, -4]
strh w0, [x20, -1]
b update_float_args

/*Has Qty exceeded the limits?*/
live_call_qty_limit_check:
strb wzr, [curdataentry_ptr, d_qflag] //reset qflag of data entry first
adr x0, qty_cursor_start_spot-12
bl qty_limit_check
tbnz w0, 1, live_call_tab_func
cbz w0, 0xC
mov w21, 1 //Set exit prompt flag to skip reprint
strb w21, [curdataentry_ptr, d_qflag] //set qflag bypass high
b update_float_args
movz x0, 0x2020, lsl 48
movk x0, 0x2020, lsl 32
movk x0, 0x2020, lsl 16
movk x0, 0x2020
str x0, [x19, -12] //Clear out qty field
str w0, [x19, -4]
strb w0, [x19]
b update_float_args

/*Alright execute the Tab func*/
live_call_tab_func:
sub x0, x20, (FIELD_MAX-1) //CURRENT field FIRST char ptr
adr x1, price_cursor_start_spot-12 //price field first char ptr
bl tab_func
cbz x0, live_out_of_memory
mov x20, x0
b update_float_args-4 /*Need to reset exit-out-of-prompt flag no matter what*/

live_enter_hit:
sub x0, x20, (FIELD_MAX-1) //arg requires we must point to FIRST char of field, NOT last
mov w1, ascii_plus
bl symbol_func
b update_float_args

live_mulli_hit:
sub x0, x20, (FIELD_MAX-1) //arg requires we must point to FIRST char of field, NOT last
mov w1, ascii_mulli
bl symbol_func
b update_float_args

live_sub_hit:
sub x0, x20, (FIELD_MAX-1) //arg requires we must point to FIRST char of field, NOT last
mov w1, ascii_dash
bl symbol_func
b update_float_args

live_div_hit:
sub x0, x20, (FIELD_MAX-1) //arg requires we must point to FIRST char of field, NOT last
mov w1, ascii_slash
bl symbol_func
b update_float_args

live_more_menus:
/*Reset fields and arrow cursor spots, YES I KNOW we can just store in reference to x19, but I want this part of code easily readable*/
movz x0, 0x2020, lsl 48
movk x0, 0x2020, lsl 32
movk x0, 0x2020, lsl 16
movk x0, 0x2020
mov w1, 0x3C3C //dub arrows in ascii
adr x2, price_cursor_start_spot
adr x3, qty_cursor_start_spot
str x0, [x2, -12] //Clear out price field, DONT overwrite dot
strh w0, [x2, -4]
strh w0, [x2, -1]
strh w1, [x2, 1] //Set dub arrows at price field
str x0, [x3, -12] //Clear out qty field
str w0, [x3, -4]
strb w0, [x3]
strh w0, [x3, 1] //Force Remove dub arrows out of qty field (ascii spaces)
bl more_menus
b __start_live_inventory /*NOTE we're lazy (for change mode shit specifically) just force recalc all the totals, this is NOT the way lol!*/

live_out_of_memory:
adr x0, out_of_memory_msg
bl puts
bl keyboard_input
cbz w0, -4
b live_inventory_epilogue
