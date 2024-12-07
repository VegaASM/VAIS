/*termios Struct offsets*/
.set lflag, 12
.set VTIME, 22
.set VMIN, 23

.align 6
.globl set_new_term_and_save_old
set_new_term_and_save_old:
/*Prologue*/
prologue 1, 8

/*Set x19 to OG term dump spot*/
add x19, masterptr, og_term_struct

/*Set args and call tcgetattr*/
mov w0, stdin
mov x1, x19
bl tcgetattr

/*Make copy of OG*/
add x8, masterptr, alt_term_struct
ldp x0, x1, [x19, 0]
ldp x2, x3, [x19, 0x10]
ldp x4, x5, [x19, 0x20]
ldp x6, x7, [x19, 0x30] //last 4 bytes are unused, fyi
stp x0, x1, [x8, 0]
stp x2, x3, [x8, 0x10]
stp x4, x5, [x8, 0x20]
stp x6, x7, [x8, 0x30]

/*Remove ECHO and ICANON*/
ldr w0, [masterptr, alt_term_struct + lflag]
mov w1, (ECHO | ICANON)
bic w0, w0, w1 /*And w/ complement to remove the 2 bits*/
str w0, [masterptr, alt_term_struct + lflag]

/*Set VMIN and VTIME to 0 TODO research if I need this!*/
strh wzr, [masterptr, alt_term_struct + VTIME]

/*Set alt term struct contents to mimic raw terminal*/
/*mov x0, x8
bl cfmakeraw*/

/*Now apply the new (alt) terminal!*/
mov w0, stdin
mov w1, TCSANOW
mov x2, x8
bl tcsetattr

/*Epilogue*/
epilogue 1, 8



.globl make_at_exit
make_at_exit:
prologue 0, 0
adr x0, reset_func
bl atexit
epilogue 0, 0

.globl reset_func
reset_func:
mov w0, stdin
mov w1, TCSANOW
add x2, masterptr, og_term_struct
b tcsetattr

