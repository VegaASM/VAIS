#include "Sub/maxmin_price.S"
#include "Sub/maxmin_qty.S"

settings_max_min_values_msg:
.asciz "\x1B[2J\x1B[H1. Set Max Price\n2. Set Min Price\n3. Set Max Qty\n4. Set Min Qty\n8/ESC. Go back to Settings Menu"

.align 6

.globl settings_max_min
settings_max_min:
/*Prologue*/
prologue 0, 0

/*Print maxmin msg*/
settings_print_max_min:
adr x0, settings_max_min_values_msg
bl puts
settings_max_min_idle_loop:
/*get input and idle*/
bl keyboard_input
cbz w0, -4
ldrb w0, [masterptr, keyboard_buffer]
cmp w0, ESC
beq settings_max_min_epilogue
cmp w0, ascii_8
beq settings_max_min_epilogue
cmp w0, ascii_1
beq going_to_call_maxmin_price
cmp w0, ascii_2
beq going_to_call_maxmin_price
cmp w0, ascii_3
beq going_to_call_maxmin_qty
cmp w0, ascii_4
beq going_to_call_maxmin_qty
bl beep
b settings_max_min_idle_loop
going_to_call_maxmin_qty:
and w0, w0, 0x0000000F
sub w0, w0, 3 /*change 3 to 0 and 4 to 1*/
bl maxmin_qty
b settings_print_max_min
going_to_call_maxmin_price:
and w0, w0, 0x0000000F
sub w0, w0, 1 /*change 1 to 0 and 2 to 1*/
bl maxmin_price
b settings_print_max_min

/*Epilogue*/
settings_max_min_epilogue:
epilogue 0, 0
