/*args...
w0 = index
0 = area width
1 = loc width
2 = cat width*/

__area_text:
.asciz "Area"
__loc_text:
.asciz "Loc"
__cat_text:
.asciz "Cat"

width_string_table:
.xword __area_text
.xword __loc_text
.xword __cat_text

.data
width_changer_msg:
.asciz "\x1B[2J\x1B[HCurrent %s width is %u\nType new %s width then press Enter/Plus (any value from 1 thru 7):  \n"
width_changer_msg_end:
.text

.align 6

//w0 = number. 0 for area, 1 for loc, 2 for cat
.globl width_changer
width_changer:
prologue 1, 8

/*save index(arg)*/
mov w19, w0

/*Based on index load up the 3 total format descriptors and call sprintf*/
width_changer_pre_loop:
add x2, invbin_ptr, areawidth
ldrb w2, [x2, x19] //use offset/arg for load
adr x3, width_string_table
lsl x0, x19, 3 //shift offset/arg
ldr x1, [x3, x0] //load %s ptr from table
mov x3, x1 //copy of %s ptr
adr x0, width_changer_msg
bl printf

/*Wait for keyboard inputs*/
width_changer_idle_loop:
bl keyboard_input
cbz w0, -4
ldrb w0, [masterptr, keyboard_buffer]
cmp w0, ESC
beq wc_escape
cmp w0, ascii_enter
beq wc_check_field
cmp w0, ascii_plus
beq wc_check_field
cmp w0, DELETE
beq wc_erase_char
cmp w0, ascii_1
blo do_wc_beep
cmp w0, ascii_7
bls wc_insert_char
do_wc_beep:
bl beep
b width_changer_idle_loop
wc_escape: /*Reset writable field*/
adr x0, width_changer_msg_end-3
mov w3, ascii_space
strb w3, [x0]
b width_changer_epilogue
wc_insert_char:
adr x1, width_changer_msg_end-3
mov w2, 1
bl insert_char
cbz w0, width_changer_pre_loop
b width_changer_idle_loop
wc_erase_char:
adr x0, width_changer_msg_end-3
mov w1, 1
bl erase_char
cbz w0, width_changer_pre_loop
b width_changer_idle_loop
wc_check_field:
adr x0, width_changer_msg_end-3
mov w1, 1
bl enter_field
cbnz w0, width_changer_idle_loop
/*Write new width to inv.bin*/
adr x0, width_changer_msg_end-3
ldrb w1, [x0]
and w1, w1, 0x0000000F
add x2, invbin_ptr, areawidth
strb w1, [x2, x19] //used index for offset
/*Reset writable field*/
mov w3, ascii_space
strb w3, [x0]
b width_changer_pre_loop

/*epilogue*/
width_changer_epilogue:
epilogue 1, 8
