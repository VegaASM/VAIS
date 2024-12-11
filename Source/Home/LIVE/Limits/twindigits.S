
/*
NOTE never call this for price field, will crash or do something unknown
args
x0 = ptr to first char of field
return value
w0 = 2, warning NOT issued, auto-bypassed
w0 = 1, warning issued, bypassed
w0 = 0, warning issued, NOT bypassed
*/

td_msg:
.asciz "\x1B[2J\x1B[HTwin digits! (%s) Bypass? Tab = Yes, Backspace = No\n"

.align 6
.globl twindigits
twindigits:
/*Check if td checker is enabled in settings*/
ldrb w1, [invbin_ptr, tdvalue]
tbnz w1, 0, td_yes_enabled
mov w0, 2
ret

/*Do an actual prologue now*/
td_yes_enabled:
prologue 0, 0x20

/*Is final char a symbol?*/
ldrb w2, [x0, FIELD_MAX - 1]
cmp w2, ascii_plus
beq td_return_two_withstd_epilogue
cmp w2, ascii_mulli
beq td_return_two_withstd_epilogue

/*Char checker loop*/
td_setup_root_loop:
mov w1, FIELD_MAX
mov x6, x0 //need copy of Arg for later
td_root_loop:
ldrb w2, [x0], 1
cmp w2, ascii_space
bne do_we_have_it
td_decrement_loop:
subs w1, w1, 1
bne td_root_loop
/*No twin digits found*/
b td_return_two_withstd_epilogue

/*We have a nonspace, do we have it*/
do_we_have_it:
ldrb w3, [x0]
cmp w2, w3
bne td_decrement_loop

/*Twin digits found!*/
/*Copy field string to temp buffer and printf*/
add x1, sp, 0x10
ldr x2, [x6]
ldr w3, [x6, 8]
ldrb w4, [x6, 12]
mov w5, 0 //Must terminate in null byte
str x2, [x1]
str w3, [x1, 8]
strb w4, [x1, 12]
strb w5, [x1, 13]
bl beep
adr x0, td_msg
/*Adjust x1 cursor to remove all unnecessary spaces*/
add x1, sp, 0xF
ldrb w2, [x1, 1]!
cmp w2, ascii_space
beq -0x8
bl printf

td_idle_loop:
bl keyboard_input
cbz w0, -4
ldrb w0, [masterptr, keyboard_buffer]
cmp w0, ascii_tab
beq td_return_one
cmp w0, DELETE
beq td_deny
bl beep
b td_idle_loop

td_deny:
mov w0, 0
b td_epilogue

td_return_one:
mov w0, 1
b td_epilogue

td_return_two_withstd_epilogue:
mov w0, 2
td_epilogue:
epilogue 0, 0x20
