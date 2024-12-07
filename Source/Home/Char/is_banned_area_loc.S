/*This func checks if area or loc is filled as "DELETE!"*/
/*x0 = ptr to area/loc field*/
/*x0 returns true (1) or false (0)*/

.globl is_banned_area_loc
is_banned_area_loc:
ldr x2, [x0]
movz x1, 0x0021, lsl 48
movk x1, 0x4554, lsl 32
movk x1, 0x454C, lsl 16
movk x1, 0x4544
and x0, x2, 0xFFFFFFFFFFFFFF00
cmp x0, x1
beq cbal_beep
mov w0, 0
ret
cbal_beep:
prologue 0, 0
bl beep
mov w0, 1
epilogue 0, 0
