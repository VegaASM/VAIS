//x0 = current field last char ptr
//x0 = qty field last char ptr or null to signal to leave inventory
.align 6
.globl inv_esc_func
inv_esc_func:
/*Are we in price or qty field?*/
ldrb w1, [x0, -(FIELD_MAX+2)]
cmp w1, ascii_y
movz x2, 0x2020, lsl 48
movk x2, 0x2020, lsl 32
movk x2, 0x2020, lsl 16
movk x2, 0x2020
beq inv_esc_func_in_qty_field
/*Clear out price field and return null*/
str x2, [x0, -12]
strh w2, [x0, -4] //Leave -2 offset (hardcoded dot) alone! Also leave dub arrows alone
strh w2, [x0, -1]
mov w0, 0 //return 0 to parent func
strb w0, [curdataentry_ptr, d_pflag] //reset price limit bypass flag; NOTE this may botch if we init ESC key in editmode and back away back to LIVE then enter in stuff
ret
inv_esc_func_in_qty_field:
/*Clear out qty field and update cursor to price field lasst char, and transfer double arrows be at price field last char*/
mov w1, 0x3C3C
str x2, [x0, -12]
str w2, [x0, -4]
strb w2, [x0]
strh w2, [x0, 1] //space out the dub arrow at qty field
sub x0, x0, (FIELD_MAX+10)
strh w1, [x0, 1] //dub arrows now at price field
mov w3, 0
strb w3, [curdataentry_ptr, d_qflag] //reset qty limit bypass flag; NOTE this may botch if we init ESC key in editmode and back away back to LIVE then enter in stuff
ret

////////////////////////////////////////////

//w0 = char
//x1 = last char ptr
//w0 return 0 for success, -1 for beep occurred
.align 6
.globl inv_insert_char
inv_insert_char:
/*Do we have space*/
ldrb w2, [x1, -(FIELD_MAX-1)]
cmp w2, ascii_space
bne inv_insert_char_beep
/*We have space, are we in price or qty field?*/
ldrb w2, [x1, -(FIELD_MAX+2)]
cmp w2, ascii_y
beq inv_insert_char_in_qty_field
/*Price field shift, leave decimal dot alone!*/
ldr x2, [x1, -11]
ldrb w3, [x1, -3]
ldrb w4, [x1, -1]
ldrb w5, [x1]
str x2, [x1, -12]
strb w3, [x1, -4]
strb w4, [x1, -3]
strb w5, [x1, -1]
inv_insert_char_last_char:
strb w0, [x1]
mov w0, 0
ret
/*Qty field shift*/
inv_insert_char_in_qty_field:
ldr x2, [x1, -11]
ldr w3, [x1, -3]
str x2, [x1, -12]
str w3, [x1, -4]
b inv_insert_char_last_char
/*Beep*/
inv_insert_char_beep:
prologue 0, 0
bl beep
mov w0, -1
epilogue 0, 0

////////////////////////////////////////////


//x0 = ptr
//w0 return 0 for success, -1 for beep occurred
.align 6
.globl inv_erase_char
inv_erase_char:
/*Do we have space on last char*/
ldrb w1, [x0]
cmp w1, ascii_space
beq inv_erase_char_beep
/*Are we in price or qty field?*/
ldrb w1, [x0, -(FIELD_MAX+2)]
cmp w1, ascii_y
mov w5, ascii_space
beq inv_erase_char_in_qty_field
/*Price field shift, leave decimal dot alone!*/
ldr x1, [x0, -12]
ldrb w2, [x0, -4]
ldrb w3, [x0, -3]
ldrb w4, [x0, -1]
str x1, [x0, -11]
strb w2, [x0, -3]
strb w3, [x0, -1]
strb w4, [x0, -0]
inv_erase_char_last_char:
strb w5, [x0, -12]
mov w0, 0
ret
/*Qty field shift*/
inv_erase_char_in_qty_field:
ldr x1, [x0, -12]
ldr w2, [x0, -4]
str x1, [x0, -11]
str w2, [x0, -3]
b inv_erase_char_last_char
/*Beep*/
inv_erase_char_beep:
prologue 0, 0
bl beep
mov w0, -1
epilogue 0, 0

////////////////////////////////////////////

//x0 = field last char ptr
//w0 return 0 for success, -1 for beep occurred
.align 6
.globl inv_insert_dot
inv_insert_dot:
/*Do we have space*/
ldrb w1, [x0, -(FIELD_MAX-1)]
cmp w1, ascii_space
bne inv_insert_dot_beep
/*We have space, are we in price or qty field?*/
ldrb w1, [x0, -(FIELD_MAX+2)]
cmp w1, ascii_e
beq inv_insert_dot_beep
/*We are in qty field. Does field already contain a dot?*/
sub x1, x0, (FIELD_MAX-1)
mov w2, FIELD_MAX
ldrb w3, [x1], 1
cmp w3, ascii_dot
beq inv_insert_dot_beep
subs w2, w2, 1
bne -0x10
/*Good to insert dot into qty field*/
ldr x1, [x0, -11]
ldr w2, [x0, -3]
mov w3, ascii_dot
str x1, [x0, -12]
str w2, [x0, -4]
strb w3, [x0]
/*Return success*/
mov w0, 0
/*End func*/
ret
inv_insert_dot_beep:
prologue 0, 0
bl beep
mov w0, -1
epilogue 0, 0
