
.align 6
/*No Args
w0 returns number of keys pressed*/
.globl keyboard_input
keyboard_input:
/*Read keystroke(s)*/
mov w8, read_sc
mov w0, stdin
add x1, masterptr, keyboard_buffer
mov w2, 0x10 /*TODO change this to 1 and retest*/
svc 0

/*w0 will contain amount of keystrokes, return it*/
ret
