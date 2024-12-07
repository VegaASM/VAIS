/*w0 = 0 or 1
0 = max qty
1 = min qty*/

maxmin_qty_sscanf_item:
.asciz "%lf"
.align 6
qty_max_string:
.asciz "Max"
qty_min_string:
.asciz "Min"

qty_maxmin_string_table:
.xword qty_max_string
.xword qty_min_string

.data
maxmin_qty_msg:
.asciz "\x1B[2J\x1B[HPress ESC at any time to go back to Settings Menu.\n\nCurrent %s Qty is %f\nEnter new value:              \n"
maxmin_qty_msg_end:
.text

.globl maxmin_qty
maxmin_qty:
/*Prologue*/
prologue 1, 0x38
/*0x10 thru 0x1F ascii float
0x20 thru 0x27 sscanf x2 arg*/

/*Save index after we mulli it by 8*/
lsl w19, w0, 3

/*Get Max/Min Price (using index) and do printf*/
maxmin_qty_pre_loop:
add x0, invbin_ptr, maxqty
ldr d0, [x0, x19] //use index as offset
adr x1, qty_maxmin_string_table
ldr x1, [x1, x19] //use index as offset
adr x0, maxmin_qty_msg
bl printf
/*Now wait for user to enter new max/min qty*/
maxmin_qty_idle_loop:
bl keyboard_input
cbz w0, -4
ldrb w0, [masterptr, keyboard_buffer]
cmp w0, ESC
beq mmq_escape
cmp w0, ascii_enter
beq mmq_check_field
cmp w0, ascii_plus
beq mmq_check_field
cmp w0, DELETE
beq mmq_erase_char //TODO put in decimal check and code for it!
cmp w0, ascii_0
blo do_mmq_beep
cmp w0, ascii_9
bls mmq_insert_char
do_mmq_beep:
bl beep
b maxmin_qty_idle_loop

mmq_escape:
/*Clear the field*/
adr x0, maxmin_qty_msg_end-3
movz x1, 0x2020, lsl 48
movk x1, 0x2020, lsl 32
movk x1, 0x2020, lsl 16
movk x1, 0x2020
str x1, [x0, -12]
str w1, [x0, -4]
strb w1, [x0]
b maxmin_qty_epilogue

mmq_insert_char:
adr x5, maxmin_qty_msg_end-3
ldrb w1, [x5, -12]
cmp w1, ascii_space
bne do_mmq_beep
/*Shift contents left to make room at cursor spot*/
ldr x1, [x5, -11]
ldr w2, [x5, -3]
str x1, [x5, -12]
str w2, [x5, -4]
/*now insert the char!*/
strb w0, [x5]
b maxmin_qty_pre_loop

mmq_erase_char:
adr x5, maxmin_qty_msg_end-3
ldrb w1, [x5]
cmp w1, ascii_space
beq do_mmq_beep
/*shift contents right*/
ldr x1, [x5, -12]
ldr w2, [x5, -4]
mov w0, ascii_space
str x1, [x5, -11]
str w2, [x5, -3]
/*Write space at first char slot*/
strb w0, [x5, -12]
b maxmin_qty_pre_loop

mmq_check_field:
/*Make sure some number was inserted in field*/
adr x1, maxmin_qty_msg_end-3
ldrb w0, [x1]
cmp w0, ascii_space
beq do_mmq_beep

/*Write new max/min price to inventory.bin*/
/*Transfer ONLy the ascii float to stack buffer*/
adr x0, maxmin_qty_msg_end-15
add x1, sp, 0x10
ldr x2, [x0]
ldr w3, [x0, 8]
ldrb w4, [x0, 12]
mov w5, 0
str x2, [x1]
str w3, [x1, 8]
strb w4, [x1, 12]
strb w5, [x1, 13] /*Make sure it ends in null byte*/

/*Change all spaces to ascii zero's*/
add x0, sp, 0x10
mov w1, 13
mov w2, ascii_0
ldrb w3, [x0], 1
cmp w3, ascii_space
bne 0x8
strb w2, [x0, -1]
subs w1, w1, 1
bne -0x14

/*Sscanf it and put dump spot further in stack buffer*/
add x0, sp, 0x10
adr x1, maxmin_qty_sscanf_item
add x2, sp, 0x20
bl sscanf /*should we EC this?*/

/*write to inv.bin and reprint*/
add x0, invbin_ptr, maxqty
ldr d0, [sp, 0x20]
str d0, [x0, x19] //use index for the store

/*reclear the field*/
adr x0, maxmin_qty_msg_end-3
movz x1, 0x2020, lsl 48
movk x1, 0x2020, lsl 32
movk x1, 0x2020, lsl 16
movk x1, 0x2020
str x1, [x0, -12]
str w1, [x0, -4]
strb w1, [x0]
b maxmin_qty_pre_loop

/*Epilogue*/
maxmin_qty_epilogue:
epilogue 1, 0x38
