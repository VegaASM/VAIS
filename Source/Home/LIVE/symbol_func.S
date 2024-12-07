/*This func handles...
"Regular" Enter (Plus)
Times/Asterisk/Mulli
Minus/Dash
Slash/Div*/
/*
x0 = pointer to field's first char
w1 = symbol , 0 = plus, 1 = mulli, 2 = sub, 3 = div, 2 & 3 not implemented yet
x0 = N/A, no return value*/

internal_symbol_func_parsing_error_msg:
.asciz "\x1B[2J\x1B[HError! Somehow sprintf returned too many chars for use in the qty field. This should never happen. Contact the Developer."
plus_string:
.asciz "%lf+%lf" //sscanf needs l for double precision
mulli_string:
.asciz "%lf*%lf"
sub_string:
.asciz "%lf-%lf"
div_string:
.asciz "%lf/%lf"
symbol_sscanf_lut:
.xword plus_string
.xword mulli_string
.xword sub_string
.xword div_string

symbol_sprintf_sixteen:
.asciz "%.16f"

.align 6
.globl symbol_func
symbol_func:
/*Prologue and Save args*/
prologue 3, 0x58 //Should be more than enough, if you get weird segments, check on sizing this up more
mov x19, x0
mov w20, w1

/*Check if we are in price or qty field*/
ldrb w1, [x0, -3]
cmp w1, ascii_e
beq symbolfunc_beep
/*We are in qty field, check NO vs A value*/
ldrb w1, [x0, FIELD_MAX-1]
cmp w1, ascii_space
beq symbolfunc_beep
/*Is last char a symbol or regular number?*/
cmp w1, ascii_0
blo symbolfunc_beep
/*Qty field with last numb as char*/
/*If symbol exist within the field, we need to call the Math*/
symbol_func_qty_field_number_is_last_char:
mov x1, x0
mov w2, FIELD_MAX-1 //Omit checking last char ofc
symbol_func_qfnislc_loop:
ldrb w21, [x1], 1 //use w21 cuz we need this symbol later thats within field that isnt last char
cmp w21, ascii_plus
beq call_symbol_parser
cmp w21, ascii_mulli
beq call_symbol_parser
cmp w21, ascii_dash
beq call_symbol_parser
cmp w21, ascii_slash
beq call_symbol_parser
subs w2, w2, 1
bne symbol_func_qfnislc_loop

/*Last char is number, and we need to append SYMBOL but if and only if first char is a space (do we have room?)*/
ldrb w1, [x0]
cmp w1, ascii_space
bne symbolfunc_beep

/*Append the symbol that was typed in!*/
symbol_func_append_symbol:
ldr x1, [x0, 1]
ldr w2, [x0, 9]
str x1, [x0]
str w2, [x0, 8]
strb w20, [x0, 12]
/*Epilogue*/
symbol_func_epilogue:
epilogue 3, 0x58

/*Call beep, return arg ptr +12*/
symbolfunc_beep:
bl beep
b symbol_func_epilogue

call_symbol_parser:
/*Copy qty field to stack buffer*/
add x1, sp, 0x10
ldr x2, [x0]
ldr w3, [x0, 8]
ldrb w4, [x0, 12]
mov w5, 0
str x2, [x1]
str w3, [x1, 8]
strb w4, [x1, 12]
strb w5, [x1, FIELD_MAX] //Need to make sure string ends in null for sscanf
/*Call sscanf
x0 = dest ptr (ptr to ascii shit)
x1 = c format line ptr
x2 = float dump spot1
x3 = float dump spot2*/
add x0, sp, 0x10
adr x1, symbol_sscanf_lut
/*ew hacky i know*/
cmp w21, ascii_plus
mov w2, 0
beq u_u_load_table_for_sscanf
cmp w21, ascii_mulli
mov w2, 8
beq u_u_load_table_for_sscanf
cmp w21, ascii_dash
mov w2, 16
beq u_u_load_table_for_sscanf
mov w2, 24
u_u_load_table_for_sscanf:
ldr x1, [x1, x2] //Now points to u-symbol-u
add x2, sp, 0x20
add x3, sp, 0x28
bl sscanf //dont ec this... lol
ldp d0, d1, [sp, 0x20]
/*Based on symbol within field (NOT last char!) do the MATH!*/
cmp w21, ascii_plus
beq float_add
cmp w21, ascii_mulli
beq float_mulli
cmp w21, ascii_dash
beq float_sub
fdiv d0, d0, d1
b do_sprintf_after_math_stuff
float_add:
fadd d0, d0, d1
b do_sprintf_after_math_stuff
float_mulli:
fmul d0, d0, d1
b do_sprintf_after_math_stuff
float_sub:
fsub d0, d0, d1
/*Now sprintf the math'd float result back to buffer*/
do_sprintf_after_math_stuff:
add x0, sp, 0x10 //1st arg of sprintf
adr x1, symbol_sprintf_sixteen
bl sprintf //Don't EC this.... lul
/*Now go navigate to null byte of sprintf's buffer result, and remove any trailing ascii zeroes*/
add x1, sp, 0x10
add x0, x1, x0
mov w2, 0
ascii_trailing_zero_removal_loop:
ldrb w3, [x0, -1]!
cmp w3, ascii_dot
beq ascii_tzrl_done //Only gets hit if whole number
cmp w3, ascii_0
bne ascii_tzrl_done
strb w2, [x0]
b ascii_trailing_zero_removal_loop
/*Done removing ascii trailing zeroes, NOTE Keep x0 intact! atm currently points to the dot from sprintf or last non-zero ascii trailing char*/
ascii_tzrl_done:
/*However if x0 points to dot, decrease it by 1*/
ldrb w1, [x0]
cmp w1, ascii_dot
bne 0x8
sub x0, x0, 1
/*Temp blank/reset qty field*/
movz x1, 0x2020, lsl 48
movk x1, 0x2020, lsl 32
movk x1, 0x2020, lsl 16
movk x1, 0x2020
str x1, [x19]
str w1, [x19, 8]
strb w1, [x19, 12]
/*Copy new ascii chars from sprintf buffer to qty field*/
add x1, sp, 0x10 //If we go below this ptr, we MUST stop after next write
add x2, x19, FIELD_MAX-1
ldrb w3, [x0], -1
strb w3, [x2], -1
cmp x0, x1
bhs -0xC

/*Finally append the symbol*/
mov x0, x19 //volatile x0 destroyed by sscanf and sprintf ofc
b symbol_func_append_symbol

internal_symbol_func_parsing_error:
adr x0, internal_symbol_func_parsing_error_msg
bl puts
b 0 //halt for now
