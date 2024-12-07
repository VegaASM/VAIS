#include "change_mode.S"
#include "edit_mode.S"

more_menus_msg:
.asciz "\x1B[2J\x1B[HLive Inventory More Menus\n\nESC. Go back to Live Inventory\n7. Edit Mode\n8. Change Mode"

.align 6
.globl more_menus
more_menus:
/*Prologue and print title*/
prologue 0, 0

more_menus_print_title:
adr x0, more_menus_msg
bl puts

/*Idle and read keyboard*/
more_menus_idle_loop:
bl keyboard_input
cbz w0, -4
ldrb w0, [masterptr, keyboard_buffer]
cmp w0, ESC
beq more_menus_epilogue
cmp w0, ascii_7
beq mm_do_edit_mode
cmp w0, ascii_8
beq mm_do_change_mode
bl beep
b more_menus_idle_loop

mm_do_edit_mode:
bl edit_mode
b more_menus_print_title

mm_do_change_mode:
bl change_mode
b more_menus_print_title

more_menus_epilogue:
epilogue 0, 0
