/*w0 = 0 or 1
0 = max price
1 = min price*/

maxmin_price_sscanf_item:
.asciz "%lf"
.align 6
price_max_string:
.asciz "Max"
price_min_string:
.asciz "Min"

price_maxmin_string_table:
.xword price_max_string
.xword price_min_string

.data
maxmin_price_msg:
.asciz "\x1B[2J\x1B[HPress ESC at any time to go back to Settings Menu.\n\nCurrent %s Price is %.2f\nEnter new value:           .  \n"
maxmin_price_msg_end:
.text

.globl maxmin_price
maxmin_price:
/*Prologue*/
prologue 1, 0x38
/*0x10 thru 0x1F ascii float
0x20 thru 0x27 sscanf x2 arg*/

/*Save index after we mulli it by 8*/
lsl w19, w0, 3

/*Get Max/Min Price (using index) and do printf*/
maxmin_price_pre_loop:
add x0, invbin_ptr, maxprice
ldr d0, [x0, x19] //utilize index
adr x1, price_maxmin_string_table
ldr x1, [x1, x19] //utilize index
adr x0, maxmin_price_msg
bl printf
/*Now wait for user to enter new max/min price*/
maxmin_price_idle_loop:
bl keyboard_input
cbz w0, -4
ldrb w0, [masterptr, keyboard_buffer]
cmp w0, ESC
beq mmp_escape
cmp w0, ascii_enter
beq mmp_check_field
cmp w0, ascii_plus
beq mmp_check_field
cmp w0, DELETE
beq mmp_erase_char
cmp w0, ascii_0
blo do_mmp_beep
cmp w0, ascii_9
bls mmp_insert_char
do_mmp_beep:
bl beep
b maxmin_price_idle_loop

mmp_escape:
/*Clear the field*/
adr x0, maxmin_price_msg_end-3
movz x1, 0x2020, lsl 48
movk x1, 0x2020, lsl 32
movk x1, 0x2020, lsl 16
movk x1, 0x2020
str x1, [x0, -12]
strh w1, [x0, -4]
strh w1, [x0, -1]
b maxmin_price_epilogue

mmp_insert_char:
adr x5, maxmin_price_msg_end-3
ldrb w1, [x5, -12]
cmp w1, ascii_space
bne do_mmp_beep
/*Shift contents left to make room at cursor spot*/
ldr x1, [x5, -11]
ldrb w2, [x5, -3]
ldrb w3, [x5, -1]
ldrb w4, [x5]
str x1, [x5, -12]
strb w2, [x5, -4]
strb w3, [x5, -3]
strb w4, [x5, -1]
/*now insert the char!*/
strb w0, [x5]
b maxmin_price_pre_loop

mmp_erase_char:
adr x5, maxmin_price_msg_end-3
ldrb w1, [x5]
cmp w1, ascii_space
beq do_mmp_beep
/*shift contents right*/
ldr x1, [x5, -12]
ldrb w2, [x5, -4]
ldrb w3, [x5, -3]
ldrb w4, [x5, -1]
mov w0, ascii_space
str x1, [x5, -11]
strb w2, [x5, -3]
strb w3, [x5, -1]
strb w4, [x5, -0]
/*Write space at first char slot*/
strb w0, [x5, -12]
b maxmin_price_pre_loop

mmp_check_field:
/*Make sure some number was inserted in field*/
adr x1, maxmin_price_msg_end-3
ldrb w0, [x1]
cmp w0, ascii_space
beq do_mmp_beep

/*Write new max/min price to inventory.bin*/
/*Transfer ONLy the ascii float to stack buffer*/
adr x0, maxmin_price_msg_end-15
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
adr x1, maxmin_price_sscanf_item
add x2, sp, 0x20
bl sscanf /*should we EC this?*/

/*write to inv.bin and reprint*/
add x0, invbin_ptr, maxprice
ldr d0, [sp, 0x20]
str d0, [x0, x19] //use index for the store

/*reclear the field*/
adr x0, maxmin_price_msg_end-3
movz x1, 0x2020, lsl 48
movk x1, 0x2020, lsl 32
movk x1, 0x2020, lsl 16
movk x1, 0x2020
str x1, [x0, -12]
strh w1, [x0, -4]
strh w1, [x0, -1]
b maxmin_price_pre_loop

/*Epilogue*/
maxmin_price_epilogue:
epilogue 1, 0x38
