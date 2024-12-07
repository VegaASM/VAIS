/*Remove all spaces*/
/*x0 = dest, x1 = src, x0 MUST end in NULL there are no checks for this ofc*/

.globl remove_all_spaces
remove_all_spaces:
mov x1, x0
remove_all_spaces_loop:
ldrb w2, [x0], 1
cbz w2, rewrite_nullbyte_ender
cmp w2, ascii_space
beq remove_all_spaces_loop
strb w2, [x1], 1
b remove_all_spaces_loop
rewrite_nullbyte_ender:
strb w2, [x1], 1
ret
