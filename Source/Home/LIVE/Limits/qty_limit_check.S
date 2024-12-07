/*
x0 = ptr to qty field first usable char
w0 = 2, warning NOT issued, auto-bypassed
w0 = 1, warning issued, bypassed
w0 = 0, warning issued, NOT bypassed*/

qty_limit_sscanf:
.asciz "%lf" //for sscanf; MUST have l before the f for longfloat
qty_override_msg:
.asciz "\x1B[2J\x1B[HNOTICE! Qty (%s) exceeds max or min boundary.\n"
qty_override_msg_2:
.asciz "Proceed?\nTab = Yes\nBackspace = No"
.align 6

.global qty_limit_check
qty_limit_check:
prologue 0, 0x30

/*
sp + 0x10 thru 0x1D = qty ascii string plus null
0x20 thru 0x2F = double float*/

/*Transfer ASCII QTY from data field to stack buffer*/
add x1, sp, 0x10
ldr x2, [x0]
ldr w3, [x0, 8]
ldrb w4, [x0, 12]
mov w5, 0 //Must terminate in null byte
str x2, [x1]
str w3, [x1, 8]
strb w4, [x1, 12]
strb w5, [x1, 13]

/*Do we have symbol at end?*/
cmp w4, ascii_plus
beq 0xC
cmp w4, ascii_mulli
bne 0x8

/*Write null on symbol*/
strb w5, [x1, 12]

/*Call sscanf
x0 = Where string is at (must be null terminated)
x1 = format string
x2 = addr to dump qty*/
mov x0, x1
adr x1, qty_limit_sscanf
add x2, sp, 0x20
bl sscanf //No error checks? TODO we should check this cuz user can spam decimal pts

/*Load float*/
ldr d0, [sp, 0x20]

/*Load and check upper limit, get final bool from condition checks*/
ldr d2, [invbin_ptr, minqty]
fcmp d0, d2
cset w2, cc
ldr d1, [invbin_ptr, maxqty]
mov w1, 0 //Preset max bool/cond as false
fcmp d1, 0.0
beq or_qty_bools
fcmp d0, d1
cset w1, hi
or_qty_bools:
orr w0, w1, w2 //hi OR lo = (hi | !C)
cbnz w0, yes_qty_limit_hit

/*Return 2*/
mov w0, 2
qty_limit_epilogue:
epilogue 0, 0x30

yes_qty_limit_hit:
bl beep
/*Printf*/
adr x0, qty_override_msg
/*Adjust x1 cursor to remove all unnecessary spaces*/
add x1, sp, 0xF
ldrb w2, [x1, 1]!
cmp w2, ascii_space
beq -0x8
bl printf
adr x0, qty_override_msg_2
bl puts

/*Now idle for key inputs*/
qty_warning_idle_loop:
bl keyboard_input
cbz w0, -4
ldrb w0, [masterptr, keyboard_buffer]
cmp w0, ascii_tab
beq qty_warning_return_one
cmp w0, DELETE
beq qty_warning_return_zero
bl beep
b qty_warning_idle_loop

qty_warning_return_one:
mov w0, 1
b qty_limit_epilogue

qty_warning_return_zero:
mov w0, 0
b qty_limit_epilogue
