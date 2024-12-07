//x0 = pointer to field
//w1 = width
//0 = success
//-1 = had to beep
erase_char:
/*Backup ptr*/
mov x3, x0
/*Move cursor to first hit of space or null ender*/
ldrb w2, [x0], 1
cmp w2, ascii_space
beq __check_erase_char
subs w1, w1, 1
bne -0x10
/*If we reached here then we know we can erase no matter what*/
__erase_char:
mov w1, ascii_space
strb w1, [x0, -1]
mov w0, 0
ret
/*Was very first char in field a space, if so, beep!*/
__check_erase_char:
sub x4, x0, 1
cmp x3, x4
beq __erase_char_beep
mov w1, ascii_space
strb w1, [x0, -2]
mov w0, 0
ret
/*Beep*/
__erase_char_beep:
prologue 0, 0
bl beep
mov w0, -1
epilogue 0, 0

//===================================

//w0 = char to insert
//x1 = ptr to field
//w2 = width
//w0 returns 0 for success
//w0 returns -1 for had to beep
insert_char:
/*Move cursor to first hit of space or null ender*/
ldrb w3, [x1], 1
cmp w3, ascii_space
beq __insert_char
subs w2, w2, 1
bne -0x10
/*if we hit here, we can't insert any more chars, beep!*/
stp fp, lr, [sp, -0x10]!
mov fp, lr
bl beep
ldp fp, lr, [sp], 0x10
mov w0, -1
ret
__insert_char:
strb w0, [x1, -1]
mov w0, 0
ret

//===================================

//x0 = ptr to field
//x1 = width
//w0 returns 0 for success
//w0 returns -1 for had to beep
enter_field:
/*Make sure every field byte is filled with a char (non space, non zero)*/
ldrb w2, [x0], 1
cmp w2, ascii_space
beq enter_field_bad
subs w1, w1, 1
bne enter_field
mov w0, 0
ret
enter_field_bad:
prologue 0, 0
bl beep
mov w0, -1
epilogue 0, 0
